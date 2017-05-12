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
# get html by id
like($X->("#para1")->html, qr{^\s*<em>}, "get html by id");
# get html by class
like($X->(".para")->html, qr{^\s*<em>}, "get html by class");
# set html
$X->("#para1")->html("<span>1</span>", "<span>2</span>");
is($X->("#para1")->html, "<span>1</span><span>2</span>", "set html");
# set HTML::Xit as HTML
$X->(".para")->html( $X->("<a>")->attr("href", "/test")->text("test") );
$X->(".para")->each(sub {
    my $elm = shift;
    is($elm->html, '<a href="/test">test</a>', "set HTML::Xit as HTML");
});
# get html only text
is($X->("title")->html, "Lorem ipsum dolor sit amet", "get html only text");

done_testing();
