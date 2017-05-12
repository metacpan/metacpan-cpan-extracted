use strict;
use warnings;

use utf8;

use MARC::Charset qw(utf8_to_marc8);
use Encode;

use Test::More tests => 1;

my $viet_utf8 = 'Phép lạ của sự tỉnh thức.';
my $viet_marc8 = utf8_to_marc8($viet_utf8);

is($viet_marc8, "Ph\xe2ep l\xf2a c\xe0ua s\xf2\xbd t\xe0inh th\xe2\xbdc.", 'converted Vietnamese to MARC8');
exit 0;
