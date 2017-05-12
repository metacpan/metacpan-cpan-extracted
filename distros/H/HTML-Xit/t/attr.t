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
# get attribute by id
is($X->("#image1")->attr("src"), "/image1", "get attribute by id");
# get attribute by class
is($X->(".image")->attr("src"), "/image1", "get attribute by class");
# set attribute by id
$X->("#image1")->attr("src", "/image1.new");
is($X->("#image1")->attr("src"), "/image1.new", "set attribute by id");
# set attribute by class
$X->(".image")->attr("width", "250");
$X->(".image")->each(sub {
    my $elm = shift;
    is($elm->attr("width"), 250, "set attribute by class");
});

done_testing();
