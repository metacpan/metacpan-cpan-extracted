package Linux::DVB::DVBT::Apps::QuartzPVR::Time ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Time - Time methods

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Schedule ;


=head1 DESCRIPTION


=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price 

=head1 BUGS

None that I know of!

=head1 INTERFACE

=over 4

=cut

use strict ;
use Carp ;

our $VERSION = "1.000" ;

#============================================================================================
# USES
#============================================================================================
use Date::Manip ;


#============================================================================================
# GLOBALS
#============================================================================================

our $debug = 0 ;


#============================================================================================
# OBJECT METHODS 
#============================================================================================

#---------------------------------------------------------------------
# Get number of seconds between end of one program and the start of the next
sub timediff_secs
{
	my ($end_entry, $start_entry) = @_ ;

print "timediff_secs(end=$end_entry->{date} @ $end_entry->{start}-$end_entry->{end} - start=$start_entry->{date} @ $start_entry->{start}-$start_entry->{end})\n"  if $debug >=4 ;

	#
	#  end_entry     start_entry
	# |----------|   |--------|
	# s          e   s        e
	#            *   *
	#
		
	my $start_secs = UnixDate($start_entry->{'start_datetime'}, "%s") ;
	my $end_secs   = UnixDate($end_entry->{'end_datetime'}, "%s") ;

	# diff
	my $diff_secs = ($start_secs - $end_secs) ;

print " + diff=$diff_secs\n" if $debug >=4 ;
		
	return $diff_secs ;
}


#---------------------------------------------------------------------------------------------------
sub time2mins
{
	my ($time) = @_ ;

	my $mins=0;
	if ($time =~ m/(\d+)\:(\d+)/)
	{
		$mins = 60*$1 + $2 ;
	}
	return $mins ;
}

#---------------------------------------------------------------------------------------------------
sub mins2time
{
	my ($mins) = @_ ;

	my $hours = int($mins/60) ;
	$mins = $mins % 60 ;
	my $time = sprintf "%02d:%02d", $hours, $mins ;
	return $time ;
}

#-----------------------------------------------------------------------------
# Convert seconds into time (in HH:MM:SS format)
sub secs2time
{
	my ($secs) = @_ ;
	
	my $mins = int($secs/60) ;
	$secs = $secs % 60 ;
	
	my $hours = int($mins/60) ;
	$mins = $mins % 60 ;
	
	my $time = sprintf "%02d:%02d:%02d", $hours, $mins, $secs ;
	return $time ;
}

#---------------------------------------------------------------------------------------------------
# reformat date (make it parseable by Date::Manip)
sub reformat_date
{
	my ($date) = @_ ;

	$date =~ s%-%/%g ;

	return $date ;
}


#---------------------------------------------------------------------------------------------------
# parse the date & time to return a Date::Manip
sub parse_date
{
	my ($date, $time) = @_ ;

	# allow $date to be set to date & time
	$time ||= "" ;
	my $dt = ParseDate("$date $time") ;

	return $dt ;
}

#---------------------------------------------------------------------------------------------------
# create today's date/time return a Date::Manip
sub today_dt
{
	my $dt = ParseDate("now") ;

	return $dt ;
}

#---------------------------------------------------------------------------------------------------
# convert Date::Manip to string
sub dt_format
{
	my ($dt, $fmt) = @_ ;

	return UnixDate($dt, $fmt) ;
}


#---------------------------------------------------------------------------------------------------
# convert Date::Manip to epoch mins
sub dt2mins
{
	my ($dt) = @_ ;

	my $secs = dt_format($dt, "%s") ;
	my $mins = int ($secs / 60) ;

	return $mins ;
}

#---------------------------------------------------------------------------------------------------
# convert Date::Manip to date string
sub dt2date
{
	my ($dt) = @_ ;

#	my $date = dt_format($dt, "%T") ;
	my $date = dt_format($dt, "%Y-%m-%d") ;

	return $date ;
}

#---------------------------------------------------------------------------------------------------
# convert Date::Manip to HH:MM:SS string
sub dt2hms
{
	my ($dt) = @_ ;

	my $time = dt_format($dt, "%H:%M:%S") ;

	return $time ;
}

#---------------------------------------------------------------------------------------------------
# convert Date::Manip to day name string
sub dt2dayname
{
	my ($dt) = @_ ;

	my $dayname = dt_format($dt, "%a") ;

	return $dayname ;
}



#---------------------------------------------------------------------------------------------------
# add an offset to a Date::Manip
sub dt_offset
{
	my ($dt, $offset) = @_ ;

	my $err ;
	$dt = DateCalc($dt, $offset, \$err) ;
print "Date calc error ($offset): $err\n" if ($err) ;
	return $dt ;
}


#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

__END__


