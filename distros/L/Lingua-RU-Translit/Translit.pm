package Lingua::RU::Translit;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(translit2koi);
$VERSION = '0.02';

bootstrap Lingua::RU::Translit $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Lingua::RU::Translit - Perl extension for decoding cyrillic translit/volapyuk

=head1 SYNOPSIS

  use Lingua::RU::Translit qw(translit2koi)
  $rus=translit2koi($translit)

=head1 DESCRIPTION

Converts transliterated cyrillic text to koi8-r.
Leaves non-translit text as is.

=head1 AUTHOR

Sergei Golubchik, sergii@pisem.net

=head1 SEE ALSO

perl(1), Lingua::Ru::Charset(3)

=cut
