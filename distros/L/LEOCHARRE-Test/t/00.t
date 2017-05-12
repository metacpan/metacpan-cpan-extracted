use lib './lib';
use LEOCHARRE::Test 'no_plan';


ok( stderr_spacer(), 'stderr_spacer');

ok(1,"started 00.t");

ok_part('interactivity');

if( test_is_interactive() ){ 
   ok 1,"test is interactive" 
}
else { 
   ok 1, "skipping ok_mysqld() test etc, non interactive." 
}


