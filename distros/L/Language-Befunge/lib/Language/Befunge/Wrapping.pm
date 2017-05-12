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

package Language::Befunge::Wrapping;
# ABSTRACT: base wrapping class
$Language::Befunge::Wrapping::VERSION = '5.000';

# -- CONSTRUCTOR

use Class::XSAccessor constructor => 'new';


# -- PUBLIC METHODS

#
# $wrapping->wrap( $storage, $ip );
#
# Wrap $ip in $storage according to this module wrapping algorithm. Note
# that $ip is already out of bounds, ie, it has been moved once by LBI.
# As a side effect, $ip will have its position changed.
#
# LBW implements a wrapping that dies. It's meant to be overridden by
# other wrapping classes.
#
sub wrap { die 'wrapping not implemented in LBW'; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Wrapping - base wrapping class

=head1 VERSION

version 5.000

=head1 DESCRIPTION

C<LBW> implements a wrapping that dies. It's meant to be overridden by
other wrapping classes.

=head1 CONSTRUCTOR

=head2 LBW->new;

Creates a new wrapping object.

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
