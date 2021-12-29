use Modern::Perl;
use Test::More qw(no_plan);

our $pkg='Devel::Agent::EveryThing';
use_ok($pkg);
require_ok($pkg);
