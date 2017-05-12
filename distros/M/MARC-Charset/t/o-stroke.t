use strict;
use warnings;

use MARC::Charset qw/marc8_to_utf8/;
use Test::More tests => 2;

use utf8;

my $marc8_ostroke = "\xB2";
my $utf8_ostroke  = marc8_to_utf8($marc8_ostroke);

ok(utf8::is_utf8($utf8_ostroke), 'UTF8 flag set after converting LATIN SMALL LETTER O WITH STROKE to UTF8');
is($utf8_ostroke, 'ø', 'successful conversion of LATIN SMALL LETTER O WITH STROKE');
