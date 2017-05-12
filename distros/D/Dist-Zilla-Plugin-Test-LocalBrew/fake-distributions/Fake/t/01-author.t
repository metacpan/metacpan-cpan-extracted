use strict;
use warnings;

use Test::More;

if(exists $ENV{'AUTHOR_TESTING'}) {
    plan tests => 1;
    fail "some author tests fail! =(";
} else {
    plan skip_all => 'I shouldn\'t be running author tests!';
}
