use warnings;
use strict;

use JavaScript::V8;
use Test::More tests => 1;

my $c = JavaScript::V8::Context->new;
$c->name_global('window');

is $c->eval('x = 4; window.x'), 4;
