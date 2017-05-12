
use strict;
use warnings;

package Test::Covered;


use Test::More;

use Path::Class;
use File::Path;



my $test_dir = dir(qw/ t data cover_db /);
my $covered_dir = dir($test_dir->parent, "covered");

rmtree([ $test_dir, $covered_dir ]);
ok( ! -d $test_dir, "  no cover_db");
ok( ! -d $covered_dir, "  no covered");
mkpath([ $test_dir, $covered_dir ]);
ok( -d $test_dir, "  created cover_db");
ok( -d $covered_dir, "  created covered_db");

END {
    rmtree([ $test_dir, $covered_dir ]);
    ok( ! -d $test_dir, "  Cleaned up ($test_dir)");
    ok( ! -d $covered_dir, "  Cleaned up ($covered_dir)");
}



1;



__END__
