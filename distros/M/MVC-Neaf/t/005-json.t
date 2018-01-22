#!perl

use strict;
use warnings;
use Test::More tests => 1;

my $view = "MVC::Neaf::View::JS";

my $luck = eval "use $view; 1; "; ## no critic
diag "Failed to load $view: $@"
    unless $luck;

if (!JSON::MaybeXS->VERSION) {
    diag "Installing JSON::MaybeXS is recommended";
};

ok $luck, "Default view ($view) loaded"
    or print "Bail out!";
