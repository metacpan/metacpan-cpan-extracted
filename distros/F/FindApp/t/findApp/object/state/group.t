#!/usr/bin/env perl

use t::setup;

use FindApp::Utils ":package";

use_ok my $Class = __TEST_PACKAGE__;

sub super_tests {
    for my $super (PACKAGE($Class)->add_all_unblessed(implements with "Overloading")) {
        ok $Class->isa($super),                         "$Class isa $super";
    }
}

sub cannery_tests { 
    my $Start = PACKAGE($Class)->left->unbless;
    require_ok($Start);
    ok $Class->can("new"),                              "$Class can new" ;
    ok !$Start->isa($Class),                            "$Start ainta $Class";
    ok !$Class->isa($Start),                            "$Class ainta $Start neither";
}

run_tests();
