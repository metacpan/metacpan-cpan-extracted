package Graph::Layout::Aesthetic::Force::MinEdgeIntersect2;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.02';
use base qw(Graph::Layout::Aesthetic::Force);

__PACKAGE__->new->register;

1;
__END__

=head1 NAME

Graph::Layout::Aesthetic::Force::MinEdgeIntersect2 - Try to make edges uncross, stronger version

=head1 SYNOPSIS

  use Graph::Layout::Aesthetic;
  $aglo = Graph::Layout::Aesthetic->new($topology);
  $aglo->add_force("MinEdgeIntersect2", 1);

=head1 DESCRIPTION

This module provides an aesthetic force for use by the
L<Graph::Layout::Aesthetic package|Graph::Layout::Aesthetic>. It's normally
implicitly loaded by using L<add_force|Graph::Layout::Aesthetic/add_force>.

The aesthetic force is that crossed edge midpoints repel each other with
force linear in the distance. The code only works in two dimensions, so it
will throw an exception if you try to
L<associate|Graph::Layout::Aesthetic/add_force> this force with a layout that's
not two-dimensional.

The old aglo documentation describes this aesthetic as using a constant force,
but that's actually not what the code does.

=head1 METHODS

This class inherits from
L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force> and adds
no methods of its own.

=head1 EXPORT

None.

=head1 SEE ALSO

L<Graph::Layout::Aesthetic>,
L<Graph::Layout::Aesthetic::Force>,
L<Graph::Layout::Aesthetic::Force::MinEdgeIntersect>

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
