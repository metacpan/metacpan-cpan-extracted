package Devel::Chitin::OpTree::NULL;
use base 'Devel::Chitin::OpTree';

our $VERSION = '0.22';

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::NULL - Deparser class for null OPs

=head1 DESCRIPTION

NULL OPs shouldn't come up during normal operation.  Sometimes, in the middle
of a crash, the deparser might come across a NULL OP while trying to print out
an OpTree.  This class allows printing that tree instead of crashing.

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
