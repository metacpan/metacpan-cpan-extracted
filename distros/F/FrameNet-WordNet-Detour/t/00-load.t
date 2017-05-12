#!perl -w 

use Test::More tests => 2;
use File::Spec;

 SKIP: {
     skip "\$WNHOME not set", 1 unless exists($ENV{'WNHOME'});
     ok(-e $ENV{'WNHOME'}, "Testing if \$WNHOME exists");
}
 SKIP: {
     skip "\$FNHOME not set", 1 unless (exists($ENV{'FNHOME'}) && exists($ENV{'WNHOME'}));
     ok(-e $ENV{'FNHOME'}, "Testing if \$FNHOME exists");
}





