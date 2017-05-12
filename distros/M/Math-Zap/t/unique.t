#_ Unique _____________________________________________________________
# Unique           
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Unique;
use Test::Simple tests=>3;
   
ok(unique() ne unique());
ok(unique() ne unique());
ok(unique() ne unique());

