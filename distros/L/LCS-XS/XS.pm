package LCS::XS;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.04';

require XSLoader;
XSLoader::load('LCS::XS', $VERSION);


1;

__END__

=head1 NAME

LCS::XS - Fast (XS) implementation of the
                 Longest Common Subsequence (LCS) Algorithm

=head1 SYNOPSIS

  use LCS::XS;

  $alg = LCS::XS->new;
  @lcs = $alg->LCS(\@a,\@b);


=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4

=item LCS(\@a,\@b)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments.

=back

=head2 EXPORT

None by design.

=head1 SEE ALSO

Algorithm::Diff

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
