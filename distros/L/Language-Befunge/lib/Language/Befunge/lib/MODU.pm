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

package Language::Befunge::lib::MODU;
# ABSTRACT: Modulo Arithmetic extension
$Language::Befunge::lib::MODU::VERSION = '5.000';
use POSIX qw{ floor };

sub new { return bless {}, shift; }


# -- modulus

#
# $mod = M( $x, $y );
#
# signed-result modulo: x MOD y = x - FLOOR(x / y) * y
#
sub M {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $y = $ip->spop;
    my $x = $ip->spop;
    my $mod = $y == 0
        ? 0
        : $x - floor($x/$y)*$y;
    $ip->spush($mod);
}


#
# $mod = U( $x, $y );
#
# Sam Holden's unsigned-result modulo... No idea who this Sam Holden is
# or if he has a special algorithm for this, therefore always returning
# absolute value of standard modulo.
#
sub U {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $y = $ip->spop;
    my $x = $ip->spop;
    if ( $y == 0 ) {
        $ip->spush(0);
        return;
    }
    my $mod = $x % $y;
    $ip->spush(abs($mod));
}


#
# $mod = R( $x, $y );
#
# C-language integer remainder: old C leaves negative modulo undefined
# but C99 defines it as the same sign as the dividend so that's what we're
# going with.
#
sub R {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $y = $ip->spop;
    my $x = $ip->spop;
    if ( $y == 0 ) {
        $ip->spush(0);
        return;
    }

    my $mod = $x % $y;
    if ( ($x <= 0 && $mod <= 0) || ($x >= 0 && $mod >= 0)) {
        $ip->spush( $mod );
    } else {
        $ip->spush( -$mod );
    }    
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::MODU - Modulo Arithmetic extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The MODU fingerprint (0x4d4f4455) implements some of the finer, less-well-
agreed-upon points of modulo arithmetic. With positive arguments, these
instructions work exactly the same as C<%> does. However, when negative
values are involved, they all work differently.

=head1 FUNCTIONS

=head2 new

Create a new MODU instance.

=head2 Modulo implementations

=over 4

=item $mod = M( $x, $y )

Signed-result modulo: x MOD y = x - FLOOR(x / y) * y

=item $mod = U( $x, $y )

Sam Holden's unsigned-result modulo... No idea who this Sam Holden is
or if he has a special algorithm for this, therefore always returning
absolute value of standard modulo.

=item $mod = R( $x, $y )

C-language integer remainder: old C leaves negative modulo undefined
but C99 defines it as the same sign as the dividend so that's what we're
going with.

=back

=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/MODU.html>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
