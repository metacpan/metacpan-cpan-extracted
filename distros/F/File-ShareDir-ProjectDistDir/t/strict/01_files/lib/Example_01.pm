use strict;
use warnings;

package Example_01;

use File::ShareDir::ProjectDistDir ':all', strict => 1;

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file( 'Example_01', 'file' ) )->slurp();
}

1;
