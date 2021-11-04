#!/usr/bin/env perl 

use t::setup;
use_ok my $Class = __TEST_PACKAGE__;

use FindApp::Utils ":package";
require_ok(my $Start = PACKAGE($Class)->left->unbless);

sub base_tests {
    my @supers = PACKAGE($Class)->add_all_unblessed(implements with <Loader Devperl Overloading>);
    for my $super (@supers) {
        ok $Class->isa($super),           "$Class isa $super";
    }
}

sub cannery_tests { 
    ok  $Class->can("new"),               "$Class can new" ;
    ok  $Start->isa($Class),              "$Start isa $Class";
    ok !$Class->isa($Start),              "but $Class ainta $Start";
}

sub debuggery_tests {
    for my $parent ($Start, $Class) { 
        my @extras = qw(debugging tracing);
        for my $extra (@extras) {
            ok $parent->can($extra),      "$parent can $extra";
        }
    }
}

sub forbid_functions_as_methods_tests {
    my @functions = grep {
           ! /^ (?: op | as ) _ /x
        && ! /^ (?: tracing | debugging ) $/x
    } @FindApp::Utils::EXPORT_OK;

    for my $function (@functions) {
        for my $type ($Start, $Class) { 
            ok !$type->can($function),    "$function uninvokable by $type";
        }
    }
}

run_tests();

__END__
