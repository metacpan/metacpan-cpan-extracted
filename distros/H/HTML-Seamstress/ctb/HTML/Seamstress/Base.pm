package HTML::Seamstress::Base;

# derive from HTML::Seamstress
use base qw(HTML::Seamstress);

# create sub comp_root:
# put a "/" on end of path - VERY important

use vars qw($comp_root);

BEGIN {
  $comp_root = '/home/metaperl/perl/src/seamstress/ctb/';
}
#BEGIN { 
 # $__PACKAGE__::comp_root = '/home/metaperl/perl/src/seamstress/ctb/'

#}

use lib $comp_root;

sub comp_root { $comp_root }

1;
