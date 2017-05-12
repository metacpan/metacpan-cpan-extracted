package IPC::Concurrency::DBI::Application;

use warnings;
use strict;

use Data::Validate::Type;
use Data::Dumper;
use Carp;

use IPC::Concurrency::DBI::Application::Instance;


=head1 NAME

IPC::Concurrency::DBI::Application - Application identifier that represents the resource that will be limited.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 SYNOPSIS

This module allows controlling how many instances of a given program are allowed
to run in parallel. It does not manage forking or starting those instances.

See the documentation of IPC::Concurrency::DBI for more information.

	# Configure the concurrency object.
	use IPC::Concurrency::DBI;
	my $concurrency_manager = IPC::Concurrency::DBI->new(
		'database_handle' => $dbh,
		'verbose'         => 1,
	);

	# Retrieve the application.
	my $application = $concurrency_manager->get_application(
		name => 'cron_script.pl',
	);

	# Count how many instances are currently running.
	my $instances_count = $application->get_instances_count();

	# NOT IMPLEMENTED YET: Get a list of what instances are currently running.
	# my $instances = $application->get_instances_list()

	# Start a new instance of the application. If this returns undef, we've
	# reached the limit.
	my $instance = $concurrent_program->start_instance();
	unless ( defined( $instance ) )
	{
		print "Too many instances of $0 are already running.\n";
		exit;
	}

	# [...] Do some work.

	# Now that the application is about to exit, flag the instance as completed.
	# (note: this is implicit when $instance is destroyed).
	$instance->finish();


=head1 METHODS

=head2 new()

Create a new IPC::Concurrency::DBI::Application object. This function should
not be called directly and its API could change, instead use
IPC::Concurrency::DBI->get_application().

	# Retrieve the application by name.
	my $application = IPC::Concurrency::DBI::Application->new(
		database_handle => $dbh,
		name            => 'cron_script.pl',
	);
	die 'Application not found'
		unless defined( $application );

	# Retrieve the application by ID.
	my $application = IPC::Concurrency::DBI::Application->new(
		database_handle => $dbh,
		id              => 12345,
	);
	die 'Application not found'
		unless defined( $application );

'database handle': mandatory, a DBI object.

'name': the name of the application to retrieve.

'id': the internal ID of the application to retrieve.

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $database_handle = delete( $args{'database_handle'} );
	my $name = delete( $args{'name'} );
	my $application_id = delete( $args{'id'} );

	# Check parameters.
	croak "Argument 'database_handle' is required to create a new IPC::Concurrency::DBI::Application object"
		unless defined( $database_handle );
	croak "Argument 'database_handle' is not a DBI object"
		if !Data::Validate::Type::is_instance( $database_handle, class => 'DBI::db' );
	croak 'Cannot pass both a name and an application ID, please use only one'
		if defined( $name ) && defined( $application_id );

	# Determine what key to use to retrieve the row.
	my ( $key, $value );
	if ( defined( $name ) )
	{
		$key = 'name';
		$value = $name;
	}
	elsif ( defined( $application_id ) )
	{
		$key = 'ipc_concurrency_application_id';
		$value = $application_id;
	}
	else
	{
		croak 'You need to specify either a name or an ID to retrieve an application';
	}

	# Retrieve the row from the database.
	my $data = $database_handle->selectrow_hashref(
		qq|
			SELECT *
			FROM ipc_concurrency_applications
			WHERE $key = ?
		|,
		{},
		$value,
	);
	croak 'Cannot execute SQL: ' . $database_handle->errstr()
		if defined( $database_handle->errstr() );
	croak 'Application not found'
		unless defined( $data );

	# Create the object.
	my $self = bless(
		{
			database_handle => $database_handle,
			data            => $data,
		},
		$class,
	);

	return $self;
}


=head2 start_instance()

Start a new instance of the current application.

	my $instance = $application->start_instance();
	unless ( defined( $instance ) )
	{
		print "Too many instances of $0 are already running.\n";
		exit;
	}

=cut

sub start_instance
{
	my ( $self ) = @_;
	my $database_handle = $self->get_database_handle();
	my $maximum_instances = $self->get_maximum_instances();

	my $rows_affected = $database_handle->do(
		q|
			UPDATE ipc_concurrency_applications
			SET current_instances = current_instances + 1, modified = ?
			WHERE ipc_concurrency_application_id = ?
				AND current_instances < maximum_instances
		|,
		{},
		time(),
		$self->get_id(),
	);
	croak 'Cannot execute SQL: ' . $database_handle->errstr()
		if defined( $database_handle->errstr() );

	# If no row was affected, we've reached the maximum number of instances or
	# the application ID has vanished. Either way, we can't start the instance.
	return unless $rows_affected == 1;

	return IPC::Concurrency::DBI::Application::Instance->new(
		application => $self,
	);
}


=head1 GETTERS / SETTERS

=head2 get_instances_count()

Retrieve the number of instances that currently running.

	my $instances_count = $application->get_instances_count();

=cut

sub get_instances_count
{
	my ( $self ) = @_;
	my $database_handle = $self->get_database_handle();
	my $maximum_instances = $self->get_maximum_instances();

	my $data = $database_handle->selectrow_hashref(
		q|
			SELECT current_instances
			FROM ipc_concurrency_applications
			WHERE ipc_concurrency_application_id = ?
		|,
		{},
		$self->get_id(),
	);
	croak 'Cannot execute SQL: ' . $database_handle->errstr()
		if defined( $database_handle->errstr() );
	croak 'Application not found'
		unless defined( $data );

	return $data->{'current_instances'};
}


=head2 get_maximum_instances()

Retrieve the maximum number of instances of the current application that are
allowed to run in parallel.

	my $maximum_instances = $application->get_maximum_instances();

=cut

sub get_maximum_instances
{
	my ( $self ) = @_;

	return $self->{'data'}->{'maximum_instances'};
}


=head2 set_maximum_instances()

Change the maximum number of instances of the current application that are
allowed to run in parallel.

	$application->set_maximum_instances( 10 );

=cut

sub set_maximum_instances
{
	my ( $self, $maximum_instances ) = @_;

	# Check parameters.
	croak 'The maximum number of instances needs to be a strictly positive integer'
		if !Data::Validate::Type::is_number( $maximum_instances, strictly_positive => 1 );

	# Update the application information.
	my $database_handle = $self->get_database_handle();
	my $rows_affected = $database_handle->do(
		q|
			UPDATE ipc_concurrency_applications
			SET maximum_instances = ?
			WHERE ipc_concurrency_application_id = ?
		|,
		{},
		$maximum_instances,
		$self->get_id(),
	);
	croak 'Cannot execute SQL: ' . $database_handle->errstr()
		if defined( $database_handle->errstr() );

	$self->{'data'}->{'maximum_instances'} = $maximum_instances;

	return 1;
}


=head2 get_name()

Returns the name of the current application.

	my $name = $application->get_name();

=cut

sub get_name
{
	my ( $self ) = @_;

	return $self->{'data'}->{'name'};
}


=head2 get_id()

Returns the internal ID of the current application.

	my $application_id = $self->get_id();

=cut

sub get_id
{
	my ( $self ) = @_;

	return $self->{'data'}->{'ipc_concurrency_application_id'};
}


=head1 INTERNAL METHODS

=head2 get_database_handle()

Returns the database handle used for this object.

	my $database_handle = $concurrency_manager->get_database_handle();

=cut

sub get_database_handle
{
	my ( $self ) = @_;

	return $self->{'database_handle'};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/IPC-Concurrency-DBI/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc IPC::Concurrency::DBI


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/IPC-Concurrency-DBI/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-Concurrency-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-Concurrency-DBI>

=item * MetaCPAN

L<https://metacpan.org/release/IPC-Concurrency-DBI>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2011-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
