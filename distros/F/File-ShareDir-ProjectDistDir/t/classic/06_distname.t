
use strict;
use warnings;

use Test::More tests => 2;
use FindBin;
use lib 't/lib';
use FakeFS;
my $fake;

BEGIN {
  $fake = FakeFS->new( root => "$FindBin::Bin/06_files" );
  $fake->add_file( 'develdir/.devdir'                               => q[] );
  $fake->add_file( 'develdir/share/file'                            => q[05] );
  $fake->add_file( 'installdir/lib/auto/share/dist/Example_04/file' => q[04] );
  $fake->add_file( 'develdir/lib/Example_05.pm'                     => <<'EOF_A');
use strict;
use warnings;

package Example_05;

use File::ShareDir::ProjectDistDir qw( :all ), distname => 'Example_05';

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file('file') )->slurp();
}

1;
EOF_A
  $fake->add_file( 'installdir/lib/Example_04.pm' => <<'EOF_B');
use strict;
use warnings;

package Example_04;

use File::ShareDir::ProjectDistDir qw( :all ), distname => "Example_04";

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file('file') )->slurp();
}

1;
EOF_B

}
use lib "$FindBin::Bin/06_files/installdir/lib";
use lib "$FindBin::Bin/06_files/develdir/lib";    # simulate testing in a child project.

use Example_04;
use Example_05;

is( Example_04->test(), '04', 'Example 04 returns the right shared value' );
is( Example_05->test(), '05', 'Example 05 returns the right shared value' );
