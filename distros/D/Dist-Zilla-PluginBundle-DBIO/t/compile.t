use strict;
use warnings;
use Test::More;

use_ok('Dist::Zilla::PluginBundle::DBIO');
use_ok('Dist::Zilla::Plugin::DBIO::CoverageGate');
use_ok('Pod::Weaver::PluginBundle::DBIO');

done_testing;
