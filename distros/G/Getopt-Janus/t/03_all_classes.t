
require 5;
use strict;
use Test;
BEGIN { plan tests => 1; }
require Getopt::Janus;
require Getopt::Janus::CLI;
require Getopt::Janus::Tk;
require Getopt::Janus::SessionBase;
require Getopt::Janus::Licenses;
require Getopt::Janus::Facade;

print "# Loaded Getopt::Janus version $Getopt::Janus::VERSION\n";
ok 1;

