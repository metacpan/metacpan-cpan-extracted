package Entities::User;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Carp;
use Digest::MD5 qw/md5_hex/;
use Moo;
use MooX::Types::MooseLike::Base qw/Any Str Bool ArrayRef/;
use MooX::Types::MooseLike::Email qw/EmailAddress/;
use Scalar::Util qw/blessed/;
use namespace::autoclean;

# ABSTRACT: A user entity that interacts with a web application.

=head1 NAME

Entities::User - A user entity that interacts with a web application.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	used internally, see L<Entities>

=head1 DESCRIPTION

A user is an entity that interacts with your webapp. Generally, this is
a human person that has signed up for your service, or was created by
a L<customer|Entities::Customer>, though it could be a privileged bot
or whatever.

The user is that actual entity the performs actions on your webapp, and is
thus required to be authorized to perform the actions they wish to perform.
This is done either by assuming <roles|Entities::Role> or by explicitely
being given <actions|Entities::Action>.

This entity class C<does> the L<Abilities> L<Moose role|Moose::Role>.

NOTE: you are not meant to create user objects directly, but only through
the C<new_user()> method in L<Entities>.

=head1 METHODS

=head2 new( username => 'someguy', passphrase => 's3cr3t', [ realname => 'Some Guy',
is_super => 0, roles => [], actions => [], customer => $customer_obj, id => 123,
emails => [], created => $dt_obj, modified => $other_dt_obj, parent => $entities_obj ] )

Creates a new instance of this module. Only 'username' and 'passphrase'
are required.

=head2 id()

Returns the ID of the user, if set.

=head2 has_id()

Returns a true value if the user object has an ID attribute.

=head2 _set_id( $id )

Sets the ID of the user object to the provided value. Only to be used
internally.

=cut

has 'id' => (
	is => 'ro',
	isa => Any,
	predicate => 'has_id',
	writer => '_set_id'
);

=head2 username()

Returns the username of this user.

=head2 set_username( $name )

Changes the username of the user to the provided name.

=cut

has 'username' => (
	is => 'ro',
	isa => Str,
	required => 1,
	writer => 'set_username'
);

=head2 realname()

Returns the real name of the user (i.e. person).

=head2 set_realname( $name )

Changes the real name of the user to the provided name.

=cut

has 'realname' => (
	is => 'ro',
	isa => Str,
	writer => 'set_realname'
);

=head2 passphrase()

Returns an MD5 digest of the passphrase set for this user.

=head2 set_passphrase( $new_passphrase )

Changes the passphrase of the user to the provided passphrase. Automatically
created an MD5 digest of the passphrase, so do not pass a digested string
here.

=cut

has 'passphrase' => (
	is => 'ro',
	isa => Str,
	required => 1,
	writer => '_set_passphrase'
);

sub set_passphrase {
	my ($self, $passphrase) = @_;

	croak 'You must provide a passphrase.' unless $passphrase;

	$self->_set_passphrase(md5_hex($passphrase));

	return $self;
}

=head2 roles( [\@roles] )

In scalar context, returns an array-ref of all role names this user
belongs to. In list context returns an array. If an array-ref of
role names is provided, it will replace the current list.

=head2 has_roles()

Returns a true value if the user belongs to any role.

=cut

has 'roles' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_roles'
);

=head2 actions( [\@actions] )

In scalar context, returns an array-ref of all action names this user
has been granted. In list context returns an array. If an array-ref of
action names is provided, it will replace the current list.

=head2 has_actions()

Returns a true value if the user has beene explicitely granted any actions.

=cut

has 'actions' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_actions'
);

=head2 is_super()

Returns a true value if this user is a super-user. Super user
can perform every possible action, in ANY SCOPE.

=cut

has 'is_super' => (
	is => 'ro',
	isa => Bool,
	default => 0
);

=head2 customer()

Returns the L<customer|Entities::Customer> entity this user belongs to,
if any.

=head2 has_customer()

Returns a true value if this user is a child of a customer entity.

=cut

has 'customer' => (
	is => 'ro',
	isa => sub { croak 'customer must be an Entities::Customer object' unless blessed $_[0] && blessed $_[0] eq 'Entities::Customer' },
	weak_ref => 1,
	predicate => 'has_customer'
);

=head2 emails( [\@emails] )

In scalar context, returns an array-ref of all email addresses set for this
user. In list context returns an array. If an array-ref of email addresses
is provided, it will replace the current list.

=head2 has_emails()

Returns a true value if the user has any emails assigned.

=cut

has 'emails' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_emails'
);

=head2 created()

Returns a L<DateTime> object in the time the user object has been created.

=cut

has 'created' => (
	is => 'ro',
	isa => sub { croak 'created must be a DateTime object' unless blessed $_[0] && blessed $_[0] eq 'DateTime' },
	default => sub { DateTime->now() }
);

=head2 modified( [$dt] )

Returns a DateTime object in the last time the object has been modified.
If a DateTime object is provided, it is set as the new modified value.

=cut

has 'modified' => (
	is => 'rw',
	isa => sub { croak 'modified must be a DateTime object' unless blessed $_[0] && blessed $_[0] eq 'DateTime' },
	default => sub { DateTime->now() }
);

=head2 parent()

Returns the L<Entities::Backend> instance that stores this object.

=cut

has 'parent' => (
	is => 'ro',
	isa => sub { croak 'parent must be an Entities::Backend' unless blessed $_[0] && $_[0]->does('Entities::Backend') },
	weak_ref => 1
);

with 'Abilities';

=head2 add_to_role( $role_name )

Adds the user to role named C<$role_name>. Croaks if such a role does not
exist, warns if the user is already a member of this role. Returns the
user object itself.

=cut

sub add_to_role {
	my ($self, $role_name) = @_;

	croak "You must provide a role name." unless $role_name;

	# does the user already belongs to this role?
	if ($self->assigned_role($role_name)) {
		carp "User ".$self->username." already belongs to role ".$role_name;
		return $self;
	}

	# find this role, does it even exist?
	my $role = $self->get_role($role_name);
	croak "Role $role_name does not exist." unless $role;

	# add the role
	my @roles = $self->roles;
	push(@roles, $role_name);
	$self->roles(\@roles);

	return $self;
}

=head2 drop_role( $role_name )

Drops the assignment of the user to the role named C<$role_name>. Warns
if the user doesn't belong to this role, does not croak if the role does
not even exist. Returns the user object itself.

=cut

sub drop_role {
	my ($self, $role_name) = @_;

	croak "You must provide a role name." unless $role_name;

	# does the user even have this role?
	unless ($self->assigned_role($role_name)) {
		carp "User ".$self->username." doesn't have role $role_name.";
		return $self;
	}

	# remove the role
	my @roles;
	foreach ($self->roles) {
		next if $_ eq $role_name;
		push(@roles, $_);
	}
	$self->roles(\@roles);

	return $self;
}

=head2 grant_action( $action_name )

Grants the action named C<$action_name> to the user. Croaks if this action
does not exist, warns if the user has already been granted this action.
Returns the user object itself.

=cut

sub grant_action {
	my ($self, $action_name) = @_;

	croak "You must provide an action name." unless $action_name;

	# do we already have this action?
	if ($self->has_direct_action($action_name)) {
		carp "User ".$self->username." already has action ".$action_name;
		return $self;
	}

	# find this action, does it even exist?
	my $action = $self->parent->get_action($action_name);
	croak "Action $action_name does not exist." unless $action;

	# add this action
	my @actions = $self->actions;
	push(@actions, $action_name);
	$self->actions(\@actions);

	return $self;
}

=head2 has_direct_action( $action_name )

Returns a true value if the user has been explictely granted the action
named C<$action_name> (i.e. not via roles).

=cut

sub has_direct_action {
	my ($self, $action_name) = @_;

	unless ($action_name) {
		carp "You must provide an action name.";
		return;
	}

	foreach ($self->actions) {
		return 1 if $_ eq $action_name;
	}

	return;
}

=head2 drop_action( $action_name )

Removes the action named C<$action_name> from the list of actions the user
has been explictely granted to perform. This doesn't necessarily mean the
user will not be able to perform this action anymore, as it might be
available to them via roles. Warns if the user wasn't granted this action,
does not croak if the action does not exist. Returns the user object
itself.

=cut

sub drop_action {
	my ($self, $action_name) = @_;

	croak "You must provide an action name." unless $action_name;

	# do we even have this action?
	unless ($self->has_direct_action($action_name)) {
		carp "User ".$self->username." doesn't have action $action_name.";
		return $self;
	}

	# remove the action
	my @actions;
	foreach ($self->actions) {
		next if $_ eq $action_name;
		push(@actions, $_);
	}
	$self->actions(\@actions);

	return $self;
}

=head2 add_email( $email )

Adds the provided email address to the user's list of email addresses.
Warns if the email is already assigned to this user. Does not (yet) check
if the email is not assigned to any other user. Returns the user object
itself.

=cut

sub add_email {
	my ($self, $email) = @_;

	croak "You must provide an email address." unless $email;

	if ($self->has_email($email)) {
		carp "User ".$self->username." already has email $email";
	} else {
		my @emails = $self->emails;
		push(@emails, $email);
		$self->emails(\@emails);
	}

	return $self;
}

=head2 has_email( $email )

Returns a true value if the user has the provided email.

=cut

sub has_email {
	my ($self, $email) = @_;

	unless ($email) {
		carp "You must provide an email address.";
		return;
	}

	foreach ($self->emails) {
		return 1 if $_ eq $email;
	}

	return;
}

=head2 drop_email( $email_address )

Removes the email address given from the user's list of email addresses.
Warns if user doesn't have that address. Returns the user object itself.

=cut

sub drop_email {
	my ($self, $email) = @_;

	croak "You must provide an email address." unless $email;

	# do we even have this action?
	unless ($self->has_email($email)) {
		carp "User ".$self->username." doesn't have email address $email.";
		return $self;
	}

	# remove the email
	my @emails;
	foreach ($self->emails) {
		next if $_ eq $email;
		push(@emails, $_);
	}
	$self->emails(\@emails);

	return $self;
}

=head2 get_role( $role_name )

Returns the role object of the role named C<$role_name>.

=cut

sub get_role { shift->parent->get_role(@_) }

=head1 METHOD MODIFIERS

The following list documents any method modifications performed through
the magic of L<Moose>.

=head2 around qw/roles actions emails/

If the C<roles()>, C<actions()> and C<emails()> methods are called with no arguments
and in list context - will automatically dereference the array-ref into
arrays.

=cut

around qw/roles actions emails/ => sub {
	my ($orig, $self) = (shift, shift);

	if (scalar @_) {
		return $self->$orig(@_);
	} else {
		my $ret = $self->$orig || [];
		return wantarray ? @$ret : $ret;
	}
};

=head2 around BUILDARGS

Called before creating a new instance of Entities::User, this automatically
turns the provided passphrase into an L<MD5 digest|Digest::MD5>.

=cut

around BUILDARGS => sub {
	my ($orig, $class, %params) = @_;

	if ($params{passphrase}) {
		$params{passphrase} = md5_hex($params{passphrase});
	}

	return $class->$orig(%params);
};

=head2 after anything_that_changes_object

Automatically saves the object to the backend after any method that changed
it was executed. Also updates the 'modified' attribute with the current time
before saving. Note, however, that the C<roles()>, C<action()> and
C<emails()> methods are not here, since they are only meant to be used
for writing internally.

=cut

after qw/set_realname set_username set_passphrase add_to_role drop_role grant_action drop_action add_email drop_email/ => sub {
	$_[0]->modified(DateTime->now);
	$_[0]->parent->save($_[0]);
};

=head1 SEE ALSO

L<Entities>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-entities at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Entities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Entities

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
