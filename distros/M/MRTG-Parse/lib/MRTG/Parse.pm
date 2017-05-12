#############################################################################
# MRTG::Parse - v0.03                                                       #
#                                                                           # 
# This module parses and utilizes the logfiles produced by MRTG             #
# A full documentation is attached to this sourcecode in POD format.        #
#                                                                           #
# Copyright (C) 2005 Mario Fuerderer <mario@codehack.org>                   #
#                                                                           #
# This library is free software; you can redistribute it and/or             #
# modify it under the terms of the GNU Lesser General Public                #
# License as published by the Free Software Foundation; either              #
# version 2.1 of the License, or (at your option) any later version.        #
#                                                                           #
# This library is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU         #
# Lesser General Public License for more details.                           #
#                                                                           #
# You should have received a copy of the GNU Lesser General Public          #
# License along with this library; if not, write to the Free Software       #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA #
#                                                                           #
#                                    Mario Fuerderer <mariof@cpan.org)      #
#                                                                           #
#############################################################################

package MRTG::Parse;

use 5.006;
use strict;
use warnings;
use Time::Local;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(mrtg_parse);

our $VERSION = '0.03';


###########################################
# This subroutine receives the needed     #
# arguments and passes them to the main   #
# parser() subroutine.                    #
###########################################
sub mrtg_parse {
  my $logfile  = $_[0];
  my $period   = $_[1];
  my $unit     = $_[2];

  # Start the parser and save total incoming and outgoing bytes to @array_traffic_total
  my @array_traffic_total           = &parser($logfile, $period);
  # Convert the bytes into the right unit (you may call it "prefix multiplier").
  my @array_traffic_total_unit_in   = &traffic_output($array_traffic_total[0], $unit);
  my @array_traffic_total_unit_out  = &traffic_output($array_traffic_total[1], $unit);
  my @array_traffic_total_unit_sum  = &traffic_output($array_traffic_total[0] + $array_traffic_total[1], $unit);

  my @return;
  push(@return, join(' ', @array_traffic_total_unit_in));
  push(@return, join(' ', @array_traffic_total_unit_out));
  push(@return, join(' ', @array_traffic_total_unit_sum));

  return @return;
}


###########################################
# Our main subroutine, which parses the   #
# logfile with the values passed through  #
# mrtg_parse().                           # 
########################################### 
sub parser {                              
  my $logfile = $_[0];
  my $period  = $_[1];

  my $parse_type;
  my $start_date;
  my $end_date;
  my $start_epoch;
  my $end_epoch;
  my $weekday;
  my $month;
  my $day;
  my $time;
  my $year;

  # Decide whether we should parse for static time period...
  if ($period eq "day" || $period eq "month" || $period eq "year") {
    ($weekday, $month, $day, $time, $year) = split(/ +/, localtime(time()));
    $parse_type = "static";  
  # ...or an individual one.
  } elsif ($period =~ /\d{8}-\d{8}/) {
    ($start_date, $end_date) = split(/-/, $period);

    unless ($start_date - $end_date =~ /-/) {
      die("Error: time periods are not in the right order!\n");
    }
    
    # Calculate start and end date to seconds since the system epoch
    $start_date  =~ /(\d{4})(\d{2})(\d{2})/;
    my $start_year  = $1;
    my $start_month = $2;
    my $start_day   = $3;
    $start_epoch = timelocal("00", "00", "00", $start_day, $start_month-1, $start_year);

    $end_date    =~ /(\d{4})(\d{2})(\d{2})/;
    my $end_year    = $1;
    my $end_month   = $2;
    my $end_day     = $3;
    $end_epoch   = timelocal("00", "00", "00", $end_day, $end_month-1, $end_year);

    $parse_type = "individual";
  } else {
    die("Error: time period is not present or in an unkown format!\n");
  }

  open(LOG, "$logfile") or die "Error: Could not open MRTG-Logfile ($logfile)";

  # Set any counter to zero before we start parsing.
  my $traffic_total_in  = 0;
  my $traffic_total_out = 0;
  my $last_date         = 0;
  my $counter           = 0;

  while (my $line=<LOG>) {
    # We want to ignore the first line, because it's just the sum of the rest.
    unless ($counter == 0) {
      my $date;
      my @column = split(/\s+/, $line);
      # Build the match-pattern
      my $pattern; 
      if ($parse_type eq "static") {
        $date = scalar localtime($column[0]);
        if ($period eq "day") {
          $pattern = ".+ $month.+$day .+$year";
        } elsif($period eq "month") {
          $pattern = ".+$month.+$year";
        } elsif($period eq "year") {
          $pattern = ".+$year";
        }
       # Check if the current line matches out pattern.
       if ($date =~ /^$pattern$/) {
         my $traffic_in  = $column[1];
         my $traffic_out = $column[2];
    
         my $time_range;
 
         unless ($last_date == 0) { 
           # Calculate the time difference between the current and the previously processd line.
           $time_range = $last_date - $column[0];
         } else {
           # Set time range to zero if it's the first line.
           $time_range = 0;
         } 
        
         # Multiply the bytes with the time range.
         $traffic_total_in  += $traffic_in  * $time_range;
         $traffic_total_out += $traffic_out * $time_range;
        
         # Set the $last_date variable to the new value.
         $last_date  = $column[0];
       }
      } elsif ($parse_type eq "individual") {
        
	$date = $column[0];

        if (($date > $start_epoch) && ($date < $end_epoch)) {
	  my $traffic_in  = $column[1];
	  my $traffic_out = $column[2];

	  my $time_range;

	  unless ($last_date == 0) {
	    $time_range = $last_date - $column[0];
          } else {
	    $time_range = 0;
	  }

          $traffic_total_in  += $traffic_in  * $time_range;
	  $traffic_total_out += $traffic_out * $time_range;

	  $last_date  = $column[0];
	}
	
      }
    }
    $counter++;
  }

  my @array;
  push(@array, $traffic_total_in);
  push(@array, $traffic_total_out);
  return @array;

  close LOG;
}


###########################################
# This is just to get the right unit...   #
###########################################
sub traffic_output {
  my $bytes        = $_[0];
  my $desired_unit = $_[1];
  
  my @array;
  my $unit;
  my $total_count;

  my @unit_array = qw(B KB MB GB TB);
  my $temp_unit  = $bytes;
  my $counter    = 0;
  my $check      = "false";

  # Run through the @unit_array
  foreach my $unit_entry (@unit_array) {
    # We don't need to divide for the first entry, because it's already in byte
    unless ($counter == 0) {
      $temp_unit = ($temp_unit / 1024);
      unless ($desired_unit) {
        # If our value is lower than 1, we should stop here in order to retain an adequate unit.
	if ($temp_unit < 1) {
          last;
        }
      }
    }

    $total_count  = $temp_unit;
    $unit         = $unit_entry;

    if ($desired_unit) {
      if ($desired_unit eq $unit_entry) {
        $check = "true";
        last;
      }
    }

    $counter++;
  }
  
  push(@array, $total_count);
  push(@array, $unit);
  if ($desired_unit && $check eq "true") {
    return @array;
  } elsif (defined($desired_unit) && $check ne "true") {
    die("Erorr: $desired_unit is a non valid unit!\n");
  } else {
    return @array;
  }
}


__END__

=head1 MRTG::Parse

MRTG::Parse - Perl extension for parsing and utilizing the logfiles
generated by the famous MRTG Tool.


=head1 SYNOPSIS

  use strict;
  use MRTG::Parse;
  
  my $mrtg_logfile = "/var/www/htdocs/mrtg/eth0.log";
  my $period       = "day";
  my $desired_unit = "GB"; 

  my ($traffic_incoming, $traffic_outgoing, $traffic_sum) = mrtg_parse($mrtg_logfile, $period, $desired_unit);

  print "Incoming Traffic:   $traffic_incoming\n";
  print "Outgoing Traffic:   $traffic_outgoing\n";
  print "= Sum               $traffic_sum\n";
  

=head1 DESCRIPTION

This perl extension enables its users to parse and utilize the logfiles that
are generated by the famous MRTG (Multi Router Traffic Grapher) tool.

mrtg_parse() takes three argument:
        
	1st:  filename of the mrtg logfile
	2nd:  time period to genereate the output for
	      valid values are:   
	                         - individual time periods like: 20040821-20050130 (ISO 8601)
	                         - static values:                day, month, year
	3rd:  the desired unit (optional)
	      valid values are: 
	                         - B, KB, MB, GB, TB 
				 - if missing mrtg_parse will chose an adequate one for you

mrtg_parse() returns three values:

        1st:  Incoming traffic
	2nd:  Outgoing traffic
	3rd:  Sum of incoming and outgoing


=head2 EXPORT

mrtg_parse()


=head1 SEE ALSO

http://people.ee.ethz.ch/~oetiker/webtools/mrtg/ - MRTG Homepage

http://people.ee.ethz.ch/~oetiker/webtools/mrtg/mrtg-logfile.html - Description of the MRTG Logfile Format


=head1 BUGS

Please report any bugs or feature requests directly to mariof@cpan.org. Thanks!


=head1 AUTHOR

Mario Fuerderer, E<lt>mariof@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Mario Fuerderer

This library is free software; you can redistribute it and/or             
modify it under the terms of the GNU Lesser General Public                
License as published by the Free Software Foundation; either             
version 2.1 of the License, or (at your option) any later version.      
                                                                       
This library is distributed in the hope that it will be useful,           
but WITHOUT ANY WARRANTY; without even the implied warranty of            
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU         
Lesser General Public License for more details.                           
                                                                          
You should have received a copy of the GNU Lesser General Public          
License along with this library; if not, write to the Free Software       
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 


=cut
