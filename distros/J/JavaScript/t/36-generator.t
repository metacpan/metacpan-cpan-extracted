#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use JavaScript;

my (undef, $version) = JavaScript->get_engine_version(); 

if ($version lt "1.7.0") {
    plan skip_all => "No generator support in SM";
}
else {
    plan tests => 10;
}

my $rt = JavaScript::Runtime->new;
my $cx = $rt->create_context;
$cx->set_version("1.7");
my $f = $cx->eval(q!
function fib() {
  var i = 0, j = 1;
  while (true) {
    yield i;
    var t = i;
    i = j;
    j += t;
  }
}
var y = fib();
y;
!);

for my $v (qw(0 1 1 2 3 5 8 13 21 34)) {
    is($f->next, $v);
}
