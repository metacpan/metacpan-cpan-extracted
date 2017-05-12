
require 5;
use strict;
use Test;
BEGIN { plan tests => 1; }
eval 'require Getopt::Janus';
die $@ if $@;

print "# Loaded Getopt::Janus version $Getopt::Janus::VERSION\n";
ok 1;

