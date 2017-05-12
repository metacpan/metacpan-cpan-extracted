# vim: filetype=perl :

use strict;
use Test::More tests => 4097;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN { use_ok('MMS::Parser'); }

my $parser = MMS::Parser->create();
my %char_tests = (
   OCTET         => [0 .. 255],
   CHAR          => [0 .. 127],
   UPALPHA       => [numerify_range('A' .. 'Z')],
   LOALPHA       => [numerify_range('a' .. 'z')],
   ALPHA         => [numerify_range('a' .. 'z', 'A' .. 'Z')],
   DIGIT         => [numerify_range('0' .. '9')],
   CTL           => [0 .. 31, 127],
   CR            => [numerify_range("\x0D")],
   LF            => [numerify_range("\x0A")],
   SP            => [numerify_range("\x20")],
   HT            => [numerify_range("\x09")],
   RFC2616_QUOTE => [numerify_range("\x22")],
   HEX           => [numerify_range('A' .. 'F', 'a' .. 'f', '0' .. '9')],
   separator     => [
      numerify_range(
         qw# ( ) < > @ ; : \ " / [ ] ? = { }  #,
         q{ }, ',', "\t"
      )
   ],
   HIGHOCTET => [128 .. 255],
   _non_CTL  => [32 .. 126, 128 .. 256],
);

while (my ($subname, $spc) = each %char_tests) {
   char_range($parser, $subname, @$spc);
}
