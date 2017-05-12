use Test::More 'no_plan';
use strict;

BEGIN { chdir 't' if -d 't'; }
BEGIN { use File::Spec; require lib;
        lib->import( File::Spec->catdir(qw[.. lib]), 'inc' );
}        

my $Class   = 'File::Alter';

use_ok( $Class );

diag "Testing $Class " . $Class->VERSION;
