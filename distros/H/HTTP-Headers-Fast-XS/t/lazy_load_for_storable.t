use strict;
use warnings;
use HTTP::Headers::Fast;
use Test::More tests => 1;

is $INC{'Storable.pm'}, undef;
