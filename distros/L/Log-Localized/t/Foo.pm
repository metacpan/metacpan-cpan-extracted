#-------------------------------------------------------
#
#   $Id: Foo.pm,v 1.1 2005/09/18 19:11:02 erwan Exp $
#
#   Foo - Just 1 function, to verify namespace matching
#
#   20050912 erwan Created 
#

package Foo; 

use strict;
use warnings;
use Utils;
use lib "../lib/";
use Log::Localized;

sub test1 {
    my $level = shift;
    llog($level,\&Utils::mark_log_called);
}

sub test2 {
    my $level = shift;
    llog($level,\&Utils::mark_log_called);
}

1;
