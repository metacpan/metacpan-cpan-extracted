use strict;
use Test::More tests => 2;

use Encode;
use Encode::JavaScript::UCS;

my $name = "\x{5BAE}\x{5DDD}\x{9054}\x{5F66}";
my $escaped = encode("JavaScript-UCS", $name);

is $escaped, "\\u5bae\\u5ddd\\u9054\\u5f66";
is decode("JavaScript-UCS", $escaped), $name;



