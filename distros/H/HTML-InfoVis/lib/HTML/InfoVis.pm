package HTML::InfoVis;

=pod

=head1 NAME

HTML::InfoVis - Content generators for the InfoVis Javascript toolkit

=head1 DESCRIPTION

B<HTML::InfoVis> is an experimental set of packages that provide a Perl API
to the JavaScript InfoVis tree/graph rendering library.

More information can be found at L<http://thejit.org/>.

In this initial implementation, the only available class is
L<HTML::InfoVis::Graph>, which assists in generation InfoVis-compatible
JSON graph dumps.

=cut

use 5.006;
use strict;
use HTML::InfoVis::Graph ();

our $VERSION = '0.03';

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-InfoVis>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
