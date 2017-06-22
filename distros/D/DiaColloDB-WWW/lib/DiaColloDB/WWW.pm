## -*- Mode: CPerl -*-
## File: DiaColloDB/WWW.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, www wrappers

package DiaColloDB::WWW;
require 5.10.0; ##-- for // operator

use DiaColloDB;
use DiaColloDB::WWW::CGI;
use DiaColloDB::WWW::Server;
use strict;

##==============================================================================
## Globals & Constants
our $VERSION = "0.02.002";
our @ISA = qw(DiaColloDB::Logger);


##==============================================================================
## Footer
1;

__END__
