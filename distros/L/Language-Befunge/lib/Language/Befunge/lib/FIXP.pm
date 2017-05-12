#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::lib::FIXP;
# ABSTRACT: Fixed point operations extension
$Language::Befunge::lib::FIXP::VERSION = '5.000';
use constant PRECISION => 10000;
use Math::Trig;

sub new { return bless {}, shift; }

sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my ($a, $b) = $ip->spop_mult(2);
    $ip->spush( $a & $b );
}

sub B {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $a = $ip->spop / PRECISION;
    $ip->spush( int( rad2deg( acos_real($a) ) * PRECISION ) );
}

sub C {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $a = deg2rad( $ip->spop / PRECISION );
    $ip->spush( int( cos($a) * PRECISION ) );
}

sub D {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $n = $ip->spop;
    $ip->spush( int( rand($n) ) );
}

sub I {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $a = deg2rad( $ip->spop / PRECISION );
    $ip->spush( int( sin($a) * PRECISION ) );
}

sub J {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $a = $ip->spop / PRECISION;
    $ip->spush( int ( rad2deg( asin_real($a) ) * PRECISION ) );
}

sub N {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $n = $ip->spop;
    $ip->spush( -$n );
}

sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my ($a, $b) = $ip->spop_mult(2);
    $ip->spush( $a | $b );
}

sub P {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $n = $ip->spop;
    $ip->spush( int($n * pi)  );
}

sub Q {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $n = $ip->spop;
    $ip->spush( int( sqrt($n) ) );
}

sub R {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my ($a, $b) = $ip->spop_mult(2);
    $ip->spush( int( $a ** $b ) );
}

sub S {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $n = $ip->spop;
    $ip->spush(1)  if $n > 0;
    $ip->spush(0)  if $n == 0;
    $ip->spush(-1) if $n < 0;
}

sub T {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $a = deg2rad( $ip->spop / PRECISION );
    $ip->spush( int( tan($a) * PRECISION ) );
}

sub U {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $a = $ip->spop / PRECISION;
    $ip->spush( int ( rad2deg( atan($a) ) * PRECISION ) );
}

sub V {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $n = $ip->spop;
    $ip->spush( abs $n );
}

sub X {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my ($a, $b) = $ip->spop_mult(2);
    $ip->spush( $a ^ $b );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::FIXP - Fixed point operations extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The FIXP fingerprint (0x4649585) allows to do fixed point operations.

=head1 FUNCTIONS

=head2 new

Create a new FIXP instance.

=head2 Angle operations

Those functions expect their arguments times 10000, and their result follow the
same convention (this gives 4 digits of precision). All angles are in degrees.

=over 4

=item $r = B( $v )

Push back C<acos($v)> on the stack. See precision convention above.

=item $r = C( $v )

Push back C<cos($v)> on the stack. See precision convention above.

=item $r = I( $v )

Push back C<sin($v)> on the stack. See precision convention above.

=item $r = J( $v )

Push back C<asin($v)> on the stack. See precision convention above.

=item $r = T( $v )

Push back C<tan($v)> on the stack. See precision convention above.

=item $r = U( $v )

Push back C<atan($v)> on the stack. See precision convention above.

=back

=head2 Arithmetic functions

=over 4

=item $r = A( $a, $b )

Push back C<$a & $b> on the stack.

=item $r = O( $a ,$b )

Push back C<$a | $b> on the stack.

=item $r = X( $a, $b )

Push back C<$a xor $b> on the stack.

=back

=head2 Numeric functions

=over 4

=item $r = D( $v )

Push back C<rand($v)> on the stack.

=item $r = N( $v )

Push back C<0-$a> on the stack (negation of argument).

=item $r = P( $v )

Push back C<$v * pi> on the stack.

=item $r = Q( $v )

Push back C<sqrt $v> on the stack.

=item $r = R( $a, $b )

Push back C<$a ** $b> on the stack.

=item $r = S( $v )

Push back the sign of C<$v> on the stack.

=item $r = V( $v )

Push back C<abs($v)> on the stack.

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#FIXP>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
