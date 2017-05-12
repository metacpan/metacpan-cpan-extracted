#_ Cube _______________________________________________________________
# Test cube      
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Cube unit=>u;
use Test::Simple tests=>5;

ok(u    eq 'cube(vector(0, 0, 0), vector(1, 0, 0), vector(0, 1, 0), vector(0, 0, 1))');
ok(u->a eq 'vector(0, 0, 0)');
ok(u->x eq 'vector(1, 0, 0)');
ok(u->y eq 'vector(0, 1, 0)');
ok(u->z eq 'vector(0, 0, 1)');

