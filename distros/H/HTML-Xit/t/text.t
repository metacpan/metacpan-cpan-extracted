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

# get text by id
like($X->("#para1")->text, qr{^\s*Lorem ipsum}, "get text by id");
# get text by class
like($X->(".para")->text, qr{^\s*Lorem ipsum}, "get text by class");
# set text
$X->(".para")->text("<b>TEST");
$X->(".para")->each(sub{
    my $elm = shift;
    is($elm->text, "<b>TEST", "set text");
});

done_testing();
