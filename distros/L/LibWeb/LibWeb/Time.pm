#==============================================================================
# LibWeb::Time -- Various time formats for libweb applications

package LibWeb::Time;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# $Id: Time.pm,v 1.4 2000/07/19 20:31:57 ckyc Exp $

$VERSION = '0.02';

#-##########################
# Use standard library.
use strict;
use vars qw($VERSION);

#-##########################
# Methods.
sub new {
    my($class, $self); 
    $class = shift;

    my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    my $month = $mon + 1;
    my $month_day = $mday;
    $self = {
	     'sec' => ($sec < 10) ? "0$sec" : $sec,
	     'min' => ($min < 10) ? "0$min" : $min,
	     'hour' => ($hour < 10) ? "0$hour" : $hour,
	     'mday' => ($mday < 10) ? "0$mday" : $mday,
	     'month' =>  ($month < 10) ? "0$month" : $month, 
	     'month_day' => ($month_day < 10) ? "0$month_day" : $month_day,
	     'mon' => ('Jan','Feb','March','April','May','June','July','Aug','Sep','Oct','Nov','Dec')[$mon],
	     'year' => $year + 1900,
	     'wday' => ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday]
	    };
    bless( $self, ref($class) || $class );
}

sub DESTROY {}

sub get_date {
    # return 'wday month mday'.
    my $self = shift;
    $self->{wday}.' '.$self->{mon}.' '.$self->{mday};
}

sub get_time {
    # return hh:mm:ss
    my $self = shift;
    $self->{hour}.':'.$self->{min}.':'.$self->{sec};
}

sub get_datetime {
    # return 'wday mm dd hh:mm:ss yyyy'.
    my $self = shift;
    $self->{wday}.' '.$self->{mon}.' '.$self->{mday}.' '.
      $self->{hour}.':'.$self->{min}.':'.$self->{sec}.' '.$self->{year};
}

sub get_timestamp {
    # return 'yyyymmddhhmmss'.
    my $self = shift;
    $self->{year}.$self->{month}.$self->{month_day}.$self->{hour}.$self->{min}.$self->{sec};
}

sub get_year {
    # return 'yyyy'.
    shift->{'year'};
}

1;
__END__

=head1 NAME

LibWeb::Time - Various time formats for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

No non-standard Perl's library is required.

=back

=head1 ISA

=over 2

=item *

None.

=back

=head1 SYNOPSIS

  use LibWeb::Time();
  my $time = new LibWeb::Time();

  my $wday_mon_mday = $time->get_date();

  my $hh_mm_ss = $time->get_time();

  my $wday_mon_dd_hh_mm_ss_yyyy = $time->get_datetime();

  my $yyyymmddhhmmss = $time->get_timestamp();

  my $yyyy = $time->get_year();

=head1 ABSTRACT

This class uses the perl's localtime() routine to provide several
methods which return time in several formats.

The current version of LibWeb::Time is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

=head2 METHODS

B<get_date()>

Return 'wday mon mday' as a string, e.g. 'Sun May 28'.

B<get_time()>

Return 'hh:mm:ss' as a string, e.g. '14:35:47'.

B<get_datetime()>

Return 'wday mon dd hh:mm:ss yyyy' as a string, e.g. 'Sun May 28
14:35:47 2000'.  This is the same as using the perl's localtime()
directly in scalar context.

B<get_timestamp()>

Return 'yyyymmddhhmmss' as a string, e.g. '20000528133547'.

B<get_year()>

Return 'yyyy' as a string, e.g. '2000'.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS


=head1 BUGS


=head1 SEE ALSO

=cut
