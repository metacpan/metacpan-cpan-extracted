use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('HTML::Xit');
}

my(@classes, $classes, $X);

# get new instance from test file
$X = HTML::Xit->new("t/data/test.html");
# get classes array
@classes = $X->("#para1")->classes();
is_deeply(\@classes, ['para'], "get classes array");
# add another class
$X->("#para1")->addClass("abc");
# classes array ordered
@classes = $X->("#para1")->classes();

for my $class (@classes) {
    ok($X->("#para1")->hasClass($class), "has class $class");
}

ok(!$X->("#para1")->hasClass("xyz"), "no class xyz");

done_testing();
