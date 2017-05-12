
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'File::Fu';
eval("require $package");
my $err = $@;
ok(! $err, 'load ok');
if($err) {
  warn $err, "\n";
  BAIL_OUT("cannot load $package STOP!");
}

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
