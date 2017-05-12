package html::Seamstress::Base;

# derive from HTML::Seamstress
use base qw(HTML::Seamstress);

# create sub comp_root:
# put a "/" on end of path - VERY important

use Cwd;

use vars qw($comp_root);

BEGIN {
  $comp_root = getcwd . '/t/' ;
}

use lib $comp_root;

sub comp_root { $comp_root }

1;
