package Graph::ReadWrite;
$Graph::ReadWrite::VERSION = '2.09';
use 5.006;
use strict;
use warnings;

1;

=head1 NAME

Graph::ReadWrite - modules for reading and writing directed graphs

=head1 DESCRIPTION

This module is a placeholder in the Graph-ReadWrite distribution,
which is a collection of modules for reading and writing directed graphs.

You don't use C<Graph::ReadWrite>, you use one of the reader or writer
modules for a specific format:

=over 4

=item * L<Graph::Reader::Dot> -
class for reading a Graph instance from Dot format.

=item * L<Graph::Reader::HTK> - read an HTK lattice in as an instance of Graph.

=item * L<Graph::Reader::XML> - class for reading a Graph instance from XML

=item * L<Graph::Writer::Dot> - write out directed graph in Dot format

=item * L<Graph::Writer::HTK> - write a perl Graph out as an HTK lattice file

=item * L<Graph::Writer::VCG> - write out directed graph in VCG format

=item * L<Graph::Writer::XML> - write out directed graph as XML

=item * L<Graph::Writer::daVinci> - write out directed graph in daVinci format

=back

=head1 REPOSITORY

L<https://github.com/neilb/Graph-ReadWrite>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001-2015 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
