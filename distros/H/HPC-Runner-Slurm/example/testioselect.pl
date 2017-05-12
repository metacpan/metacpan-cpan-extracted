#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  testioselect.pl
#
#        USAGE:  ./testioselect.pl  
#
#  DESCRIPTION:  This script is 100% from this discussion http://www.perlmonks.org/?node_id=151886
#
#       AUTHOR:  abstracts from perlmonks
#      VERSION:  1.0
#      CREATED:  12/12/2013 02:42:13 PM
#     REVISION:  ---
#===============================================================================

# This script was taken into service from the thread http://www.perlmonks.org/?node_id=151886 discussing the proper use of IPC::Open3 on perlmonks.
# this script printf to stdout and stderr.  It prints random
# characters and does not flush the output of stdout. stderr 
# is autoflushed by default.
# uncomment the line about autoflush STDOUT to see how that
# changes the behavior.  Also, you can uncomment the sleep 
# line to watch the script in slow motion.

use warnings;
use strict;
use IO::Handle;

#autoflush STDOUT 1;
print "#####################################\n";
print "\nARG is ".$ARGV[0]."\n";
print "#####################################\n";

for (1..10){
    if($_ == 1){
        sleep 5;
    }
    my $str = '';
    for(1..10){
        $str .= ('A'..'Z','a'..'z',0..9)[rand 62];
    }
    if(int rand 2){ # 50:50 chance
        print STDOUT "StdOut:$str\n";
    } else {
        print STDERR "StdErr:$str\n";
    }
    sleep 1;
}

sleep(100);

print "\n#####################################\n";

