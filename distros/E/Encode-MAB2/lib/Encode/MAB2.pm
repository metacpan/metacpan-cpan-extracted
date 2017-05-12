package Encode::MAB2;

use strict;
our $VERSION = "0.09"; # must stay in sync with Encode::MAB2table

use Encode ();
use Encode::MAB2table;
use Unicode::Normalize qw(NFC);

use base qw(Encode::Encoding);
__PACKAGE__->Define('MAB2', 'mab2');

sub needs_lines {1}

our $combinings = qr/[\xc0-\xdb\xdd-\xdf]/;
sub decode {
    my($obj, $str, $chk) = @_;
    return unless defined $str;
    $str =~ s{\xcd\xc9}{\xcd}g; # Fehler bei Heged"us, Erd"os und Mez"o
    $str =~ s{($combinings+)(.)}{($2 eq "\xf5" ? "i" : $2) . $1}ge; #};
    if ($chk) {
      if ($str =~ s/($combinings+)\z//) {
        $_[1] = $1; # we have 'sub needs_lines {1}', so this should
                    # never happen
      } else {
        $_[1] = '';
      }
    }
    NFC(Encode::decode("MAB2table",$str));
}

1;
__END__


=head1 NAME

Encode::MAB2 - Das C<Maschinelle Austauschformat fuer Bibliotheken>

=head1 STATUS

This module and all the accompanying modules are to be regarded as
ALPHA quality software. That means all interfaces, namespaces,
functions, etc. are still subject to change.

=head1 SYNOPSIS

  use Encode::MAB2;
  my $mab2 = 'Some string in MAB2 encoding';
  my $unicode = Encode::decode('MAB2',$mab2);

=head1 DESCRIPTION

The Encode::MAB2 module works on the string level abstraction of MAB2
records. You can feed it a string in the encoding used by MAB2 and get
a Unicode string back. The module only works in one direction, it does
not provide a way to convert a Unicode string back into MAB2 encoding.

=head1 Background

MAB2 is a German library data format and an encoding almost completely
based on ASCII and ISO 5426:1983. On 2003-09-08 Die Deutsche
Bibliothek published
L<http://www.ddb.de/professionell/pdf/mab_unic.pdf>, the first
official document that maps the MAB2 encoding to Unicode 4.0. The
mapping provided by this module follows this publication. See below
for small additional convenience tricks that are also implemented by
the module to avert common errors.

                     ALERT: USE AT YOUR OWN RISK

                   You are responsible to determine
                applicability of information provided.

=head1 Links

Besides the above mentioned mab_unic.pdf, the following documents
provided invaluable help in developing the mapping presented in this
module:

=over

=item *

Thomas Berger in his L<http://www.gymel.com/charsets/MAB2.html>

=item *

ISO/TC46/SC4/WG1 in their L<http://www.niso.org/international/SC4/Wg1_240.pdf>

=item *

Wayne Schneider in L<http://crl.nmsu.edu/~mleisher/csets/ISO053.TXT>

=item *

Thanks also go to Reinhold Heuvelmann of I<Die Deutsche Bibliothek> who
sent me an early draft of mab_unic.pdf.

=back

=head1 Normalization

This module uses the module Unicode::Normalize to deliver the
combining characters in the MAB2 record in normalization form C. We
have taken precautions against common errors in MAB records:

=over 4

=item *

If
the dotless i (LATIN SMALL LETTER DOTLESS I) is victim of a
composition process, it is treated like an i (LATIN SMALL LETTER I)
before composition takes place.

=item *

If a composed letter is combined with both a diaeresis and a double
acute, we ignore the diaeresis and pretend there was only a double
acute.

=back

=head1 Other modules in this package

This module comes with 6 modules that alleviate the parsing of MAB
records. The modules are the following:

 MAB2::Record::Base
 MAB2::Record::gkd
 MAB2::Record::lokal
 MAB2::Record::pnd
 MAB2::Record::swd
 MAB2::Record::titel

where Base is based on the file C<segm000.txt> and each of the others
is based on the according textfile in the C<ftp://ftp.ddb.de/pub/mab/>
directory on the server of I<Die Deutsche Bibliothek>. More
documentation can be found in C<MAB2::Record::Base>.

In addition to that, there are two C<tie> interfaces available:
C<Tie::MAB2::Recno> and C<Tie::MAB2::Id>. These are the high-level
access classes for MAB2 files that use all other modules presented in
the package.

=head1 SEE ALSO

L<Encode>

=cut
