package Math::Rand48::Cursor;

use v5.34;
use warnings;
use experimental qw(signatures);
use Carp         qw(croak);
use Math::BigInt;
use Math::BigFloat;

our $VERSION = '0.001';

my $M  = Math::BigInt->bone->blsft(48);
my $A  = Math::BigInt->from_hex('5DEECE66D');    # drand48 multiplier
my $C  = Math::BigInt->new(11);                  # drand48 increment
my $AI = $A->copy->bmodinv($M);
my $CI = ( -$AI * $C ) % $M;

# Compose the step x -> a*x + c with itself n times, by squaring.
sub _affine_pow ( $a, $c, $n ) {
    my ( $ra, $rc ) = ( Math::BigInt->bone, Math::BigInt->bzero );
    my ( $ba, $bc ) = ( $a->copy, $c->copy );
    until ( $n->is_zero ) {
        ( $ra, $rc ) = ( ( $ba * $ra ) % $M, ( $ba * $rc + $bc ) % $M )
          if $n->is_odd;
        ( $ba, $bc ) = ( ( $ba * $ba ) % $M, ( $ba * $bc + $bc ) % $M );
        $n->brsft(1);
    }
    return ( $ra, $rc );
}

sub new ( $class, %arg ) {
    my $state =
      defined $arg{state}
      ? Math::BigInt->new("$arg{state}")
      : Math::BigInt->bzero;
    return bless { state => $state % $M }, $class;
}

sub from_rand ( $class, $obs ) {
    return $class->new( state => sprintf '%.0f', $obs * 2**48 );
}

sub from_seed48 ( $class, $seed ) {
    my $n = Math::BigFloat->new("$seed");
    croak "from_seed48() seed must be a finite number, got '$seed'"
      if $n->is_nan || $n->is_inf;
    my $int = $n->babs->bfloor->as_int;
    my $x   = $int->blsft(16)->bior( Math::BigInt->from_hex('330e') );
    return $class->new( state => $x );
}

sub state ($self) { $self->{state}->copy }
sub rand  ($self) { $self->{state}->numify / 2**48 }

sub seek ( $self, $n ) {
    my $steps = Math::BigInt->new("$n");
    croak "seek() count must be a finite integer, got '$n'"
      if $steps->is_nan || $steps->is_inf;
    my ( $a,  $c )  = $steps->is_negative ? ( $AI, $CI ) : ( $A, $C );
    my ( $pa, $pc ) = _affine_pow( $a, $c, $steps->babs );
    $self->{state} = ( $pa * $self->{state} + $pc ) % $M;
    return $self;
}

sub forward  ($self) { $self->seek(1) }
sub backward ($self) { $self->seek(-1) }

1;

__END__

=encoding utf-8

=head1 NAME

Math::Rand48::Cursor - Move forward and backward in the drand48/rand() sequence

=head1 SYNOPSIS

    use Math::Rand48::Cursor;

    # Recover the generator state from one observed rand() output:
    my $obs = rand;
    my $rng = Math::Rand48::Cursor->from_rand($obs);

    $rng->rand;                 # == $obs
    $rng->forward->rand;        # the next rand() output
    $rng->backward->rand;       # the previous one

    $rng->seek(1_000_000);      # jump a million steps ahead
    $rng->seek(-1_000_000);     # and back

=head1 DESCRIPTION

Perl's C<rand> is C<drand48(3)>, a 48-bit linear congruential generator. Its
steps can be run in reverse, so a single C<rand()> output is enough to recover
the full internal state. From there you can jump to any point in the sequence.

=head1 METHODS

=head2 new

    my $rng = Math::Rand48::Cursor->new( state => $x );

Construct a cursor at an explicit 48-bit state (integer, string, or
L<Math::BigInt>). Defaults to C<0>.

=head2 from_rand

    my $rng = Math::Rand48::Cursor->from_rand($observed);

Construct a cursor at the state that produced a single observed C<rand()> output.

=head2 from_seed48

    my $rng   = Math::Rand48::Cursor->from_seed48($seed);
    my $first = $rng->forward->rand;    # the first rand() after srand($seed)

Construct a cursor at the state set by C<srand($seed)>, before the first output.

=head3 Seed handling

C<$seed> follows Perl's C<srand> coercion rules, so C<from_seed48> inverts
C<srand>:

=over 4

=item *

Fractional seeds truncate toward zero (C<3.7> becomes C<3>).

=item *

Negative seeds use their absolute value (C<-1> seeds like C<1>), following Perl
rather than libc's C<srand48>.

=item *

Only the low 32 bits matter, so seeds C<< >= 2**32 >> wrap.

=item *

C<NaN> and C<Inf> are rejected with C<croak>.

=back

=head2 state

The current 48-bit state as a L<Math::BigInt>.

=head2 rand

The float C<rand()> would return for the current state.

=head2 seek

    $rng->seek($n);

Move C<$n> steps along the sequence; negative C<$n> seeks backward. Mutates the
cursor and returns it (chainable).

=head2 forward / backward

Shorthand for C<< seek(1) >> and C<< seek(-1) >>.

=head1 AUTHOR

Stig Palmquist E<lt>stig@stig.ioE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
