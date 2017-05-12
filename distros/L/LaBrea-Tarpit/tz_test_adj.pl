#!/usr/bin/perl

package LaBrea::Tarpit::tz_test_adj;

use strict;
#use diagnostics;
use Time::Local;
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.01 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

LaBrea::Tarpit::tz_test_adj

=head1 SYNOPSIS

  Used only by the test suite.
  From t/xxx.t
	use lib qw( ./ );
	require tz_test_adj.pl

	$expect = new LaBrea::Tarpit::tz_test_adj;
	$realtime = $expect->{sometime};
	...
	...

	$max = $expect->{max};	# max of times above

=cut

sub new {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $expect = {};
# time zone and year must be adjusted
#
  my $test_no_year = <<EOF;
# mon   dy hr mn sc yyy timestamp
Nov 10  30 14 31 36 101 1007159496
Nov 10  30 14 31 39 101 1007159499
Nov 10  30 14 31 40 101 1007159500
Nov 10  30 14 31 41 101 1007159501
Nov 10  30 14 31 50 101 1007159510
Nov 10  30 14 31 59 101 1007159519
Nov 10  30 15 31 39 101 1007163099
EOF

# time zone only must be adjusted
  my $test_absolute = <<EOF;
Dec 11  1 13 11 07 101 1007241067
Dec 11  1 13 12 03 101 1007241123
Dec 11  1 13 12 05 101 1007241125
Dec 11  1 13 12 06 101 1007241126
Dec 11  1 13 12 07 101 1007241127
EOF

  foreach(split('\n', $test_no_year)) {
    next if $_ =~ /^\s*#/;
    my ($mon,$day,$hr,$min,$sec,$yr,$ts) = &parse_date($_);
# year is relative, get it now
    my ($nowmo,$nowyr) = (localtime(time))[4,5];
    $yr = ($mon > $nowmo)	# roll over to new year??
	? $nowyr -1
	: $nowyr;
    $expect->{$ts} = timelocal($sec,$min,$hr,$day,$mon,$yr);
  }

  foreach(split('\n', $test_absolute)) {
    next if $_ =~ /^\s*#/;
    my ($mon,$day,$hr,$min,$sec,$yr,$ts) = &parse_date($_);
    $expect->{$ts} = timelocal($sec,$min,$hr,$day,$mon,$yr);
  }

  my $max = 0;
  foreach(values %{$expect}) {
    $max = $_ if $max < $_;
  }
  $expect->{max} = $max;

  bless ($expect, $class);
  return $expect;
}
  
sub parse_date {
  my ($s) = @_;
#	       mon	dy	hr	mn	sc	yy	ts
    $s =~ /(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)$/;
  return ($1,$2,$3,$4,$5,$6,$7);
}

###########################################################
# BELOW IS SETUP STUFF FOR ABOVE
###########################################################
#
# call &LaBrea::Tarpit::tz_test_adj::print_tvals
# to print the test date values at the top of this file.
#
# If you need to update the test values, modify the foreach
# statement to add / edit values the run &print_tvals to 
# print the new array for insertion into the new adjustment
# strings. YOU MAY HAVE TO CONVERT 'h174' TO YEAR 2001 OR
# WHATEVER THE NEW TEST STRING YEAR IS TO GET THIS TO WORK.
#
sub print_tvals {
#Nov 10 30 14 31 36 101 1007159496
  print
"# mon\tdy hr mn sc yyy timestamp
";

  foreach (
'Nov 30 14:31:36 h174 /usr/local/bin/LaBrea: Persist Activity: 67.97.64.173 61623 -> 63.77.172.50 80',
'Nov 30 14:31:39 h174 /usr/local/bin/LaBrea: Initial Connect (tarpitting): 63.204.44.126 2014 -> 63.77.172.39 80',
'Nov 30 14:31:40 h174 /usr/local/bin/LaBrea: Additional Activity: 63.204.44.126 2014 -> 63.77.172.39 80',
'Nov 30 14:31:41 h174 /usr/local/bin/LaBrea: Persist Trapping: 63.204.44.126 2014 -> 63.77.172.39 80 *',
'Nov 30 14:31:50 h174 /usr/local/bin/LaBrea: Persist Trapping: 63.204.44.126 2014 -> 63.77.172.39 80 *',
'Nov 30 14:31:59 h174 /usr/local/bin/LaBrea: Current average bw: 145 (bytes/sec)',
'Nov 30 15:31:39 h174 /usr/local/bin/LaBrea: Initial Connect (tarpitting): 222.205.44.126 2014 -> 63.77.172.49 123',
'Sat Dec  1 13:11:07 2001 2001 Persist Activity: 63.227.234.71 4628 -> 63.77.172.57 81 *',
'Sat Dec  1 13:12:03 2001 Persist Activity: 63.87.135.216 3204 -> 63.77.172.35 80',
'Sat Dec  1 13:12:05 2001 Initial Connect (tarpitting): 63.222.243.6 2710 -> 63.77.172.16 81',
'Sat Dec  1 13:12:06 2001 Additional Activity: 63.222.243.6 2710 -> 63.77.172.16 81 *',
'Sat Dec  1 13:12:07 2001 Persist Trapping: 63.222.243.6 2710 -> 63.77.172.16 81',
  ) {
    my $time =&make_time($_);
    print $time,"\n";
  }
}
  
# used by above to print and make values
#
sub make_time {
    my ($line) = @_;
    require Time::Local;
    return undef unless $line =~ /(.+)\s+(\d+):(\d+):(\d+)\s+(\w+)\s+/;
    @_ = split(/\s+/,$1);
    my $day = pop @_;
    my $mon = pop @_;
    print $mon;
    $mon = ${&mon}->{"\L$mon"};
    my ($hr,$min,$sec,$yr) = ($2,$3,$4,$5);
    if ($yr =~ /[^\d]/) {
      my ($nowmo,$nowyr) = (localtime(time))[4,5];
      $yr = ($mon > $nowmo)             # roll over to new year??
        ? $nowyr -1
        : $nowyr;  
    } elsif ( $yr > 1900 ) {    # most likely
      $yr -= 1900;
    } elsif ( $yr < 70 ) {      # yr 2000 or more
      $yr += 100;
    }                           # else leave as-is, 70 - 99
    print " $mon $day $hr $min $sec $yr ";
    return &Time::Local::timelocal($sec,$min,$hr,$day,$mon,$yr);
}

# used by above to look up month value
#
sub mon {
  return {qw(jan 0 feb 1 mar 2 apr 3 may 4 jun 5 jul 6 aug 7 sep 8 oct 9 nov 10 dec 11)};
}
1;
__END__

=head1 EXPORT

  None by default.

=head1 COPYRIGHT

Copyright 2002, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

