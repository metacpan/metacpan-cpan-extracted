use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('HTML::Xit');
}

my($elm, $X);

# get new instance from test file
$X = HTML::Xit->new("t/data/test.html");
# prepend element
$X->("#body")->prepend( $X->("<a>")->attr("href", "/test")->text("test") );
is($X->("#body")->children()->first()->html(), "test", "prepend element");

done_testing();
