
use strict;
use warnings;

use Test::More tests => 1;
use FindBin;
use lib 't/lib';
use FakeFS;

my $fake;

BEGIN {
  $fake = FakeFS->new( root => "$FindBin::Bin/01_files" );
  $fake->add_file( '.devdir'           => q[] );
  $fake->add_file( 'share/file'        => q[01] );
  $fake->add_file( 'lib/Example_01.pm' => <<'EOF' );
use strict;
use warnings;

package Example_01;

use File::ShareDir::ProjectDistDir;

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file( 'Example_01', 'file' ) )->slurp();
}

1;
EOF
}
use lib "$FindBin::Bin/01_files/lib";

use Example_01;

is( Example_01->test(), '01', 'Example 01 returns the right shared value' );
