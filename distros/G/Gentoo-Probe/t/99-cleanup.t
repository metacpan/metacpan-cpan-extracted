#!/usr/bin/perl

system("rm -fr tmp") unless $ENV{NO_CLEANUP};
die if $?;
print "1..1\nok\n";
