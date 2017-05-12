#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Log::Log4perl;
use Test::More tests => 19;

# Set up the logger specification through the conf file
Log::Log4perl->init("$Bin/testlogger.conf");

# Can we "use" the module?
BEGIN {
  use_ok('Grid::Request::HTC');
}
my @methods = qw(new debug);

can_ok( "Grid::Request::HTC", @methods); 

foreach my $method (@methods) {
    can_ok('Grid::Request::HTC', $method);
}

{ # Since Grid::Request::HTC does not implement _init, but leaves it to
  # sub-classes, we jump into the package and override this behavior.
  package Grid::Request::HTC;
  sub _init {
     return 1;
  }
} 

my $h = Grid::Request::HTC->new;

my %levels = ( debug => 5,
               info  => 4,
               warn  => 3,
               error => 2,
               fatal => 1,
             );
my %names = reverse %levels;

# Test the integer debug levels.
foreach my $integer_debug_level ( sort values %levels ) {
    $h->debug($integer_debug_level);
    is($h->debug, $integer_debug_level, "Test numeric debug level $integer_debug_level.");
}

# Test the lower case debug level names.
foreach my $integer_debug_level ( sort keys %names ) {
    $h->debug($names{$integer_debug_level});
    is($h->debug, $integer_debug_level, "Test string debug level $names{$integer_debug_level}.");
}

# Test the upper case debug level names.
foreach my $integer_debug_level ( sort keys %names ) {
    my $uc_name = uc($names{$integer_debug_level});
    $h->debug($uc_name);
    is($h->debug, $integer_debug_level, "Test string debug level $uc_name.");
}
