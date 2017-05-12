use strict;
use warnings;

use Test::More;

if(exists $ENV{'RELEASE_TESTING'}) {
    plan tests => 1;
    fail "some release tests fail! =(";
} else {
    plan skip_all => 'I shouldn\'t be running release tests!';
}
