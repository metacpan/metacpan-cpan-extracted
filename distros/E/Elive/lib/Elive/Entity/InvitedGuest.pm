package Elive::Entity::InvitedGuest;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

extends 'Elive::Entity';

use Carp;

__PACKAGE__->entity_name('InvitedGuest');
__PACKAGE__->collection_name('InvitedGuests');

has 'invitedGuestId' => (is => 'rw', isa => 'Int');
__PACKAGE__->_alias(id => 'invitedGuestId');

has 'loginName' => (is => 'rw', isa => 'Str',
		    documentation => "Guest's login name (usually an email address)");

has 'displayName' => (is => 'rw', isa => 'Str',
		      documentation => "Guest's display name");

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;

    my $args;

    if ($spec && ! ref $spec) {
	if ($spec =~ m{^ \s* 
            ([^;]*?)          # display name
            \s*
            \( ([^;\)]+) \)   # (login name)
            \s*
            (= (\d) \s*)?     # possible '=role' (ignored)
          $}x) {

	    $args = {displayName => $1, loginName => $2};
	}
	else {
	    die "invited guest '$spec': not in format: <Display Name>(<user-id>)'";
	}
    }
    else {
	$args = $spec;
    }

    return $args;
}

coerce 'Elive::Entity::InvitedGuest' => from 'HashRef|Str'
          => via {Elive::Entity::InvitedGuest->new($_)};

=head1 NAME

Elive::Entity::InvitedGuest - Invited Guest entity class

=head1 DESCRIPTION

This is the structural class for an invited guest. It is associated with
meetings via the L<Elive::Entity::Participant> entity.

=cut

=head1 METHODS

=cut

=head2 stringify

Serialize a guest as <displayName> (<loginName>): e.g. C<Robert (bob@acme.com)>.

=cut

sub stringify {
    my $self = shift;
    my $data = shift || $self;

    return $data
	unless Scalar::Util::refaddr($data);

    return sprintf("%s (%s)", $data->{displayName}, $data->{loginName});
}

sub _retrieve_all {
    my ($class, $vals, %opt) = @_;

    #
    # No getXxxx command use listXxxx
    #
    return $class->SUPER::_retrieve_all($vals,
				       command => 'listInvitedGuests',
				       %opt);
}

=head1 SEE ALSO

=over 4

=item Elive::Entity::Session
=item Elive::Entity::Meeting

=back

=cut

1;
