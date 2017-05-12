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

package Language::Befunge::Wrapping::LaheySpace;
# ABSTRACT: a LaheySpace wrapping
$Language::Befunge::Wrapping::LaheySpace::VERSION = '5.000';

use base qw{ Language::Befunge::Wrapping };


# -- PUBLIC METHODS

#
# $wrapping->wrap( $storage, $ip );
#
# Wrap $ip in $storage according to this module wrapping algorithm. Note
# that $ip is already out of bounds, ie, it has been moved once by LBI.
# As a side effect, $ip will have its position changed.
#
# LBW::LaheySpace implements a wrapping as defined in befunge specs -
# ie, when hitting a bound of the storage, the ip reverses and
# backtraces until it bumps into another bound, and then it reverses one
# last time to keep its velocity.
#
sub wrap {
    my ($self, $storage, $ip) = @_;

    # fetch the current position/velocity of the ip.
    my $v = $ip->get_position;
    my $d = $ip->get_delta;

    # fetch the storage min / max
    my $min = $storage->min;
    my $max = $storage->max;

    # funge98 says we should walk our current trajectory in reverse,
    # until we hit the other side of the storage, and then continue
    # along the same path.
    do {
        $v -= $d;
    } while ( $v->bounds_check($min, $max) );

    # now that we've hit the wall, walk back into the valid code range.
    $v += $d;

    # store new position.
    $ip->set_position($v);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Wrapping::LaheySpace - a LaheySpace wrapping

=head1 VERSION

version 5.000

=head1 DESCRIPTION

C<LBW::LaheySpace> implements a wrapping as defined in befunge specs - ie,
when hitting a bound of the storage, the ip reverses and backtraces
until it bumps into another bound, and then it reverses one last time to
keep its velocity.

=head1 CONSTRUCTOR

=head2 LBW::LaheySpace->new;

Creates a new LaheySpace wrapping.

=head1 PUBLIC METHODS

=head2 $wrapping->wrap( $storage, $ip )

Wrap C<$ip> in C<$storage> according to this module wrapping algorithm.
See L<DESCRIPTION> for an overview of the algorithm used.

Note that C<$ip> is already out of bounds, ie, it has been moved once by
LBI.

As a side effect, $ip will have its position changed.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
