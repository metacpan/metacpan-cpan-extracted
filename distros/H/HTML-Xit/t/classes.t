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
# get classes hashref
$classes = $X->("#para1")->classes();
is_deeply($classes, {'para' => 1}, "get classes hashref");
# add another class
$X->("#para1")->addClass("abc");
# classes array ordered
@classes = $X->("#para1")->classes();
is_deeply(\@classes, ['abc', 'para'], "classes array ordered");

done_testing();
