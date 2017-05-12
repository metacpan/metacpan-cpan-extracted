# GenPerl module 
#

package Genetics::Util ;

require Exporter ;
use strict ;

use vars qw($ID $VERSION @ISA @EXPORT) ;
$ID = "SLM::Lib" ;
$VERSION = "0.01" ;
@ISA = qw(Exporter) ;
@EXPORT = qw(now browse structure2Str) ;


=head1 NAME

  SLM::Lib

=head1 SYNOPSIS

  Not really appropriate.  See individual functions.

=head1 DESCRIPTION

  A collection of GenPerl utility functions.

=head1 LICENSE

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
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 FEEDBACK

Currently, all feedback should be sent directly to the author.

=head1 AUTHOR - Steve Mathias

Email: mathias@genomica.com

Phone: (720) 565-4029

Address: Genomica Corporation 
         1745 38th Street
         Boulder, CO 80301

=head1 DETAILS

The rest of the documentation describes each of the object variables and 
methods. The names of internal variables and methods are preceded with an
underscore (_).

=head2 now

 Function  : Generate a text representation of the current date/time
 Arguments : Hash
 Returns   : Scalar text string
 Example   : print LOG now(format => 'fancy')
 Scope     : Public
 Comments  : Formats: raw       : comma-delimited output from localtime(time)
                      simple    : "1965-11-14 12:45:44"
                      dayonly   : "14 November 1965"
                      fancy     : "Friday November 14, 1965 12:45:44"
                      mysqldate : "1965-11-14"

=cut

sub now {
  my(%args) = @_ ;
  my $format = $args{format} || "raw" ;

  my @textDays = qw(Sunday Monday Tuesday Wednesday 
		    Thursday Friday Saturday) ;
  my @textMonths = qw(January February March April MAy June July 
		      August September October November December) ;
  my($textDay, $textMonth, $now) ;

  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time) ;

  $year += 1900 unless $format eq "raw" ;

  if ($format eq "mysqldate") {
    $mon++ ;
    ($mon < 10) and ($mon = "0" . $mon) ;
    ($mday < 10) and ($mday = "0" . $mday) ;
    $now = "$year-$mon-$mday" ;
  } elsif ($format eq "simple") {
    $mon++ ;
    ($mon < 10) and ($mon = "0" . $mon) ;
    ($mday < 10) and ($mday = "0" . $mday) ;
    $now = "$year-$mon-$mday $hour:$min:$sec" ;
  } elsif ($format eq "fancy") {
    $textDay = $textDays[$wday] ;
    $textMonth = $textMonths[$mon] ;
    $now = "$textDay $textMonth $mday, $year $hour:$min:$sec" ;
  } elsif ($format eq "dayonly") {
    $textMonth = $textMonths[$mon] ;
    $now = "$mday $textMonth $year" ;
  } else {
    # raw format
    $now = "$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst" ;
  }

  return $now ;
}

=head2 browse

 Function  : A simple de-referencing browser for perl data structures
 Arguments : Scalar
 Returns   : N/A
 Example   : browse()
 Scope     : Public
 Comments  : See also structure2Str()

=cut

sub browse {
  my ($val, $level) = @_ ;
  $level = 0 unless defined $level ;
  my $tab = '    ' x $level ;
  my $ref = ref $val ;
  
  if (not defined $val) {
    print "undef\n" ;
  } elsif ($ref eq 'CODE' or $ref eq 'GLOB') {
    print $val, "\n" ;
  } elsif ($ref eq 'ARRAY') {
    print "$ref\n" ;
    $level++ ;
    for(my $i = 0; $i < @{$val}; $i++) {
      print "$tab    [$i] = " ;
      browse($val->[$i], $level) ;
    }
  } elsif ($ref eq 'HASH' or $ref =~ /^[A-Z]/) {
    print "$ref\n" ;
    $level++ ;
    foreach my $key (keys %{$val}) {
      print "$tab    $key => " ;
      browse($val->{$key}, $level) ;
    }
  } elsif ($ref) {
    print $ref, "\n" ;
  } else {
    print $val, "\n" ;
  }
}

=head2 structure2Str

 Function  : Convert a pointer to a complex perl data structure into a string 
             for printing.
 Arguments : Scalar
 Returns   : N/A
 Example   : browse()
 Scope     : Private Class Method
 Comments  : Recurses if nested pointers exist in the data structure.

=cut

sub structure2Str {
    my($value) = @_ ;
    my($str, $k, $v, @data) ;

    if (not defined $value) {
	$str = "" ;
    } elsif (not ref $value) {
	$str = $value ;
    } elsif (ref $value eq "ARRAY") {
	foreach $v (@$value) {
	    $str = _attr2String($v) ;
	    push(@data, $str)
	}
	$str = "[ " . join(", ", @data) . " ]" ;
	
    } elsif (ref $value eq "HASH") {
	@data = () ;
	while (($k,$v) = each %$value) {
	    $str = _attr2String($v) ;
	    push(@data, "$k => $str") ;
	}
	$str = "{ " . join(", ", @data) . " }" ;
    } else {
	$str = "Reference to an unsupported type" ;
    }

    return($str) ;
}
1;

