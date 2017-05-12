package Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Prog - Program methods

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

our $VERSION = "1.009" ;

#============================================================================================
# USES
#============================================================================================
use Linux::DVB::DVBT::Utils ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Time ;


#============================================================================================
# GLOBALS
#============================================================================================

our $debug ;

## These fields should get filled in from the listings table
my @PROG_FIELDS = qw/
	pid 
	title 
	text 
	subtitle 
	date 
	start 
	duration 
	episode 
	num_episodes 
	channel 
	adapter 
	priority
	tva_prog
	tva_series
	video
	audio
	event
	pathspec
	genre
/ ;

#============================================================================================
# OBJECT METHODS 
#============================================================================================

#---------------------------------------------------------------------------------------------------

=item C<prog_cmp($prog_a, $prog_b)>

Compare info - given a ref to a prog_info hash and 2 pid's, compare based on date & time

=cut

sub prog_cmp
{
	my ($a, $b) = @_ ;

	return 
		$a->{'priority'} <=> $b->{'priority'}
		||
		$a->{'start_dt_mins'} <=> $b->{'start_dt_mins'} ;
}

#---------------------------------------------------------------------------------------------------

=item C<start_cmp($prog_a, $prog_b)>

Just compare start time (using start_dt_mins field)

=cut

sub start_cmp
{
	my ($a, $b) = @_ ;

	return 
		$a->{'start_dt_mins'} <=> $b->{'start_dt_mins'} ;
}


#---------------------------------------------------------------------
# set the end time, reformat the date etc.
#
# Required:
#  date
#  start
#  duration
#
# modifies:
#  date = changes from YYYY-MM-DD to YYYY/MM/DD for Date::Manip
#
# Creates:
#  end	= end time
#  duration_secs = duration time in seconds
#  start_datetime = Date::Manip date for start time/date
#  end_datetime = Date::Manip date for start time/date
#  start_dt_mins = minutes from 1970 for start date/time
#  end_dt_mins = minutes from 1970 for end date/time
#
sub set_times
{
	my ($entry_href) = @_ ;
	
	# reformat date (make it parseable by Date::Manip)
	$entry_href->{'date'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::reformat_date($entry_href->{'date'}) ; 
	
	# get duration
	my $duration_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::time2mins($entry_href->{'duration'}) ;
	my $duration_add = sprintf "+ %dmin", $duration_mins ;
	$entry_href->{'duration_secs'} = 60 * $duration_mins ;
	
	# cache the start & end date/times
	my $dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::parse_date($entry_href->{date}, $entry_href->{start}) ;
	$entry_href->{'start_datetime'} = $dt ;
	$entry_href->{'start_dt_mins'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($dt) ;
	
	# add duration to start to get end
	$dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($dt, $duration_add) ;
	$entry_href->{'end_datetime'} = $dt ;
	$entry_href->{'end'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($dt) ;
	$entry_href->{'end_date'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2date($dt) ;
	$entry_href->{'end_dt_mins'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($dt) ;
	
}

#---------------------------------------------------------------------
# Check that there is enough time between times to add padding
sub check_pad
{
	my ($end_entry, $start_entry, $pad) = @_ ;

print "check_pad(end=$end_entry->{date} @ $end_entry->{start}-$end_entry->{end} - start=$start_entry->{date} @ $start_entry->{start}-$start_entry->{end})\n" if $debug>=4 ;

	#
	#  end_entry     start_entry
	# |----------|   |--------|
	# s          e   s        e
	#            *   *
	#
		
	# pad
	my $pad_secs = $pad * 60 ;

	# diff
	my $diff_secs = Linux::DVB::DVBT::Apps::QuartzPVR::Time::timediff_secs($end_entry, $start_entry) ;

print " + diff=$diff_secs (pad=$pad_secs)\n" if $debug>=4 ;
		
	return $diff_secs >= $pad_secs ? 1 : 0 ;
}


#---------------------------------------------------------------------
# add padding to start of end time depending of the value of $field
# ($field = 'start' or 'end')
#
# Updates:
#   duration_secs
#   start_datetime & start_dt_mins
#   OR: end_datetime & end_dt_mins
#
sub _add_pad
{
	my ($entry_href, $field, $pad) = @_ ;

if ($debug >=2)
{
print "pad($field) : $entry_href->{date} @ $entry_href->{end} - $entry_href->{end} (duration: $entry_href->{duration})\n" ;
print " + start : $entry_href->{start_datetime} - $entry_href->{end_datetime} (duration: $entry_href->{duration_secs} secs)\n" ;
}
	
	if ($pad) 
	{
		my $pad_add = sprintf "+ %dmin", $pad ;
		my $pad_sub = sprintf "- %dmin", $pad ;
		
		$entry_href->{'duration_secs'} += $pad * 60 ;

		if ($field eq 'start')
		{
			## start early
			$entry_href->{'start_datetime'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($entry_href->{'start_datetime'}, $pad_sub) ;
			$entry_href->{'start_dt_mins'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($entry_href->{'start_datetime'}) ;
		}
		else
		{
			## end late
			$entry_href->{'end_datetime'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($entry_href->{'end_datetime'}, $pad_add) ;
			$entry_href->{'end_dt_mins'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($entry_href->{'end_datetime'}) ;
		}
print " + padded : $entry_href->{start_datetime} - $entry_href->{end_datetime} (duration: $entry_href->{duration_secs} secs)\n" if $debug >=2 ;
		
	}
}

#---------------------------------------------------------------------
# add padding to start of end time depending of the value of $field
# ($field = 'start' or 'end')
#
# Updates:
#   duration_secs
#   start_datetime
#   OR: end_datetime
#
sub pad
{
	my ($entry_href, $field, $pad) = @_ ;

	if ($pad) 
	{
		_add_pad($entry_href, $field, $pad) ;
	}
}

#---------------------------------------------------------------------
# add padding to the end time 
#
# Updates:
#   end_datetime & end_dt_mins
#   timeslip
#
sub timeslip
{
	my ($entry_href, $timeslip) = @_ ;

	$entry_href->{'timeslip'} = 0 ;
	if ($timeslip > 0) 
	{
		$entry_href->{'end_datetime'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($entry_href->{'end_datetime'}, "+ ${timeslip}min") ;
		$entry_href->{'end_dt_mins'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($entry_href->{'end_datetime'}) ;
		$entry_href->{'timeslip'} = $timeslip ;
	}
}



#---------------------------------------------------------------------
# set the end time early by the specified number of seconds
#
# Updates:
#   duration_secs
#   end_datetime
#
sub finish_early
{
	my ($entry_href, $early_secs) = @_ ;

	if ($early_secs) 
	{
		my $pad_sub = sprintf "- %dsec", $early_secs ;
		
		$entry_href->{'duration_secs'} -= $early_secs ;

		## end
		$entry_href->{'end_datetime'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($entry_href->{'end_datetime'}, $pad_sub) ;

print " + early : $entry_href->{start_datetime} - $entry_href->{end_datetime} (duration: $entry_href->{duration_secs} secs)\n" if $debug >=2 ;
		
	}

}

#---------------------------------------------------------------------
# Given a listings entry, create a new recording entry
sub new_recording
{
	my ($listing_href, $record, $record_id, $priority, $pathspec) = @_ ;
	my $recording_href = {} ;

	# add 'subtitle' based on main text
	$listing_href->{'text'} ||= "" ;
	$listing_href->{'subtitle'} ||= Linux::DVB::DVBT::Utils::subtitle($listing_href->{'text'}) ;
	
print "new_recording(title=$listing_href->{'title'}, episode=$listing_href->{'episode'}, num=$listing_href->{'num_episodes'}, subtitle=$listing_href->{'subtitle'})\n" if $debug ;

	foreach (@PROG_FIELDS)
	{
		$recording_href->{$_} = $listing_href->{$_} ;
	}
	
	# set type code (once, weekly etc)
	$record = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('once') unless defined($record) ;
	$recording_href->{'record'} = $record ;

	# set priority
	$recording_href->{'priority'} ||= $priority ;

	# set parent recording id 
	# NOTE: will end up with multiple program recordings all with same record id - this is just the parent id that we can use to trace back to
	# the original MySQL 'record' table entry 
	#
	# If undefined then this is a new entry
	$recording_href->{'id'} = $record_id  if defined($record_id);
	$recording_href->{'rid'} = $recording_href->{'id'} ; 
	
	# Set up default pathspec
	$recording_href->{'pathspec'} = $pathspec || "" ; 
	
	return $recording_href ;
}


#============================================================================================
# DEBUG
#============================================================================================
#

#--------------------------------------------------------------------------------------------
sub disp_sched_entry
{
	my ($prog_href) = @_ ;
	
	print "$prog_href->{title} $prog_href->{date} $prog_href->{start} - $prog_href->{end} ($prog_href->{duration})" ;	
	print "(".Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'start_datetime'}) . " - " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'end_datetime'}).") " ;	
	print " : start_dt_mins=$prog_href->{'start_dt_mins'} : end_dt_mins=$prog_href->{'end_dt_mins'} : duration_secs=$prog_href->{'duration_secs'}" ;	
	print " : record $prog_href->{record}" ;	
	print " : priority $prog_href->{priority}" ;	
	print " : pid $prog_href->{pid}" ;	
	print " : prog pid $prog_href->{prog_pid}" if $prog_href->{prog_pid} ;	
	print " : chan $prog_href->{channel}" ;
	if (exists($prog_href->{'timeslip'}))
	{
		print " : timeslip $prog_href->{timeslip}" ;	
	}	
	if ($prog_href->{'pathspec'})
	{
		print " : pathspec $prog_href->{pathspec}" ;	
	}	
	print "\n" ;	
}
	
#--------------------------------------------------------------------------------------------
sub disp_sched
{
	my ($msg, $sched_aref) = @_ ;
	
	print "$msg\n" ;
	my @list = sort { start_cmp($a, $b) } @$sched_aref ;

	foreach my $prog_href (@list)
	{
		if ($prog_href->{'type'} eq 'multiplex')
		{
			print "  ** Multiplex (".$prog_href->{'multid'}.") ** " ; disp_sched_entry($prog_href) ;	
			foreach my $mux_prog_href (@{$prog_href->{'multiplex'}})
			{
				print "    " ; disp_sched_entry($mux_prog_href) ;					
			}
		}
		else
		{
			print "  " ; disp_sched_entry($prog_href) ;	
		}
	}
	print "\n" ;	
}
	


# ============================================================================================
# END OF PACKAGE
1;

__END__


