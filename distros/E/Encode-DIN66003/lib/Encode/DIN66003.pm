package Encode::DIN66003;
use vars qw($VERSION);
$VERSION = "0.04";

use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__,$VERSION);

1;
__END__

=encoding UTF-8

=head1 NAME

Encode::DIN66003 - Encoding according to DIN 66003

=head1 SYNOPSIS

  use Encode::DIN66003;

  # If your terminal is UTF-8
  print decode('DIN66003', 'Hello W|rld!'); # Hello Wörld

  # If your terminal is Windows cp850
  print encode('cp850', decode('DIN66003', 'Hello W|rld!')); # Hello Wörld

=head1 SEE ALSO

L<Encode>

CP1011 (IBM) and CP20106 (Microsoft)

L<https://de.wikipedia.org/wiki/DIN_66003>

L<https://en.wikipedia.org/wiki/Code_page_1011>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Encode-DIN66003>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
