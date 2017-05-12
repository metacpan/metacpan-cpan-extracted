
use strict;
use warnings;

use Test::More tests => 1;
use FindBin;
use lib 't/lib';
use FakeFS;

my $fake;

BEGIN {
  $fake = FakeFS->new( root => "$FindBin::Bin/04_files" );
  $fake->add_file( 'develdir/.devdir'                               => q[] );
  $fake->add_file( 'develdir/share/dist/Example_06/file'            => q[06] );
  $fake->add_file( 'installdir/lib/auto/share/dist/Example_06/file' => q[06-old] );
  $fake->add_file( 'develdir/lib/Example_06.pm'                     => <<'EOF_A' );
use strict;
use warnings;

package Example_06;

use File::ShareDir::ProjectDistDir ':all', strict => 1;

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file( 'Example_06', 'file' ) )->slurp();
}

1;
EOF_A
  $fake->add_file( 'installdir/lib/Example_06.pm' => <<'EOF_B' );
use strict;
use warnings;

package Example_06;

use File::ShareDir::ProjectDistDir ':all', strict => 1;

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file( 'Example_06', 'file' ) )->slurp();
}

1;
EOF_B

}
use lib "$FindBin::Bin/04_files/installdir/lib";
use lib "$FindBin::Bin/04_files/develdir/lib";    # simulate testing in a child project.

use Example_06;

is( Example_06->test(), '06', 'Example 06 returns the right shared value' );
