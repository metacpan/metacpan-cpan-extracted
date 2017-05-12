
use strict;
use warnings;

use Test::More tests => 1;
use FindBin;
use lib 't/lib';
use FakeFS;
my $fake;

BEGIN {
  $fake = FakeFS->new( root => "$FindBin::Bin/02_files" );
  $fake->add_file( 'develdir/.devdir'                               => q[] );
  $fake->add_file( 'develdir/share/file'                            => qq[03\n] );
  $fake->add_file( 'installdir/lib/auto/share/dist/Example_02/file' => q[02] );
  $fake->add_file( 'develdir/lib/Example_03.pm'                     => <<'EOF_A');
use strict;
use warnings;

package Example_03;

1;
EOF_A
  $fake->add_file( 'installdir/lib/Example_02.pm' => <<'EOF_B');
use strict;
use warnings;

package Example_02;

use File::ShareDir::ProjectDistDir;

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file( 'Example_02', 'file' ) )->slurp();
}

1;
EOF_B
}
use lib "$FindBin::Bin/02_files/installdir/lib";
use lib "$FindBin::Bin/02_files/develdir/lib";    # simulate testing in a child project.

use Example_02;

is( Example_02->test(), '02', 'Example 02 returns the right shared value' );
