use strict;
use warnings;

use Test::More tests => 1;

use blib;

my @subs = ();

BEGIN { use_ok( 'Dist::Zilla::PluginBundle::WCS', @subs ) || BAIL_OUT($@); }

diag("Testing Dist-Zilla-PluginBundle-WCS $Dist::Zilla::PluginBundle::WCS::VERSION, Perl $], $^X");
