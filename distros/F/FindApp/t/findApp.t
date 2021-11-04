#!/usr/bin/env perl 

use t::setup;
use FindApp::Utils ":package";

require_ok(my $Class = __TEST_PACKAGE__);

sub super_tests {
    my @supers = PACKAGE($Class)->add_all_unblessed(Object => with "Exporter");
    for my $super (@supers) {
        ok $Class->isa($super),      "$Class isa $super";
    }
}

sub debuggery_tests {
    my @extras = qw(debugging tracing);
    for my $extra (@extras) {
        ok $Class->can($extra),      "$Class can $extra";
    }
}

sub cleanliness_tests {
    my @functions = grep {
           ! /^ (?: op | as ) _ /x
        && ! /^ (?: tracing | debugging ) $/x
    } @FindApp::Utils::EXPORT_OK;

    for my $function (@functions) {
        ok !$Class->can($function),    "$function uninvokable by $Class";
    }

}

run_tests();
