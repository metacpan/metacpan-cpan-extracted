#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DesktopWorkspace::Sample::Source::DefHash;

my $dw = DesktopWorkspace::Sample::Source::DefHash->new();

ok($dw->items);
is($dw->kde_activity, "test");
ok($dw->new_browser_window);

done_testing;
