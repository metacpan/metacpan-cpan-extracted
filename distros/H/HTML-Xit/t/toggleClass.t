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
# toggle existing class
$X->("#para1")->toggleClass("para");
# confirm remove
ok(!$X->("#para1")->hasClass("para"), "toggle removed class para");
# toggle non-existing class
$X->("#para1")->toggleClass("xyz");
# confirm add
ok($X->("#para1")->hasClass("xyz"), "toggle added class xyz");
# toggle multiple classes
$X->("#para1")->toggleClass("para xyz");
# confirm toggle
ok($X->("#para1")->hasClass("para"), "has class para");
ok(!$X->("#para1")->hasClass("xyz"), "no class xyz");

done_testing();
