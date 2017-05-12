package Java::JCR::Nodetype;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw( Java::JCR );

=head1 NAME

Java::JCR::Nodetype - Load the JCR node type class wrappers

=head1 SYNOPSIS

  use Java::JCR::Nodetype;

=head1 DESCRIPTION

This loads the Perl classes mapped to the C<javax.jcr.nodetype> package.

You might notice the odd letter case of this package differs from that of the node type class (L<Java::JCR::Nodetype::NodeType>). This has to do with the way the package was imported. This may be corrected in the future.

=cut

Java::JCR::import_my_packages();

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
