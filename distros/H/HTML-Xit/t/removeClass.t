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
# remove class
$X->("#para1")->removeClass("para");
# confirm remove
ok(!$X->("#para1")->hasClass("para"), "removed class para");
# add some more classes
$X->("#para1")->addClass("abc def");
# confirm add
ok($X->("#para1")->hasClass("abc"), "add class abc");
ok($X->("#para1")->hasClass("def"), "add class def");
# remove multiple classes
$X->("#para1")->removeClass("abc def");
# confirm remove
ok(!$X->("#para1")->hasClass("abc"), "remove class abc");
ok(!$X->("#para1")->hasClass("def"), "remove class def");

done_testing();
