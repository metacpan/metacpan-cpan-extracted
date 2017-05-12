use Test::More qw(no_plan);
use strict;
use warnings;

use MARC::Charset qw(marc8_to_utf8 utf8_to_marc8);
is('foobar', marc8_to_utf8('foobar'), 'no escapes');

my $text = 'All about whales.';
my $utf8 = marc8_to_utf8($text);
is($text, $utf8, 'punctuation marc8_to_utf8');

my $marc8 = utf8_to_marc8($utf8);
is($text, $marc8, 'punctuation utf8_to_marc8');
