use strict;
use warnings;

use Test::More;

# ABSTRACT: make sure expand_modname works

use Test::More 0.96;

use Dist::Zilla::Util::EmulatePhase qw( -all );

is( expand_modname('-MetaProvider'), 'Dist::Zilla::Role::MetaProvider', 'Role Expansion works' );
is( expand_modname('=PreReqs'),      'Dist::Zilla::Plugin::PreReqs',    'Plugin Expansion works' );

done_testing;
