#!perl

use Test::More tests => 7;

use strict;
use warnings;
use Test::Exception;

use JSPL;

my $rt = JSPL::Runtime->new();
my $cx = $rt->create_context();

my $v = $cx->get_version();
is($v, 'default', "Default version");

my $src = q/
var x = 5;
var y = 0;

let (x = x + 10, y = 12) {
    v = x + y;
};
/;

throws_ok { $cx->eval($src) } qr/missing ;/;

is($cx->set_version("1.7"), $v, "Version set");
is($cx->get_version(), "1.7", "Really set");
lives_ok { $cx->eval($src) } "Now without errors";

is($cx->set_version("1.5"), "1.7", "Version set");
is($cx->get_version(), "1.5", "Really set");
