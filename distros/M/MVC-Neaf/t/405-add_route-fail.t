#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;

my $n = MVC::Neaf->new;

throws_ok {
    $n->add_route( "/" );
} qr([Oo]dd number of), "Odd args = no go";

throws_ok {
    $n->add_route( "/", "foobar" );
} qr(handler.*code), 'Code must be code';

throws_ok {
    $n->add_route( "/", [] );
} qr(handler.*code.*not ARRAY), 'Code must be code';

throws_ok {
    $n->add_route( foo => sub { }, default => [] );
} qr(default.*hash), "Defaults must be hash";

throws_ok {
    $n->add_route( foo => sub { }, foobar => 42 );
} qr([Uu]nexpected.*foobar), "Unknown keys = no go";

throws_ok {
    $n->add_route( foo => sub { }, param_regex => qr(missed_me) );
} qr(param_regex), "Param regex must be hash";

done_testing;
