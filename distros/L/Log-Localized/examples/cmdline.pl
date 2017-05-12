#!/usr/bin/perl
#
# $Id: cmdline.pl,v 1.2 2005/09/20 06:59:41 erwan Exp $
#
# an example of how to use Log::Localized to handle
# logging in a small program that accepts '-v' style
# arguments from the command line.
#
# erwan lemonnier - 200509
#


use strict;
use warnings;
use Getopt::Long;
use lib "../lib/";
# 'log => 1' required since we want to log but neither rules file nor global vebrosity exists
use Log::Localized log => 1;

my $help;

GetOptions("verbose|v+" => sub { $Log::Localized::VERBOSITY++; },
	   "help|h"     => \$help,
	   );

die "run 'cmdline.pl -v' with a various number of '-v' and watch the result\n" if ($help);

print "global verbosity level is ".$Log::Localized::VERBOSITY." (use -h for help)\n";

llog(0,"this is a message of level 0");
llog(1,"this is a message of level 1");
llog(2,"this is a message of level 2");
llog(3,"this is a message of level 3");

# and try with 5 -v to see Log::Localized's own log info :)
