#!/usr/bin/perl
#
# $Id: funcref.pl,v 1.1 2005/09/20 06:58:06 erwan Exp $
#
# an example of how to use closures (anonymous subs) to 
# execute some code generating a message to log, and to
# show that this closure is executed only when its result
# would really be logged.
#
# erwan lemonnier - 200509
#

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use lib "../lib/";
# 'log => 1' required since we want to log but neither rules file nor global vebrosity exists
use Log::Localized log => 1;

my $help;

GetOptions("verbose|v+" => sub { $Log::Localized::VERBOSITY++; },
	   "help|h"     => \$help,
	   );

die "run 'funcref.pl -v' with a various number of '-v' and watch the result\n" if ($help);

print "global verbosity level is ".$Log::Localized::VERBOSITY." (use -h for help)\n";

# look at that
llog(1,sub { "a rather dumb function..."; });

no strict 'refs'; # required by %{"main::"}

# and at that
llog(2,sub { "dumping the stash!!".
	     Dumper(%{"main::"}).
	     "\nNow, THIS Dumper is something you don't want to execute when you don't really want to see it..."; 
	 });
