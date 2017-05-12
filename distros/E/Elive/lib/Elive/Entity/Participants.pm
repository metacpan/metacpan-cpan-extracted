package Elive::Entity::Participants;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::DAO::Array';

use Elive::Entity::Participant;
use Elive::Entity::Role;
use Elive::Util;

__PACKAGE__->element_class('Elive::Entity::Participant');
__PACKAGE__->mk_classdata('separator' => ';');

=head1 NAME

Elive::Entity::Participants - A list of participants

=head1 DESCRIPTION

This class implements the C<participants> property of C<Elive::Entity::Session>
and C<Elive::Entity::ParticipantList>

=cut

=head1 METHODS

=cut

sub _build_array {
    my $class = shift;
    my $spec = shift;

    my $type = Elive::Util::_reftype( $spec );

    my @participants;

    if ($type) {
	$spec = [$spec]
	    unless $type eq 'ARRAY';

	@participants = @$spec;
    }
    elsif (defined $spec) {
	@participants = split(__PACKAGE__->separator, Elive::Util::string($spec));
    }

    my $cur_role;
    my @args;
    my $element_class = $class->element_class;

    foreach (@participants) {

	foreach (Elive::Util::_reftype($_) eq 'ARRAY' ? @$_ : ($_)) {
	    next unless defined;

	    if (!ref && m{^-(\w+)$}) {
		my $opt = $1;

		if ($opt =~ m{^(participant|other)(s?)$}) {
		    $cur_role = ${Elive::Entity::Role::PARTICIPANT};
		}
		elsif ($opt =~ m{^moderator(s?)$}) {
		    $cur_role = ${Elive::Entity::Role::MODERATOR};
		}
		else {
		    die "unknown option '$_' in participant list (expected: '-participant', '-moderator' or '-other'";
		}
	    }
	    else {
		my $participant = $_;
		$participant = $element_class->new($participant)
		    unless ref && Scalar::Util::blessed($_) && $_->isa($element_class);

		$participant->role($cur_role) if $cur_role;

		push (@args, $participant);
	    }
	}
    }

    return \@args;
}

=head2 add 

    $participants->add('alice=2', 'bob');

Add additional participants

=cut

sub add {
    my ($self, @elems) = @_;

    my $participants = $self->_build_array( \@elems );

    return $self->SUPER::add( @$participants );
}

our $class = __PACKAGE__;
coerce $class => from 'ArrayRef|Str'
          => via {$class->new($_);};

sub _group_by_type {
    my $self = shift;

    my @raw_participants = @{ $self || [] };

    my %users;
    my %groups;
    my %guests;

    foreach my $participant (@raw_participants) {

	$participant = Elive::Entity::Participant->new($participant)
	    unless Scalar::Util::blessed $participant
	    && $participant->isa('Elive::Entity::Participant');

	my $id;
	my $roleId = Elive::Entity::Role->stringify( $participant->role )
	    || ${Elive::Entity::Role::PARTICIPANT};

	if (!defined $participant->type || $participant->type == ${Elive::Entity::Participant::TYPE_USER}) {
	    $id = Elive::Entity::User->stringify( $participant->user );
	    $users{ $id } = $roleId;
	}
	elsif ($participant->type == ${Elive::Entity::Participant::TYPE_GROUP}) {
	    $id = Elive::Entity::Group->stringify( $participant->group );
	    $groups{ $id } = $roleId;
	}
	elsif ($participant->type == ${Elive::Entity::Participant::TYPE_GUEST}) {
	    $id = Elive::Entity::InvitedGuest->stringify( $participant->guest );
	    $guests{ $id } = $roleId;
	}
	else {
	    carp("unknown type: $participant->{type} in participant list: ".$self->id);
	}
    }

    return (\%users, \%groups, \%guests);
}

=head2 tidied

    my $untidy = 'trev;bob=3;bob=2'
    my $participants = Elive::Entity::Participants->new($untidy);
    # outputs: alice=2;bob=3;trev=3
    print $participants->tidied;

Produces a tidied list of participants. These are sorted with duplicates
removed (highest role is retained).

The C<facilitatorId> option can be used to ensure that the meeting facilitator
is included and has a moderator role.
     
=cut

sub tidied {
    my $self = shift;

    my ($_users, $_groups, $_guests) = $self->_group_by_type;

    # weed out duplicates as we go
    my %roles = (%$_users, %$_groups, %$_guests);

    if (wantarray) {

	# elm3.x compat

	my %guests;
	my %moderators;
	my %participants;

	foreach (sort keys %roles) {

	    my $role = $roles{$_};

	    if (exists $_guests->{$_} ) {
		$guests{$_} = $role;
	    }
	    elsif ($role <= 2) {
		$moderators{$_} = $role;
	    }
	    else {
		$participants{$_} = $role;
	    }
	}

	return ([ sort keys %guests],
		[ sort keys %moderators],
		[ sort keys %participants])
    }
    else {
	# elm2.x compat
       return $self->stringify([ map { $_.'='.$roles{$_} } sort keys %roles ]);
    }
}

=head1 SEE ALSO 

L<Elive::Entity::Session>
L<Elive::Entity::ParticipantList>

=cut

1;
