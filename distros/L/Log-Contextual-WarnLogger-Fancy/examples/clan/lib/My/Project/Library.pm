use strict;
use warnings;

package My::Project::Library;

use My::Project::Logger;

sub run {
  log_warn { "Running library " };
}

1;
