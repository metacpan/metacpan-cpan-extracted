#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DesktopWorkspace::Test::Spec::Basic;

my $dw = DesktopWorkspace::Test::Spec::Basic->new;

subtest "items" => sub {
    ok($dw->items);
};

subtest "kde_activity" => sub {
    $dw->kde_activity;
    ok(1);
};

subtest "new_browser_window" => sub {
    $dw->new_browser_window;
    ok(1);
};

done_testing;
