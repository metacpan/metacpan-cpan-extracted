package Elive::Entity::Participant;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

use Scalar::Util;

use Elive;
use Elive::Util;
use Elive::Entity::User;
use Elive::Entity::Group;
use Elive::Entity::InvitedGuest;
use Elive::Entity::Role;
use Try::Tiny;

=head1 NAME

Elive::Entity::Participant - A Single Meeting Participant

=head1 DESCRIPTION

This is a component of L<Elive::Entity::Participants>. It contains details
on a participating user, including their type and participation role.

=head1 METHODS

=cut

__PACKAGE__->entity_name('Participant');

has 'user' => (is => 'rw', isa => 'Elive::Entity::User',
		documentation => 'User (type=0)',
		coerce => 1,
    );

has 'group' => (is => 'rw', isa => 'Elive::Entity::Group',
	       documentation => 'Group of attendees (type=1)',
	       coerce => 1,
    );
# for the benefit of createSession and updateSession commands
__PACKAGE__->_alias(participant => 'user' );

has 'guest' => (is => 'rw', isa => 'Elive::Entity::InvitedGuest',
		documentation => 'Guest (type=2)',
		coerce => 1,
    );
__PACKAGE__->_alias( invitedGuestId => 'guest' );

has 'role' => (is => 'rw', isa => 'Elive::Entity::Role',
	       documentation => 'Role level of the meeting participant',
	       coerce => 1,
    );

has 'type' => (is => 'rw', isa => 'Int',
	       documentation => 'type of participant; 0:user, 1:group, 2:guest'
    );

our ( $TYPE_USER, $TYPE_GROUP, $TYPE_GUEST );
BEGIN {
    $TYPE_USER  = 0;
    $TYPE_GROUP = 1;
    $TYPE_GUEST = 2;
}

sub BUILDARGS {
    my $class = shift;
    local ($_) = shift;

    if (Scalar::Util::blessed($_)) {

	if (try {$_->isa('Elive::Entity::User')}) {
	    #
	    # coerce participant as regular user
	    #
	    return {
		user => $_,
		role => {roleId => ${Elive::Entity::Role::PARTICIPANT}},
		type => $TYPE_USER,
	    }
	}

	if (try {$_->isa('Elive::Entity::Group')}) {
	    #
	    # coerce to group of participants
	    #
	    return {
		group => $_,
		role => {roleId => ${Elive::Entity::Role::PARTICIPANT}},
		type => $TYPE_GROUP,
	    }
	}

	if (try {$_->isa('Elive::Entity::InvitedGuest')}) {
	    #
	    # coerce to an invited guest
	    #
	    return {
		guest => $_,
		role => {roleId => ${Elive::Entity::Role::PARTICIPANT}},
		type => $TYPE_GUEST,
	    }
	}
    }

    my $reftype = Elive::Util::_reftype($_);
    if ($reftype eq 'HASH') {
	# already structured as a participant
	my %spec = %$_;

	my $type;
	if ($spec{user}) {
	    $spec{type} ||= $TYPE_USER;
	}
	elsif ($spec{group}) {
	    $spec{type} ||= $TYPE_GROUP;
	}
	elsif ($spec{guest}) {
	    $spec{type} ||= $TYPE_GUEST;
	}

	return \%spec if defined $spec{type};
    }

    if ($reftype) {
	warn YAML::Syck::Dump({unbuildable_participant => $_})
	    if Elive->debug;
	die "unable to build participant from $reftype reference";
    }

    #
    # Simple users:
    #     'bob=3' => user:bob, role:3, type: 0 (user)
    #     'alice' => user:bob, role:3 (defaulted), type: 0 (user)
    # A leading '*' indicates a group:
    #     '*mygroup=2' => group:mygroup, role:2 type:1 (group)
    # Invited guests are of the form: displayName(loginName)
    #     'Robert(bob)' => guest:{loginName:bob, displayName:Robert}
    #
    my %parse;

    if (m{^ \s* 
            ([^;]*?)          # display name
            \s*
            \( ([^;\)]+) \)   # (login name)
            \s*
            (= (\d) \s*)?     # possible '=role' (ignored)
          $}x) {

	$parse{guest} = {displayName => $1, loginName => $2};
	$parse{type} = $TYPE_GUEST;

	return \%parse;
    }
    elsif (m{^ \s*
               (\*?)          # optional group indicator '*'
               \s*
               ([^,]*?)       # user/group id
               \s*
               (= (\d) \s*)?  # optional '=role'
             $}x) {

	my $is_group = $1;
	my $id = $2;
	my $roleId = $4;

	$roleId = ${Elive::Entity::Role::PARTICIPANT}
	    unless defined $roleId && $roleId ne '';

	if ( $is_group ) {
	    $parse{group} = {groupId => $id};
	    $parse{type} = $TYPE_GROUP;
	}
	else {
	    $parse{user} = {userId => $id};
	    $parse{type} = $TYPE_USER;
	}

	$parse{role}{roleId} = $roleId;

	return \%parse;
    }

    #
    # slightly convoluted die on return to keep Perl::Critic happy
    #
    return die "participant '$_' not in format: userId=[0-3] or *groupId=[0-3] or guestName(guestLogin)";
}

coerce 'Elive::Entity::Participant' => from 'Str'
    => via { __PACKAGE__->new( $_) };

=head2 participant

Returns a participant. This can either be of type L<Elive::Entity::User> (type
0), L<Elive::Entity::Group> (type 1) or L<Elive::Entity::InvitedGuest> (type 2).

=cut

sub participant {
    my ($self) = @_;
 
    return (!defined $self->type || $self->type == $TYPE_USER) ? $self->user
       : ($self->type == $TYPE_GROUP) ? $self->group
       : ($self->type == $TYPE_GUEST) ? $self->guest
       : do {warn "unknown participant type: ".$self->type;
	     $self->user || $self->group || $self->guest};
}

=head2 is_moderator

Utility method to examine or set a meeting participant's moderator privileges.

    # does Bob have moderator privileges?
    my $is_moderator = $bob->is_moderator;

    # grant moderator privileges to Alice
    $alice->is_moderator(1);  

=cut

sub is_moderator {
    my $self = shift;

    my $role_id;

    if (defined $self->type && $self->type == $TYPE_GUEST) {
	#
	# invited guests cannot be moderators
	return;
    }

    if (@_) {
	my $is_moderator = shift;
	$role_id = $is_moderator
	    ? ${Elive::Entity::Role::MODERATOR}
	    : ${Elive::Entity::Role::PARTICIPANT};

	$self->role( $role_id )
	    unless $role_id == $self->role->stringify;
    }
    else {
	$role_id = $self->role->stringify;
    }

    return defined $role_id && $role_id != ${Elive::Entity::Role::PARTICIPANT};
}

=head2 stringify

Returns a string of the form 'userId=role' (users) '*groupId=role (groups),
or displayName(loginName) (guests). This value is used for comparisons,
display, etc...

=cut

sub stringify {
    my $self = shift;
    my $data = shift || $self;

    $data = $self->BUILDARGS($data);
    my $role_id = Elive::Entity::Role->stringify( $data->{role} );

    if (!defined $data->{type} || $data->{type} == $TYPE_USER) {
	# user => 'userId'
	return Elive::Entity::User->stringify($data->{user}).'='.$role_id;
    }
    elsif ($data->{type} == $TYPE_GUEST) {
	# guest => 'displayName(loginName)'
	my $guest_str =  Elive::Entity::InvitedGuest->stringify($data->{guest});

	Carp::carp ("ignoring moderator role for invited guest: $guest_str")
	    if defined $role_id && $role_id != ${Elive::Entity::Role::PARTICIPANT};

	return $guest_str;
    }
    elsif ($data->{type} == $TYPE_GROUP) {
	# group => '*groupId'
	return Elive::Entity::Group->stringify($data->{group}).'='.$role_id;
    }
    else {
	# unknown
	die "unrecognised participant type: $data->{type}";
    }
}

=head1 SEE ALSO

L<Elive::Entity::ParticipantList>
L<Elive::Entity::Participants>
L<Elive::Entity::User>
L<Elive::Entity::Group>
L<Elive::Entity::InvitedGuest>;
L<Elive::Entity::Role>

=cut

1;
