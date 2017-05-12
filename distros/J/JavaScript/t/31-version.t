#!perl

use Test::More tests => 4;

use strict;
use warnings;

use JavaScript;

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

my $v = $cx->get_version();

my $src = q/
var x = 5;
var y = 0;

let (x = x + 10, y = 12) {
    v = x + y;
};
/;

$cx->eval($src);
ok($@);

$cx->set_version("1.7");
$v = $cx->get_version();
is($v, "1.7");
$cx->eval($src);
ok(!$@);

$cx->set_version("1.5");
$v = $cx->get_version();
is($v, "1.5");
