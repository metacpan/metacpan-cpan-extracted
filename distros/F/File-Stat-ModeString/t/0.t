#!perl -w

require 5.005;
use strict;
use Test;

my $n              =  1+28672*4;
BEGIN { plan tests => 1+28672*4};

use File::Stat::ModeString;
ok(1);#1
--$n;

print STDERR " $n tests will be run, please wait...\n";

foreach my $t (qw(- l p s d c b)) {
 foreach my $ur (qw(- r)) {
  foreach my $uw (qw(- w)) {
   foreach my $ux (qw(- x s S)) {
    foreach my $gr (qw(- r)) {
     foreach my $gw (qw(- w)) {
      foreach my $gx (qw(- x s S)) {
       foreach my $or (qw(- r)) {
        foreach my $ow (qw(- w)) {
	 foreach my $ox (qw(- x t T))
	 {   #28672
	     my $m = "$t$ur$uw$ux$gr$gw$gx$or$ow$ox";

	     ok( is_mode_string_valid($m) )
		 or die "\ncheck_mode_string($m) failed,";

	     my $mode = string_to_mode($m);
	     ok( defined $mode )
		 or die "\nstring_to_mode($m) failed,";

	     my $tchr = mode_to_typechar($mode);
	     ok( $tchr =~ m/^[-dcbpls]$/ )
		 or die "\ntchr = $tchr; mode_to_typechar(". sprintf("%06o", $mode) .") failed on mode \'$m\',";

	     my $mstr = mode_to_string($mode);
	     ok( $mstr, $m )
		 or die "\nmode_to_string(". sprintf("%06o", $mode) .") failed on mode \'$m\',";
	 }
	}
       }
      }
     }
    }
   }
  }
 }
}

