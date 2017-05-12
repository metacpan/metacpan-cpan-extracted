#!/usr/bin/perl
sub demo {
    $a = $_[0];
    $b = 3;
    $c = 2 * $a + 7 * $b;
    @d = ($a, $b, $c + $b);
    return @d;
}
use threads;
my @threads = map { threads->create( \&demo, $_ ) } 5, -1;
$_->join for @threads;
exit 0;
