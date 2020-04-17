#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Java::Release qw(parse_java_jdk_release);

if (@ARGV < 1) {
       print STDERR "Usage: $0 java_jdk_release\n";
       exit 1;
}
my $java_jdk_release = $ARGV[0];

# Parse Java JDK release name.
my $release_hr = parse_java_jdk_release($java_jdk_release);

p $release_hr;

# Output like:
# Usage: qr{\w+} java_jdk_release