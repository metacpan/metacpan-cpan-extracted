use strict;
use warnings;

package My::Project;

use My::Project::Logger;

sub import {
  log_trace { 'import called' };
}

sub run {
  log_trace { 'running' };
  require My::Project::Library;
  My::Project::Library->run;
}

1;
