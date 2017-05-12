package GoogleApps::TestClass;
use Test::Class::Most; # we now inherit from Test::Class
use Test::More 'no_plan'; # REMOVE THE 'no_plan'
use Test::MockObject;
 
INIT { Test::Class->runtests }
 
1;
