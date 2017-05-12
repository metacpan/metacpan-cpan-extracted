#!/usr/bin/perl
#
# $Id: funcref_advanced.pl,v 1.1 2005/09/20 06:58:07 erwan Exp $
#
# an example of how to alter the log message format
# depending on message levels.
# this might be of use when replacing pre-existing
# logging modules with Log::Localized in a transparent
# way.
#
# erwan lemonnier - 200509
#

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use lib "../lib/";
# rules => imply that logging is on, so no need to 'log => 1'
use Log::Localized rules => 'Log::Localized::format = %MSG';

#----------------------------------------------------
#
#   format - here lays the magic. format alters the log
#            message depending on its level. in a large
#            project, you would isolate format() in a
#            module of its own...
#

sub format {
    my $message = shift;
    my $level = $Log::Localized::LEVEL;

    if ($level == 0) {
	return "=> $message";
    } elsif ($level == 1) {
	return "   -> $message";
    } else {
	return "      * $message";
    }
}

#----------------------------------------------------
#
#    main
#

my $help;

GetOptions("verbose|v+" => sub { $Log::Localized::VERBOSITY++; },
	   "help|h"     => \$help,
	   );

die "run 'funcref_advanced.pl -v' with a various number of '-v' and watch the result\n" if ($help);

print "global verbosity level is ".$Log::Localized::VERBOSITY." (use -h for help)\n";

# look at that
llog(0, sub { &format("this message has level 0") });
llog(1, sub { &format("this message has level 1") });
llog(2, sub { &format("this message has level 2") });
llog(3, sub { &format("this message has level 3") });


