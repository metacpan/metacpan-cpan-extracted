package Entities::Role;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw/Any Str Bool ArrayRef/;
use Scalar::Util qw/blessed/;
use namespace::autoclean;

# ABSTRACT: A collection of possibly related actions granted to users.

=head1 NAME

Entities::Role - A collection of possibly related actions granted to users.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	used internally, see L<Entities>

=head1 DESCRIPTION

A role is merely a collection of actions. Users are assigned to these roles
to easily provide them with abilities they might need, probably to perform
their 'roles' in a webapp (think of roles such as 'admins', 'members',
'vandal_fighters' or 'trolls'; probably not trolls though).

Roles can inherit all action of other roles, to allow for a structured
authorization-system that is easier to apply and follow.

This entity class C<does> the L<Abilities> L<Moose role|Moose::Role>.

NOTE: you are not meant to create role objects directly, but only through
the C<new_role()> method in L<Entities>.

=head1 METHODS

=head2 new( name => 'somerole', [ description => 'Just some role',
is_super => 0, roles => [], actions => [], created => $dt_obj,
modified => $other_dt_obj, parent => $entities_obj, id => 123 ] )

Creates a new instance of this module. Only 'name' is required.

=head2 id()

Returns the ID of the role, if set.

=head2 has_id()

Returns a true value if the role object has an ID attribute.

=head2 _set_id( $id )

Sets the ID of the role object to the provided value. Only to be used
internally.

=cut

has 'id' => (
	is => 'ro',
	isa => Any,
	predicate => 'has_id',
	writer => '_set_id'
);

=head2 name()

Returns the name of the role.

=cut

has 'name' => (
	is => 'ro',
	isa => Str,
	required => 1
);

=head2 description()

Returns the description text of this role.

=head2 set_description( $desc )

Changes the description text of the object to the provided text.

=cut

has 'description' => (
	is => 'ro',
	isa => Str,
	writer => 'set_description'
);

=head2 roles( [\@roles] )

In scalar context, returns an array-ref of all role names this role
inherits from. In list context returns an array. If an array-ref of
role names is provided, it will replace the current list.

=head2 has_roles()

Returns a true value if the role inherits from any other roles.

=cut

has 'roles' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_roles'
);

=head2 _actions( [\@actions] )

In scalar context, returns an array-ref of all action names this role
has. In list context returns an array. If an array-ref of
action names is provided, it will replace the current list.

=head2 has_actions()

Returns a true value if the role has been granted any actions.

=head2 actions()

Returns an array of all action names this role has been granted.

=cut

has 'actions' => (
	is => 'rw',
	isa => ArrayRef[Str],
	predicate => 'has_actions'
);

=head2 is_super()

Returns a true value if this role is considered a super-role. Super roles
can do every possible action, in ANY SCOPE.

=cut

has 'is_super' => (
	is => 'ro',
	isa => Bool,
	default => 0
);

=head2 created()

Returns a L<DateTime> object in the time the role object has been created.

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

=head2 has_direct_action( $action_name )

Returns a true value if the role has been explicitely grant the action
named C<$action_named> (i.e. not through inheritance).

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

=head2 grant_action( $action_name )

Grants the action named C<$action_name> to the role. Croaks if the action
does not exist, warns if the role has already been granted this action.

Returns the role object itself.

=cut

sub grant_action {
	my ($self, $action_name) = @_;

	croak "You must provide an action name." unless $action_name;

	# does this role already have that feature?
	if ($self->has_direct_action($action_name)) {
		carp "Role ".$self->name." already has action ".$action_name;
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

=head2 drop_action( $action_name )

Removes the action named C<$action_name> from the list of actions the role
has been explictely granted to perform. This doesn't necessarily mean the
role will not be able to perform this action anymore, as it might be
available to it via inherited roles. Warns if the role wasn't granted this action,
does not croak if the action does not exist. Returns the role object
itself.

=cut

sub drop_action {
	my ($self, $action_name) = @_;

	croak "You must provide an action name." unless $action_name;

	# do we even have this action?
	unless ($self->has_direct_action($action_name)) {
		carp "Role ".$self->name." doesn't have action $action_name.";
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

=head2 inherit_from_role( $role_name )

Sets up an inheritance between the current role object and the role whose
name is C<$role_name>. Croaks if C<$role_name> cannot be found, warns if
such an inheritance already exists.

Returns the role object itself.

=cut

sub inherit_from_role {
	my ($self, $role_name) = @_;

	croak "You must provide a role name." unless $role_name;

	# do we already take from this role?
	if ($self->assigned_role($role_name)) {
		carp "Role ".$self->name." already inherits from ".$role_name;
		return $self;
	}

	# find this role, does it even exist?
	my $role = $self->get_role($role_name);
	croak "Role $role_name does not exist." unless $role;

	# add this role
	my @roles = $self->roles;
	push(@roles, $role_name);
	$self->roles(\@roles);

	return $self;
}

=head2 dont_inherit_from_role( $role_name )

This badly named method drops the inheritance from the role named C<$role_name>. Warns
if the role object doesn't inherit from the provided role, does not croak
if the provided role does not even exist. Returns the role object itself.

=cut

sub dont_inherit_from_role {
	my ($self, $role_name) = @_;

	croak "You must provide a role name." unless $role_name;

	# does the user even have this role?
	unless ($self->assigned_role($role_name)) {
		carp "Role ".$self->name." doesn't inherit from role $role_name.";
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

=head2 get_role( $role_name )

Returns the role object of the role named C<$role_name>.

=cut

sub get_role { shift->parent->get_role(@_) }

=head1 METHOD MODIFIERS

The following list documents any method modifications performed through
the magic of L<Moose>.

=head2 around qw/roles actions/

If the C<roles()> and C<actions()> methods are called with no arguments
and in list context - will automatically dereference the array-ref into
arrays.

=cut

around qw/roles actions/ => sub {
	my ($orig, $self) = (shift, shift);

	if (scalar @_) {
		return $self->$orig(@_);
	} else {
		my $ret = $self->$orig || [];
		return wantarray ? @$ret : $ret;
	}
};

=head2 after anything_that_changes_object

Automatically saves the object to the backend after any method that changed
it was executed. Also updates the 'modified' attribute with the current time
before saving. Note, however, that the C<roles()> and C<action()> methods
are not here, since they are only meant to be used for writing internally.

=cut

after qw/set_description grant_action drop_action inherit_from_role dont_inherit_from_role/ => sub {
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
