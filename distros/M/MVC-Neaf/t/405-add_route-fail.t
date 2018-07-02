#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my $n = MVC::Neaf->new;

eval {
    $n->add_route( "/" );
};
like $@, qr#[Oo]dd number of#, "Odd args = no go";

eval {
    $n->add_route( foo => sub { }, default => [] );
};
like $@, qr#default.*hash#, "Defaults must be hash";

eval {
    $n->add_route( foo => sub { }, foobar => 42 );
};
like $@, qr#[Uu]nexpected.*foobar#, "Unknown keys = no go";

eval {
    $n->add_route( foo => sub { }, param_regex => qr#missed_me# );
};
like $@, qr#param_regex#, "Param regex must be hash";

done_testing;
