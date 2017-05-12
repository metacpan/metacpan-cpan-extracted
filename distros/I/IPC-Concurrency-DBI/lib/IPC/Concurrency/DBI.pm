package IPC::Concurrency::DBI;

use warnings;
use strict;

use Data::Dumper;
use Data::Validate::Type;
use Carp;

use IPC::Concurrency::DBI::Application;


=head1 NAME

IPC::Concurrency::DBI - Control how many instances of an application run in parallel, using DBI as the IPC method.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 SYNOPSIS

This module controls how many instances of a given program are allowed to run
in parallel. It does not manage forking or starting those instances.

You can use this module for example to prevent more than one instance of a
program from running at any given time, or to never have more than N instances
running in parallel to prevent exhausting all the available resources.

It uses DBI as a storage layer for information about instances and applications,
which is particularly useful in contexts where Sarbanes-Oxley regulations allow
you database access but not file write rights in production environments.

	# Configure the concurrency object.
	use IPC::Concurrency::DBI;
	my $concurrency_manager = IPC::Concurrency::DBI->new(
		'database_handle' => $dbh,
		'verbose'         => 1,
	);

	# Create the tables that the concurrency manager needs to store information
	# about the applications and instances.
	$concurrency_manager->create_tables();

	# Register cron_script.pl as an application we want to limit to 10 parallel
	# instances. We only need to do this once, obviously.
	$concurrency_manager->register_application(
		name              => 'cron_script.pl',
		maximum_instances => 10,
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
	unless ( my $instance = $application->start_instance() )
	{
		print "Too many instances of $0 are already running.\n";
		exit;
	}

	# [...] Do some work.

	# Now that the application is about to exit, flag the instance as completed.
	# (note: this is implicit when $instance is destroyed).
	$instance->finish();


=head1 SUPPORTED DATABASES

This distribution currently supports:

=over 4

=item * SQLite

=item * MySQL

=item * PostgreSQL

=back

Please contact me if you need support for another database type, I'm always
glad to add extensions if you can help me with testing.


=head1 METHODS

=head2 new()

Create a new IPC::Concurrency::DBI object.

	my $concurrency_manager = IPC::Concurrency::DBI->new(
		'database_handle'   => $dbh,
		'verbose'           => 1,
	);

Arguments:

=over 4

=item * database handle

Mandatory, a DBI object.

=item * verbose

Optional, see verbose() for options.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $database_handle = delete( $args{'database_handle'} );
	my $verbose = delete( $args{'verbose'} );

	# Check parameters.
	croak "Argument 'database_handle' is required to create a new IPC::Concurrency::DBI object"
		unless defined( $database_handle );
	croak "Argument 'database_handle' is not a DBI object"
		if !Data::Validate::Type::is_instance( $database_handle, class => 'DBI::db' );

	# Create the object.
	my $self = bless(
		{
			'database_handle' => $database_handle,
			'verbose'         => 0,
		},
		$class,
	);

	$self->set_verbose( $verbose )
		if defined( $verbose );

	return $self;
}


=head2 register_application()

Register a new application with the concurrency manager and define the maximum
number of instances that should be allowed to run in parallel.

	$concurrency_manager->register_application(
		name              => 'cron_script.pl',
		maximum_instances => 10,
	);

'name' is a unique name for the application. It can be the name of the script
for a cron script, for example.

'maximum_instances' is the maximum number of instances that should be allowed to
run in parallel.

=cut

sub register_application
{
	my ( $self, %args ) = @_;
	my $name = delete( $args{'name'} );
	my $maximum_instances = delete( $args{'maximum_instances'} );

	# Check parameters.
	croak 'The name of the application must be defined'
		if !defined( $name ) || ( $name eq '' );
	croak 'The application name is longer than 255 characters'
		if length( $name ) > 255;
	croak 'The maximum number of instances must be defined'
		if !defined( $maximum_instances ) || ( $maximum_instances eq '' );
	croak 'The maximum number of instances must be a strictly positive integer'
		if !Data::Validate::Type::is_number( $maximum_instances, strictly_positive => 1 );

	# Insert the new application.
	my $database_handle = $self->get_database_handle();
	my $time = time();
	my $rows_affected = $database_handle->do(
		q|
			INSERT INTO ipc_concurrency_applications( name, current_instances, maximum_instances, created, modified )
			VALUES( ?, 0, ?, ?, ? )
		|,
		{},
		$name,
		$maximum_instances,
		$time,
		$time,
	);
	croak 'Cannot execute SQL: ' . $database_handle->errstr()
		if defined( $database_handle->errstr() );

	return defined( $rows_affected ) && $rows_affected == 1 ? 1 : 0;
}


=head2 get_application()

Retrieve an application by name or by application ID.

	# Retrieve the application by name.
	my $application = $concurrency_manager->get_application(
		name => 'cron_script.pl',
	);
	die 'Application not found'
		unless defined( $application );

	# Retrieve the application by ID.
	my $application = $concurrency_manager->get_application(
		id => 12345,
	);
	die 'Application not found'
		unless defined( $application );

=cut

sub get_application
{
	my ( $self, %args ) = @_;
	my $name = delete( $args{'name'} );
	my $application_id = delete( $args{'id'} );
	my $database_handle = $self->get_database_handle();

	return IPC::Concurrency::DBI::Application->new(
		name            => $name,
		id              => $application_id,
		database_handle => $database_handle,
	);
}


=head2 create_tables()

Create the tables that the concurrency manager needs to store information about
the applications and instances.

	$concurrency_manager->create_tables(
		drop_if_exist => $boolean,      #default 0
	);

By default, it won't drop any table but you can force that by setting
'drop_if_exist' to 1.

=cut

sub create_tables
{
	my ( $self, %args ) = @_;
	my $drop_if_exist = delete( $args{'drop_if_exist'} );
	my $database_handle = $self->get_database_handle();

	# Defaults.
	$drop_if_exist = 0
		if !defined( $drop_if_exist ) || !$drop_if_exist;

	# Check the database type.
	my $database_type = $self->get_database_type();
	croak "This database type ($database_type) is not supported yet, please email the maintainer of the module for help"
		if $database_type !~ m/^(?:SQLite|mysql|Pg)$/x;

	# Table definitions.
	my $tables_sql =
	{
		SQLite =>
		q|
			CREATE TABLE ipc_concurrency_applications
			(
				ipc_concurrency_application_id INTEGER PRIMARY KEY AUTOINCREMENT,
				name varchar(255) NOT NULL,
				current_instances INTEGER NOT NULL default '0',
				maximum_instances INTEGER NOT NULL default '0',
				created bigint(20) NOT NULL default '0',
				modified bigint(20) NOT NULL default '0',
				UNIQUE (name)
			)
		|,
		mysql  =>
		q|
			CREATE TABLE ipc_concurrency_applications
			(
				ipc_concurrency_application_id BIGINT(20) UNSIGNED NOT NULL auto_increment,
				name VARCHAR(255) NOT NULL,
				current_instances INT(10) UNSIGNED NOT NULL default '0',
				maximum_instances INT(10) UNSIGNED NOT NULL default '0',
				created bigint(20) UNSIGNED NOT NULL default '0',
				modified bigint(20) UNSIGNED NOT NULL default '0',
				PRIMARY KEY (ipc_concurrency_application_id),
				UNIQUE KEY idx_ipc_concurrency_applications_name (name)
			)
			ENGINE=InnoDB
		|,
		Pg     =>
		q|
			CREATE TABLE ipc_concurrency_applications
			(
				ipc_concurrency_application_id BIGSERIAL,
				name VARCHAR(255) NOT NULL,
				current_instances INT NOT NULL default '0',
				maximum_instances INT NOT NULL default '0',
				created BIGINT NOT NULL default '0',
				modified BIGINT NOT NULL default '0',
				PRIMARY KEY (ipc_concurrency_application_id),
				CONSTRAINT idx_ipc_concurrency_applications_name UNIQUE (name)
			)
		|,
	};
	croak "No table definition found for database type '$database_type'"
		if !defined( $tables_sql->{ $database_type } );

	# Create the table that will hold the list of applications as well as
	# a summary of the information about instances.
	if ( $drop_if_exist )
	{
		$database_handle->do( q|DROP TABLE IF EXISTS ipc_concurrency_applications| )
			|| croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}
	$database_handle->do(
		$tables_sql->{ $database_type }
	) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

	# TODO: create a separate table to hold information about what instances
	# are currently running.

	return 1;
}


=head1 ACCESSORS

=head2 get_database_handle()

Returns the database handle used for this object.

	my $database_handle = $concurrency_manager->get_database_handle();

=cut

sub get_database_handle
{
	my ( $self ) = @_;

	return $self->{'database_handle'};
}


=head2 get_database_type()

Return the database type corresponding to the database handle associated
with the L<IPC::Concurrency::DBI> object.

	my $database_type = $concurrency_manager->get_database_type();

=cut

sub get_database_type
{
	my ( $self ) = @_;

	my $database_handle = $self->get_database_handle();

	return $database_handle->{'Driver'}->{'Name'} || '';
}


=head2 get_verbose()

Return the verbosity level, which is used in the module to determine when and
what type of debugging statements / information should be warned out.

See C<set_verbose()> for the possible values this function can return.

	warn 'Verbose' if $queue->get_verbose();

	warn 'Very verbose' if $queue->get_verbose() > 1;

=cut

sub get_verbose
{
	my ( $self ) = @_;

	return $self->{'verbose'};
}


=head2 set_verbose()

Control the verbosity of the warnings in the code:

=over 4

=item * 0 will not display any warning;

=item * 1 will only give one line warnings about the current operation;

=item * 2 will also usually output the SQL queries performed.

=back

	$queue->set_verbose(1); # turn on verbose information

	$queue->set_verbose(2); # be extra verbose

	$queue->set_verbose(0); # quiet now!

=cut

sub set_verbose
{
	my ( $self, $verbose ) = @_;

	$self->{'verbose'} = ( $verbose || 0 );

	return;
}


=head1 DEPRECATED METHODS

=head2 verbose()

Please use C<get_verbose()> and C<set_verbose()> instead.

=cut

sub verbose
{
	croak 'verbose() has been deprecated, please use get_verbose() / set_verbose() instead.';
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


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!

Thanks to Jacob Rose C<< <jacob at thinkgeek.com> >> for suggesting the idea of
this module and brainstorming with me about the features it should offer.


=head1 COPYRIGHT & LICENSE

Copyright 2011-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
