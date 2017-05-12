#!/usr/bin/env perl
# Test the fake exceptions

use Test::More tests => 3;

use Log::Report::Minimal;

eval "error 'help!'";
is($@, "error: help!\n", $@);

{   my $w;
    eval { local $SIG{__WARN__} = sub {$w = join ';', @_};
           warning 'auch!' };
    is($@, '', $@);  # no die
    is($w, "warning: auch!\n");
}
