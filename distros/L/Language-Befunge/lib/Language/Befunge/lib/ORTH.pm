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

package Language::Befunge::lib::ORTH;
# ABSTRACT: Orthogonal easement extension
$Language::Befunge::lib::ORTH::VERSION = '5.000';
use Language::Befunge::Vector;

sub new { return bless {}, shift; }


# -- bit operations

#
# $v = A( $a, $b )
#
# push $a & $b back onto the stack (bitwise AND)
#
sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a&$b );
}


#
# $v = E( $a, $b )
#
# push $a ^ $b back onto the stack (bitwise XOR)
#
sub E {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a^$b );
}


#
# $v = O( $a, $b )
#
# push $a | $b back onto the stack (bitwise OR)
#
sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a|$b );
}


# -- push / get

#
# $v = G( $y, $x )
#
# push back value stored at coords ($x, $y). note that befunge get is g($x,$y)
# (ie, the arguments are reversed).
#
sub G {
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;

    my $x = $ip->spop;
    my $y = $ip->spop;
	my $v = Language::Befunge::Vector->new($x,$y);
    my $val = $lbi->get_storage->get_value( $v );
    $ip->spush( $val );
}


#
# P( $v, $y, $x )
#
# store value $v at coords ($x, $y). note that befunge put is p($v,$x,$y) (ie,
# the coordinates are reversed).
#
sub P {
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;

    my $x = $ip->spop;
    my $y = $ip->spop;
	my $v = Language::Befunge::Vector->new($x,$y);
	my $val = $ip->spop;
    $lbi->get_storage->set_value( $v, $val );
}


# -- output

#
# S( 0gnirts )
#
# print popped 0gnirts on stdout.
#
sub S {
    my ($self, $lbi) = @_;
    print $lbi->get_curip->spop_gnirts;
}


# -- coordinates & velocity changes

#
# X( $x )
#
# Change X coordinate of IP to $x.
#
sub X {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v = $ip->get_position;
    my $x = $ip->spop;
	$v->set_component(0,$x);
}

#
# Y( $y )
#
# Change Y coordinate of IP to $y.
#
sub Y {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v = $ip->get_position;
    my $y = $ip->spop;
	$v->set_component(1,$y);
}


#
# V( $dx )
#
# Change X coordinate of IP velocity to $dx.
#
sub V {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v  = $ip->get_delta;
    my $dx = $ip->spop;
	$v->set_component(0,$dx);
}


#
# W( $dy )
#
# Change Y coordinate of IP velocity to $dy.
#
sub W {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v  = $ip->get_delta;
    my $dy = $ip->spop;
	$v->set_component(1,$dy);
}


# -- misc

#
# Z( $bool )
#
# Test the top stack element, and if zero, skip over the next cell (i.e., add
# the delta twice to the current position).
#
sub Z {
	my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v  = $ip->spop;
	$lbi->_move_ip_once($ip) if $v == 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::ORTH - Orthogonal easement extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The ORTH fingerprint (0x4f525448) is designed to ease transition between the
Orthogonal programming language and Befunge-98 (or higher dimension Funges).

Even if transition from Orthogonal is not an issue, the ORTH library contains
some potentially interesting instructions not in standard Funge-98.

=head1 FUNCTIONS

=head2 new

Create a new ORTH instance.

=head2 Bit operations

=over 4

=item A( $a, $b )

Push back C<$a & $b> (bitwise AND).

=item O( $a, $b )

Push back C<$a | $b> (bitwise OR).

=item E( $a, $b )

Push back C<$a ^ $b> (bitwise XOR).

=back

=head2 Push & get

=over 4

=item G( $y, $x )

Push back value stored at coords ($x, $y). Note that Befunge get is C<g($x,$y)>
(ie, the arguments are reversed).

=item P( $v, $y, $x )

Store value C<$v> at coords ($x, $y). Note that Befunge put is C<p($v,$x,$y)> (ie,
the coordinates are reversed).

=back

=head2 Output

=over 4

=item S( 0gnirts )

Print popped 0gnirts on STDOUT.

=back

=head2 Coordinates & velocity changes

=over 4

=item X( $x )

Change X coordinate of IP to C<$x>.

=item Y( $y )

Change Y coordinate of IP to C<$y>.

=item V( $dx )

Change X coordinate of IP velocity to C<$dx>.

=item W( $dy )

Change Y coordinate of IP velocity to C<$dy>.

=back

=head2 Miscellaneous

=over 4

=item Z( $bool )

Test the top stack element, and if zero, skip over the next cell (i.e., add
the delta twice to the current position).

=back

=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/ORTH.html>,
L<http://www.muppetlabs.com/~breadbox/orth/orth.html>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
