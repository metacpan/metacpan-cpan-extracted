#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::CPLI;
# ABSTRACT: Complex numbers extension
$Language::Befunge::lib::CPLI::VERSION = '5.000';
use Math::Complex;

sub new { return bless {}, shift; }


# -- operations

#
# ($r, $i) = A( $ar, $ai, $br, $bi )
#
# push ($ar+i*$ai) + ($br+i*$bi) back onto the stack (complex addition)
#
sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $bi = $ip->spop;
    my $br = $ip->spop;
    my $ai = $ip->spop;
    my $ar = $ip->spop;
    my $a = cplx($ar, $ai);
    my $b = cplx($br, $bi);
	
	# push the result
    my $c = $a + $b;
	$ip->spush( $c->Re, $c->Im );
}


#
# ($r, $i) = D( $ar, $ai, $br, $bi )
#
# push ($ar+i*$ai) / ($br+i*$bi) back onto the stack (complex division)
#
sub D {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $bi = $ip->spop;
    my $br = $ip->spop;
    my $ai = $ip->spop;
    my $ar = $ip->spop;
    my $a = cplx($ar, $ai);
    my $b = cplx($br, $bi);
	
	# push the result
    my $c = $a / $b;
	$ip->spush( $c->Re, $c->Im );
}


#
# ($r, $i) = M( $ar, $ai, $br, $bi )
#
# push ($ar+i*$ai) * ($br+i*$bi) back onto the stack (complex multiplication)
#
sub M {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $bi = $ip->spop;
    my $br = $ip->spop;
    my $ai = $ip->spop;
    my $ar = $ip->spop;
    my $a = cplx($ar, $ai);
    my $b = cplx($br, $bi);
	
	# push the result
    my $c = $a * $b;
	$ip->spush( $c->Re, $c->Im );
}


#
# ($r, $i) = S( $ar, $ai, $br, $bi )
#
# push ($ar+i*$ai) - ($br+i*$bi) back onto the stack (complex subtraction)
#
sub S {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $bi = $ip->spop;
    my $br = $ip->spop;
    my $ai = $ip->spop;
    my $ar = $ip->spop;
    my $a = cplx($ar, $ai);
    my $b = cplx($br, $bi);
	
	# push the result
    my $c = $a - $b;
	$ip->spush( $c->Re, $c->Im );
}


#
# $n = V( $r, $i )
#
# push absolute value of complex $r+i*$i
#
sub V {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $i = $ip->spop;
    my $r = $ip->spop;

    my $c = cplx($r, $i);
	$ip->spush( $c->abs );
}


# -- display

#
# O( $r, $i )
#
# output complex number $r+i*$i
#
sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $i = $ip->spop;
    my $r = $ip->spop;

    # print the complex
    my $c = cplx($r, $i);
	print $c;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::CPLI - Complex numbers extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The CPLI fingerprint (0x43504C49) allows to do complex numbers operations.

=head1 FUNCTIONS

=head2 new

Create a new CPLI instance.

=head2 Complex operations

=over 4

=item * ($r, $i) = A( $ar, $ai, $br, $bi )

Push ($ar+i*$ai) + ($br+i*$bi) back onto the stack (complex addition)

=item * ($r, $i) = D( $ar, $ai, $br, $bi )

Push ($ar+i*$ai) + ($br+i*$bi) back onto the stack (complex division)

=item * ($r, $i) = M( $ar, $ai, $br, $bi )

Push ($ar+i*$ai) + ($br+i*$bi) back onto the stack (complex multiplication)

=item * ($r, $i) = S( $ar, $ai, $br, $bi )

Push ($ar+i*$ai) + ($br+i*$bi) back onto the stack (complex subtraction)

=item * V( $r, $i )

Push back absolute value of complex C<$r + i* $i>.

=back

=head2 Output

=over 4

=item * O( $r, $i )

Output complex number C<$r + i * $i>.

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#CPLI>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
