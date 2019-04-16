use strict;
use warnings;
use Test::More;
BEGIN {
    if ($INC{"Storable.pm"}) {
        plan skip_all => "Storable is already loaded by toolchain";
    }
}
use HTTP::Headers::Fast;

plan tests => 1;

is $INC{'Storable.pm'}, undef;
