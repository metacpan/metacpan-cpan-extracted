#!/usr/bin/env perl

use t::setup;

require_ok(my $MODULE = __TEST_PACKAGE__);

sub import_tests {
    my @tags = map ":$_", qw(vars subs all);
    for my $tag (@tags) { 
        ok(eval { $MODULE->import("$tag"); 1 }, "use $MODULE qw($tag);")
            || diag "couldn't import $tag from $MODULE";
    }   
}

run_tests();

__END__
