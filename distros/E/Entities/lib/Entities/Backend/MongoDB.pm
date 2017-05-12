package Entities::Backend::MongoDB;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Carp;
use DateTime::Format::ISO8601;
use MongoDB;
use Moo;
use MooX::Types::MooseLike::Base qw/Str Int/;
use Scalar::Util qw/blessed/;
use namespace::autoclean;

with 'Entities::Backend';

# ABSTRACT: Stores all Entities data in a MongoDB database.

=head1 NAME

Entities::Backend::MongoDB - Stores all Entities data in a MongoDB database.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	use Entities;
	use Entities::Backend::MongoDB;

	# see synopsis at L<Entities>

=head1 DESCRIPTION

This L<backend|Entities::Backend> for the L<Entities> user management
and authorization system stores all entities and relations between them
in a MongoDB database, using the L<MongoDB> module. This is a powerful,
fast backend that gives you all the features of MongoDB. This is the only
backend right now that can be used in production environments.

A big advantage of using this backend is that there is no setup work
necessary. Just make sure your MongoDB daemon is running, and this
backend will automatically create the database and necessary collections.

=head1 UNIQUE METHODS

The following method are unique to this backend only.

=head2 new( [ host => 'localhost', port => 27017, db_name => 'entities' ] )

Creates a new instance of this module. Can receive the hostname of the server
running the MongoDB daemon, the port on that host where the daemon is
listening, and the name of the database to use. None of these parameters
is required, host will default to 'localhost', port will default to 27017
(the default MongoDB port) and db_name will default to 'entities'.

=head2 host()

Returns the host name or IP of the MongoDB server.

=cut

has 'host' => (
	is => 'ro',
	isa => Str,
	default => 'localhost'
);

=head2 port()

Returns the port number on the host where the MongoDB server listens.

=cut

has 'port' => (
	is => 'ro',
	isa => Int,
	default => sub { 27017 }
);

=head2 db_name()

Returns the name of the database into which all data is saved.

=cut

has 'db_name' => (
	is => 'ro',
	isa => Str,
	default => 'entities'
);

=head2 db( [$db_obj] )

Returns the L<MongoDB::Database> object used for actually storing and
retrieving data. If a MongoDB::Database object is provided, it will replace
the current object.

=cut

has 'db' => (
	is => 'rw',
	isa => sub { croak 'db must be a MongoDB::Database object' unless blessed $_[0] && blessed $_[0] eq 'MongoDB::Database' }
);

=head2 to_hash( $obj )

Receives an entity object (either user, action, role, feature, plan or
customer) and turns it into a hash-ref that can be saved in the database.

=cut

sub to_hash {
	my ($self, $obj) = @_;

	my $hash;

	if ($obj->isa('Entities::User')) {
		return {
			username => $obj->username,
			passphrase => $obj->passphrase,
			realname => $obj->realname,
			is_super => $obj->is_super ? 1 : 0,
			created => $obj->created->datetime,
			modified => $obj->modified->datetime,
			actions => [$obj->actions],
			roles => [$obj->roles],
			emails => [$obj->emails],
			customer => $obj->customer ? $obj->customer->name : undef,
		};
	} elsif ($obj->isa('Entities::Role')) {
		return {
			name => $obj->name,
			desription => $obj->description,
			is_super => $obj->is_super ? 1 : 0,
			created => $obj->created->datetime,
			modified => $obj->modified->datetime,
			actions => [$obj->actions],
			roles => [$obj->roles],
		};
	} elsif ($obj->isa('Entities::Action') || $obj->isa('Entities::Feature')) {
		return {
			name => $obj->name,
			desription => $obj->description,
			created => $obj->created->datetime,
			modified => $obj->modified->datetime,
		};
	} elsif ($obj->isa('Entities::Customer')) {
		return {
			name => $obj->name,
			email_address => $obj->email_address,
			created => $obj->created->datetime,
			modified => $obj->modified->datetime,
			features => [$obj->features],
			plans => [$obj->plans],
		};
	} elsif ($obj->isa('Entities::Plan')) {
		return {
			name => $obj->name,
			description => $obj->description,
			created => $obj->created->datetime,
			modified => $obj->modified->datetime,
			features => [$obj->features],
			plans => [$obj->plans],
		};
	} else {
		croak "Received an object that doesn't belong to the Entities family.";
	}
}

=head1 METHODS IMPLEMENTED

The following methods implement the methods that the L<Entities::Backend>
Moose role requires backend classes to implement. See the documentation
of that role for more information on these methods.

=head2 get_user_from_id( $user_id )

=cut

sub get_user_from_id {
	my ($self, $id) = @_;

	my $user = $self->db->get_collection('users')->find_one({ _id => $id });
	return unless $user;

	# turn this into an object
	return Entities::User->new(id => $user->{_id}, username => $user->{username}, realname => $user->{realname}, customer => $user->{customer} ? $self->get_customer($user->{customer}) : undef, passphrase => $user->{passphrase}, is_super => $user->{is_super}, roles => $user->{roles}, actions => $user->{actions}, emails => $user->{emails}, created => DateTime::Format::ISO8601->parse_datetime($user->{created}), modified => DateTime::Format::ISO8601->parse_datetime($user->{modified}), parent => $self);
}

=head2 get_user_from_name( $username )

=cut

sub get_user_from_name {
	my ($self, $username) = @_;

	my $user = $self->db->get_collection('users')->find_one({ username => $username });
	return unless $user;

	# turn this into an object
	return Entities::User->new(id => $user->{_id}, username => $user->{username}, realname => $user->{realname}, customer => $user->{customer} ? $self->get_customer($user->{customer}) : undef, passphrase => $user->{passphrase}, is_super => $user->{is_super}, roles => $user->{roles}, actions => $user->{actions}, emails => $user->{emails}, created => DateTime::Format::ISO8601->parse_datetime($user->{created}), modified => DateTime::Format::ISO8601->parse_datetime($user->{modified}), parent => $self);
}

=head2 get_role( $role_name )

=cut

sub get_role {
	my ($self, $name) = @_;

	my $role = $self->db->get_collection('roles')->find_one({ name => $name });
	return unless $role;
	
	# turn this into an object
	$role->{description} ||= '';

	return Entities::Role->new(id => $role->{_id}, name => $role->{name}, description => $role->{description}, is_super => $role->{is_super}, roles => $role->{roles}, actions => $role->{actions}, created => DateTime::Format::ISO8601->parse_datetime($role->{created}), modified => DateTime::Format::ISO8601->parse_datetime($role->{modified}), parent => $self);
}

=head2 get_customer( $customer_name )

=cut

sub get_customer {
	my ($self, $name) = @_;

	my $customer = $self->db->get_collection('customers')->find_one({ name => $name });
	return unless $customer;
	
	# turn this into an object
	return Entities::Customer->new(id => $customer->{_id}, name => $customer->{name}, email_address => $customer->{email_address}, features => $customer->{features}, plans => $customer->{plans}, created => DateTime::Format::ISO8601->parse_datetime($customer->{created}), modified => DateTime::Format::ISO8601->parse_datetime($customer->{modified}), parent => $self);
}

=head2 get_plan( $plan_name )

=cut

sub get_plan {
	my ($self, $name) = @_;

	my $plan = $self->db->get_collection('plans')->find_one({ name => $name });
	return unless $plan;
	
	# turn this into an object
	$plan->{description} ||= '';

	return Entities::Plan->new(id => $plan->{_id}, name => $plan->{name}, description => $plan->{description}, features => $plan->{features}, plans => $plan->{plans}, created => DateTime::Format::ISO8601->parse_datetime($plan->{created}), modified => DateTime::Format::ISO8601->parse_datetime($plan->{modified}), parent => $self);
}

=head2 get_feature( $feature_name )

=cut

sub get_feature {
	my ($self, $name) = @_;

	my $feature = $self->db->get_collection('features')->find_one({ name => $name });
	return unless $feature;

	$feature->{description} ||= '';
	
	# turn this into an object
	return Entities::Feature->new(id => $feature->{_id}, name => $feature->{name}, description => $feature->{description}, created => DateTime::Format::ISO8601->parse_datetime($feature->{created}), modified => DateTime::Format::ISO8601->parse_datetime($feature->{modified}), parent => $self);
}

=head2 get_action( $action_name )

=cut

sub get_action {
	my ($self, $name) = @_;

	my $action = $self->db->get_collection('actions')->find_one({ name => $name });
	return unless $action;

	$action->{description} ||= '';
	
	# turn this into an object
	return Entities::Action->new(id => $action->{_id}, name => $action->{name}, description => $action->{description}, created => DateTime::Format::ISO8601->parse_datetime($action->{created}), modified => DateTime::Format::ISO8601->parse_datetime($action->{modified}), parent => $self);
}

=head2 save( $obj )

=cut

sub save {
	my ($self, $obj) = @_;

	my $coll_name = $obj->isa('Entities::User') ? 'users' :
			$obj->isa('Entities::Role') ? 'roles' :
			$obj->isa('Entities::Action') ? 'actions' :
			$obj->isa('Entities::Feature') ? 'features' :
			$obj->isa('Entities::Plan') ? 'plans' :
			$obj->isa('Entities::Customer') ? 'customers' :
			'unknown';

	croak "Can't find out the type of object received, it is not a valid Entity"
		if $coll_name eq 'unknown';

	if ($obj->has_id) {
		# we're updating an existing object
		croak "Failed updating the object in MongoDB collection $coll_name: ".$self->db->last_error
			unless $self->db->get_collection($coll_name)->update({ _id => $obj->id }, $self->to_hash($obj), { safe => 1 });
	} else {
		# we're storing a new object
		my $coll = $self->db->get_collection($coll_name);
		if ($coll_name eq 'users') {
			$coll->ensure_index({ username => 1 }, { unique => 1 });
			$coll->ensure_index({ customer => 1 });
		} else {
			$coll->ensure_index({ name => 1 }, { unique => 1 });
		}

		my $id = $coll->insert($self->to_hash($obj), { safe => 1 });
		croak "Failed creating the object in MongoDB collection $coll: ".$self->db->last_error
			unless $id;
		$obj->_set_id($id);
	}

	return 1;
}

=head1 METHOD MODIFIERS

The following list documents any method modifications performed through
the magic of L<Moose>.

=head2 BUILD()

This method is automatically invoked immediately after the C<new()> method
is invoked. It is used to initiate the connection to the MongoDB database
and store it in the object.

=cut

sub BUILD {
	my $self = shift;

	my $connection = MongoDB::MongoClient->new(
		host => $self->host,
		port => $self->port
	);

	$self->db($connection->get_database($self->db_name));
}

=head1 SEE ALSO

L<Entities>, L<Entities::Backend>, L<Entities::Backend::Memory>, L<MongoDB>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-entities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Entities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Entities::Backend::MongoDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Entities>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Entities>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Entities>

=item * Search CPAN

L<http://search.cpan.org/dist/Entities/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
