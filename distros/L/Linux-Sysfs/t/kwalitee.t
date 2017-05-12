#!perl

use strict;
use warnings;
use Test::More;

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [qw( -has_meta_yml )] );
};

plan skip_all => 'Needs Test::Kwalitee' if $@;
