package Math::GrahamFunction::SqFacts::Dipole;

use strict;
use warnings;

=head1 NAME

Math::GrahamFunction::SqFacts::Dipole - a dipole of two vectors - a result and
a composition.

=head1 WARNING!

This is a module for Math::GrahamFunction's internal use only.

=cut

use base qw(Math::GrahamFunction::SqFacts);

use List::Util ();
__PACKAGE__->mk_accessors(qw(result compose));

sub _initialize
{
    my $self = shift;
    my $args = shift;

    $self->result($args->{result});
    $self->compose($args->{compose});

    return 0;
}

=head1 METHODS

=head2 my $copy = $dipole->clone()

Clones the dipole returning a new dipole with the clone of the result and the
composition.

=cut

sub clone
{
    my $self = shift;
    return __PACKAGE__->new(
        {
            'result' => $self->result()->clone(),
            'compose' => $self->compose()->clone(),
        });
}

=head2 $changing_dipole->mult_by($constant_dipole)

Multiplies the result by the result and the composition by the composition.

=cut

sub mult_by
{
    my $n_ref = shift;
    my $m_ref = shift;

    $n_ref->result()->mult_by($m_ref->result());
    $n_ref->compose()->mult_by($m_ref->compose());

    return 0;
}

=head2 $bool = $dipole->is_square()

Returns whether the result is square.

=cut

sub is_square
{
    my $self = shift;
    return $self->result()->is_square();
}

=head2 $bool = $dipole->exists($factor)

Returns whether the factor exists in the result.

=cut

sub exists
{
    my ($self, $factor) = @_;

    return $self->result()->exists($factor);
}

=head2 $first_factor = $dipole->first()

Returns the C<first()> factor of the result vector.

=cut

sub first
{
    my $self = shift;

    return $self->result()->first();
}

=head2 $factors = $dipole->factors()

Equivalent to C<$dipole->result()->factors()>.

=cut

sub factors
{
    my $self = shift;

    return $self->result->factors();
}

sub _get_ret
{
    my $self = shift;

    return [ @{$self->compose->factors()} ];
}

1;

