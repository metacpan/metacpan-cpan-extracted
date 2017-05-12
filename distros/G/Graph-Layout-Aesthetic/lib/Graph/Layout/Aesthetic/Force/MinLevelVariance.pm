package Graph::Layout::Aesthetic::Force::MinLevelVariance;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.02';
use base qw(Graph::Layout::Aesthetic::Force);

__PACKAGE__->new->register;

1;
__END__

=head1 NAME

Graph::Layout::Aesthetic::Force::MinLevelVariance - Try to put nodes at the same level equally far from the left

=head1 SYNOPSIS

  use Graph::Layout::Aesthetic;
  $aglo = Graph::Layout::Aesthetic->new($topology);
  $aglo->add_force("MinLevelVariance", 1);

=head1 DESCRIPTION

This module provides an aesthetic force for use by the
L<Graph::Layout::Aesthetic package|Graph::Layout::Aesthetic>. It's normally
implicitly loaded by using L<add_force|Graph::Layout::Aesthetic/add_force>.

The aesthetic force is that it tries to place nodes on the same level on the
same distance from the left (same x-coordinate). The level of a node is
roughly its distance from a leaf. For each level it then calculates the average
x-coordinate, and for each node it then tries to move it along the x-axis with
a force that grows as the third power of its distance from its level average.

The old aglo documentation describes the force of this aesthetic as
being quadratic in the distance, but that's actually not what the code does.

=head1 METHODS

This class inherits from
L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force> and adds
no methods of its own.

=head1 EXPORT

None.

=head1 SEE ALSO

L<Graph::Layout::Aesthetic>,
L<Graph::Layout::Aesthetic::Force>

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

Much of the underlying L<XS|perlxs> code is derived from C code copyrighted by
D. Stott Parker, who released it under the GNU GENERAL PUBLIC LICENSE
(version 1).

=cut
