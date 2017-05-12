#!/usr/bin/env perl
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl HOI-Comprehensions.t'

#########################

use Test::More tests => 5;
use HOI::Comprehensions;
#plan tests => 4;
#BEGIN { use_ok('HOI::Comprehensions') };
ok(1);

#########################

my $list = HOI::Comprehensions::comp( sub { $x + $y + $z + $w }, x => [ 1, 2, 3 ], y => [ 4, 5, 6 ], w => HOI::Comprehensions::comp( sub { $u }, u => [ 1, 2, 3 ] )->(), z => sub { (2, 1) } )->( sub { $x > 1 } );
#diag("eval...");
#diag($list->{geneitr});
my ($elt, $done);
sub {
    do {
        ($elt, $done) = @{<$list>};
        #diag("elt = $elt");
    } while (not $done);
}->();

my $target = [];
for my $i (2..3) {
    for my $j (4..6) {
        for my $k (1..3) {
            push @$target, $i + $j + 2 + $k;
        }
    }
}
is_deeply($target, $list->get_list, "eq");

$done = 0;
my $cnt_done = 0;
sub {
    for (my $idx = 0; $idx < 18; $idx++) {
        ($elt, $done) = @{$idx + $list};
        $cnt_done += $done;
    }
}->();
ok($cnt_done == 18);

ok($list->is_over());

my $deplist = HOI::Comprehensions::comp( sub { $y + $x }, y => sub { $x }, x => [ 1, 2, 3 ] )->();
is_deeply($deplist->force, [ 2, 4, 6 ], "eq_dep");

#done_testing(4);
