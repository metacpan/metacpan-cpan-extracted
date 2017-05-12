use strict;
use warnings;

package Example_05;

use File::ShareDir::ProjectDistDir ':all', projectdir => 'templates';

use Path::Tiny qw(path);

sub test {
  return scalar path( dist_file( 'Example_05', 'file' ) )->slurp();
}

1;
