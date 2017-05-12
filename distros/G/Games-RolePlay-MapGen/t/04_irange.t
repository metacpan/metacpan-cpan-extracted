
use strict;
use Test;

plan tests => 10;

use Games::RolePlay::MapGen::Tools "irange";

my $epoch = 100000;

my %h = ();

   $h{ irange(0, 9) } ++ for 1 .. $epoch;

for my $v (sort {$a<=>$b} keys %h) {
    ok( sprintf('%d-%0.2f', $v, $h{$v}/$epoch), qr{(?:$v\-0.10|$v\-0.11)} );
}
