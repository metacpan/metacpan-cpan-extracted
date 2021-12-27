use Modern::Perl;
use Test::More qw(no_plan);

our $pkg='Devel::Agent::AwareRole';
use_ok($pkg);
require_ok($pkg);

{
  package 
    SmokeTest;
  
  use Role::Tiny::With;

  with 'Devel::Agent::AwareRole';
}
can_ok('SmokeTest','___db_stack_filter');
