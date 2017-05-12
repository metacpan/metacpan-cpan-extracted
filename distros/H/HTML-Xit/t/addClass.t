use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('HTML::Xit');
}

my($X);

# get new instance from test file
$X = HTML::Xit->new("t/data/test.html");
# check existing classes
ok($X->("#para1")->hasClass("para"), "has class para");
ok(!$X->("#para1")->hasClass("xyz"), "no class xyz");
# add class
$X->("#para1")->addClass("xyz");
# confirm add
ok($X->("#para1")->hasClass("xyz"), "add class xyz");
ok($X->("#para1")->hasClass("para"), "still has class para");
# add multiple classes
$X->("#para1")->addClass("abc def");
# confirm add
ok($X->("#para1")->hasClass("abc"), "add class abc");
ok($X->("#para1")->hasClass("def"), "add class def");

done_testing();
