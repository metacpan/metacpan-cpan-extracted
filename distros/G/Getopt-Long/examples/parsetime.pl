#!/usr/bin/perl

# This is a (working) example of how to write a helper routine for
# Getopt::Long to deal with specific cases.
#
# The basic principle is:
#   - specify the option type to be string
#   - specify a code reference to handle the parsing an assignment.
#
# This example parses time specifications in the form HH:MM:SS.mmm, where
# unneeded parts may be left out.

use strict;
use warnings;
use Getopt::Long;

# The helper routine. It will be called to handle the actual delivery
# of the option value.
# There are two parameters: the option name, and the value to be
# assigned.
# Note the use of 'die' to signal errors back to Getopt::Long.

sub parsetime {
    my ($opt_name, $opt_value) = @_;
    my $val = 0;
    unless ( $opt_value =~ /
	^		# beginning of value string
	(?:(\d+):)?	# hours
	(?:(\d+):)?	# minutes
	(\d+(?:\.\d+)?)	# seconds + fraction
	$		# end of value string
	/x ) {
	die("Value \"$opt_value\" invalid for option $opt_name\n");
    }

    # Return the value.
    ( defined $1 ? 3600*$1 : 0) +
    ( defined $2 ?   60*$2 : 0) +
    $3;
}

@ARGV = ("-time", "1:24.14") unless @ARGV;

my $time;
GetOptions("time=s" => sub { $time = &parsetime }) &&
  print "time = $time seconds\n";

