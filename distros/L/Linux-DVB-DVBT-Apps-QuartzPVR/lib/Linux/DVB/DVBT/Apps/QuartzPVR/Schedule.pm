package Linux::DVB::DVBT::Apps::QuartzPVR::Schedule ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Schedule - Manage program recording scheduling

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

our $VERSION = "1.015" ;

#============================================================================================
# USES
#============================================================================================
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Crontab ;
use Linux::DVB::DVBT::Apps::QuartzPVR::DVB ;

use Linux::DVB::DVBT::Utils ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object) ; 

#============================================================================================
# GLOBALS
#============================================================================================

## Schedule HASH entry eventually contains:
#
# From SQL:
#	pid 
#	channel 
#	title 
#	date   (YYYY/MM/DD for Date::Manip)
#	start 
#	duration 
#	episode 
#	num_episodes 
#	repeat 
#	adapter 
#	chan_type 
#	record
#
#   priority - from schedule/recording (1=highest; 100=lowest)
#
# Created:
#  end	= end time
#  duration_secs = duration time in seconds
#  start_datetime = Date::Manip date for start time/date
#  end_datetime = Date::Manip date for start time/date
#  start_dt_mins = minutes from 1970 for start date/time
#  end_dt_mins = minutes from 1970 for end date/time
#
#


my %FIELDS = (
	'phase'		=> '',

	## Internal
	'_tvsql'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Sql object
	'_tvrec'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Recording object
	'_tvreport'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Report object
	
	'today_mins'	=> undef,		# Today's date/time in minutes
) ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

=item C<new([%args])>

Create a new object.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	my $today_dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::today_dt() ;
	my $today_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($today_dt) ;
	$this->today_mins($today_mins) ;

	return($this) ;
}



#============================================================================================
# CLASS METHODS 
#============================================================================================

#-----------------------------------------------------------------------------

=item C<init_class([%args])>

Initialises the Cwrsync object class variables. Creates a class instance so that these
methods can also be called via the class (don't need a specific instance)

=cut

sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

	if (! keys %args)
	{
		%args = () ;
	}
	
	# Add extra fields
	$class->add_fields(\%FIELDS, \%args) ;

	# init class
	$class->SUPER::init_class(%args) ;

	# Create a class instance object - allows these methods to be called via class
	$class->class_instance(%args) ;
	
}

#============================================================================================
# OBJECT DATA METHODS 
#============================================================================================



#============================================================================================
# OBJECT METHODS 
#============================================================================================

#---------------------------------------------------------------------
sub existing_schedule
{
	my $this = shift ;
	my $tvsql = $this->_tvsql ;
	my $tvrec = $this->_tvrec ;
	
	my @schedule = $tvsql->select_scheduled() ;

	$this->fix_times(\@schedule) ;	
	
	# Set up sub-title entry
	foreach (@schedule)
	{
		$_->{'subtitle'} ||= Linux::DVB::DVBT::Utils::subtitle($_->{'text'}) ;
	}
	
	# fix any mutliplex recordings
	@schedule = $this->fix_multiplex(\@schedule) ;
	
	# sort by start
	@schedule = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @schedule ;
	
	return @schedule ;
}

#---------------------------------------------------------------------
# Gets the latest scheduled recordings list from the database and also
# sets up various date/time values for later use
sub fix_times
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;

	# Set up times
	foreach (@$schedule_aref)
	{
		# Set end time etc
		# only do so if extra information hasn't already been set
		unless (exists($_->{'start_dt_mins'}))
		{
			Linux::DVB::DVBT::Apps::QuartzPVR::Prog::set_times($_) ;
		}
	}
}


#---------------------------------------------------------------------
# Run through all the phases to get the recordings scheduled. Allows there to already
# be a schedule of recordings (e.g. for when we want to add some new recordings to a
# previous good set)
#
sub schedule_recordings
{
	my $this = shift ;
	my ($num_adapters, $recording_schedule_aref, $schedule_aref, $unscheduled_aref, %options) = @_ ;

$this->prt_data("schedule_recordings() options=", \%options) if $this->debug >= 4 ;

	## filter out any recordings that are IPLAY-only
	my @dvbt_recordings = $this->filter_dvbt($recording_schedule_aref) ;

	## remove dummy "fuzzy" recordings
	my @filtered_recordings = $this->remove_dummies(\@dvbt_recordings) ;
	$recording_schedule_aref = \@filtered_recordings ;
	
	# keep a copy for later
	my $requested_rec_aref = $recording_schedule_aref ;
	my @requested_recordings = (@$recording_schedule_aref) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

	my $tvreport = $this->_tvreport ;

	# report
	$this->_new_phase('initial') ;
	$tvreport->recordings($recording_schedule_aref) ;
	$tvreport->scheduling($schedule_aref, $unscheduled_aref) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P0 Recordings=", $recording_schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P0 Schedule=", $schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P0 Unscheduled=", $unscheduled_aref) if $this->debug >= 4 ;

	## If allowed, group into multiplex blocks
	if ($options{'enable_multirec'})
	{
		# Mark any multiplexes that are currently recording (or will be recording) as 'locked'
		$this->lock_multiplexes($schedule_aref) ;

		## merge together existing schedule over to recording list (along with the requested recordings!) 
		## (This removes duplicates!)
		my $demux_schedule_aref = $this->de_multiplex($schedule_aref) ;
		my %sched_recordings = map { $_->{'pid'} => $_ } @$demux_schedule_aref ;
		my %req_recordings = map { $_->{'pid'} => $_ } @$recording_schedule_aref ;
		my %all_recordings = (%sched_recordings, %req_recordings) ;
	
		# Move existing schedule over to recording list (along with the requested recordings!)
		@$recording_schedule_aref = values %all_recordings ;
		
		# clear out
		@$schedule_aref = () ;
		@$unscheduled_aref = () ;

		## Group new recordings into multiplex blocks
		$recording_schedule_aref = $this->block_multiplex($recording_schedule_aref, %options) ;

		$this->_new_phase('multiplex') ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Multiplex recordings:", $recording_schedule_aref) if $this->debug ;

	}
	
	## 1: Schedule programs evenly over adapters
	if (scalar(@$recording_schedule_aref) || scalar(@$unscheduled_aref))
	{
		$this->_new_phase('no adjacent programs') ;
		$this->schedule($num_adapters, $recording_schedule_aref, $schedule_aref, $unscheduled_aref, 'adjacent' => 0) ;
	
		# report
		$tvreport->scheduling($schedule_aref, $unscheduled_aref) ;
	}
	
$this->prt_data("Recordings=", $recording_schedule_aref) if $this->debug >= 4 ;
$this->prt_data("Schedule=", $schedule_aref, "Unscheduled=", $unscheduled_aref) if $this->debug >= 4 ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P1 Recordings=", $recording_schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P1 Schedule=", $schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P1 Unscheduled=", $unscheduled_aref) if $this->debug >= 4 ;


if ($this->debug >= 2)
{
print "\n==[ Phase 1 ]=============================================\n" ;
$tvreport->display_unschedule_by_adap($schedule_aref, $unscheduled_aref) ;
print "\n==========================================================\n" ;	
}

	## If unscheduled programs...
	if (@$unscheduled_aref)
	{

		## 2: Attempt to add unscheduled programs into any gaps
		$this->_new_phase('insert programs into gaps') ;
		$this->schedule($num_adapters, $unscheduled_aref, $schedule_aref, $unscheduled_aref, 'adjacent' => 1) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P2 Recordings=", $recording_schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P2 Schedule=", $schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P2 Unscheduled=", $unscheduled_aref) if $this->debug >= 4 ;


if ($this->debug >= 2)
{
print "\n==[ Phase 2 ]=============================================\n" ;
$tvreport->display_unschedule_by_adap($schedule_aref, $unscheduled_aref) ;
print "\n==========================================================\n" ;	
}

		# report
		$tvreport->scheduling($schedule_aref, $unscheduled_aref) ;

$this->prt_data("Schedule2=", $schedule_aref, "Unscheduled2=", $unscheduled_aref) if $this->debug >= 4 ;

		## If failed, then re-try allowing any to be adjacent
		if (@$unscheduled_aref)
		{
		my %sched_recordings ;
		my %req_recordings ;
		my %all_recordings ;
		
			## merge together existing schedule over to recording list (along with the requested recordings!) 
			## (This removes duplicates!)
			## NOTE: Using @resuested_recordings copy of recordings array BEFORE they have been merged into multiplex
			%sched_recordings = map { $_->{'pid'} => $_ } @$schedule_aref ;
			%req_recordings = map { $_->{'pid'} => $_ } @requested_recordings ;
			%all_recordings = (%sched_recordings, %req_recordings) ;
		
			# Move existing schedule over to recording list (along with the requested recordings!)
			@$recording_schedule_aref = values %all_recordings ;
			
			# clear out
			@$schedule_aref = () ;
			@$unscheduled_aref = () ;


			## If allowed, group into multiplex blocks
			if ($options{'enable_multirec'})
			{
				## Group new recordings into multiplex blocks
				$recording_schedule_aref = $this->de_multiplex($recording_schedule_aref) ;
				$recording_schedule_aref = $this->block_multiplex($recording_schedule_aref, %options) ;
		
				$this->_new_phase('multiplex rip-up') ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Multiplex recordings:", $recording_schedule_aref) if $this->debug ;
			}

#TODO: Only rip up from end to (just before?) failed one(s)
#      or just rip up region around failed ones?			

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Pre-P3 Recordings=", $recording_schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Pre-P3 Requested Recordings=", \@requested_recordings) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Pre-P3 Schedule=", $schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Pre-P3 Unscheduled=", $unscheduled_aref) if $this->debug >= 4 ;


			## 3: Attempt to redo whole schedule allow adjacent progs
			$this->_new_phase('rip up and retry allowing adjacent progs') ;
			$this->schedule($num_adapters, $recording_schedule_aref, $schedule_aref, $unscheduled_aref, 'adjacent' => 1) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P3 Recordings=", $recording_schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P3 Schedule=", $schedule_aref) if $this->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("P3 Unscheduled=", $unscheduled_aref) if $this->debug >= 4 ;


# TODO: If allowed, attempt recording using multiplex?
# TODO: If that fails, attempt multiplex recordings from just before failed one?

if ($this->debug >= 2)
{
print "\n==[ Phase 3 ]=============================================\n" ;
$tvreport->display_unschedule_by_adap($schedule_aref, $unscheduled_aref) ;
print "\n==========================================================\n" ;	
}
	
			# report
			$tvreport->scheduling($schedule_aref, $unscheduled_aref) ;
	
	$this->prt_data("Schedule3=", $schedule_aref, "Unscheduled3=", $unscheduled_aref) if $this->debug >= 4 ;
		}

	}

	## Need to propogate the DVB adapter down from the 'multiplex' container into each sub-prog
	$this->update_multiplex($schedule_aref) ;

	# update the array passed in 
	@$requested_rec_aref = @$recording_schedule_aref ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
	
	my $ok = scalar(@$unscheduled_aref) ? 0 : 1 ;
	return ($ok) ;	
}

#---------------------------------------------------------------------
# Remove any dummy "fuzzy" recordings
#
sub remove_dummies
{
	my $this = shift ;
	my ($recording_aref) = @_ ;

# TODO: Change scheduling to not schedule these in the first place!

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('remove dummies') ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

	my @removed ;
	foreach my $prog_href (@$recording_aref)
	{
		if ($prog_href->{'pid'} == $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::FUZZY_PID)
		{
			# delete 
		}
		else
		{
			push  @removed, $prog_href ;
		}
	}
	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
	
	return @removed ;
}


#---------------------------------------------------------------------
# Update cron jobs
#
sub update_cron
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('update cron') ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

	## Set cron
	Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::update($schedule_aref) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;

}

#---------------------------------------------------------------------
# Commit the final schedule (both to database and cron jobs)
#
sub commit
{
	my $this = shift ;
	my ($schedule_aref, $test) = @_ ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('commit') ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;


	## Set cron
	Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::commit() unless $test ;

	## Set database
	my $tvsql = $this->_tvsql ;
	$tvsql->update_schedule_table($schedule_aref) unless $test>=2 ;
	
	## Update recorded files
	unless ($test >= 2)
	{	
		my $recorded_files_href = Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::recorded_files() ;

print "Schedule: Update recorded table\n" if $this->debug ;

		## Check for exsistence of recrded entries
		foreach my $idx (sort {
				my $a_href = $recorded_files_href->{$a} ;
				my $b_href = $recorded_files_href->{$b} ;
				$a_href->{'start_dt_mins'} <=> $b_href->{'start_dt_mins'} || 
				$a_href->{'rid'} <=> $b_href->{'rid'} || 
				$a_href->{'rectype'} cmp $b_href->{'rectype'}
			}  keys %$recorded_files_href)
		{
print " + $recorded_files_href->{$idx}{pid} ($recorded_files_href->{$idx}{rectype}) $recorded_files_href->{$idx}{title}\n" if $this->debug ;

			my $exsisting_aref = $tvsql->select_recorded($recorded_files_href->{$idx}) ;
			
			## If not exsits, then create a new one
			if (!@$exsisting_aref)
			{
print " + + Does not exist : creating new\n" if $this->debug ;
				$tvsql->insert_recorded($recorded_files_href->{$idx}) ;	
			}
			else
			{
print " + + Exists : status=\"$exsisting_aref->[0]{'status'}\"\n" if $this->debug ;

				## Check status - if set then skip this (don't alter an existing result)
				if (!$exsisting_aref->[0]{'status'})
				{
print " + + + No status : amended details\n" if $this->debug ;
					## No status (i.e. not recorded yet), so amend details
					$tvsql->update_recorded($recorded_files_href->{$idx}) ;	
				}
			}
		}
	}


	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
}

#---------------------------------------------------------------------
# Remove any recordings matching this RID
# 
#
#Need to keep multiplex info, just remove prog from multiplex (and demote to prog if multiplex
#only holds a single prog). Otherwise the multirec table (Sql) is screwed.
#
sub unschedule
{
	my $this = shift ;
	my ($schedule_aref, $rid) = @_ ;

	my @sched = (@$schedule_aref) ;
	@$schedule_aref = () ;
	
	foreach my $href (@sched)
	{
		if ($href->{'type'} eq 'multiplex')
		{
			my @progs = @{$href->{'multiplex'}} ;
			$href->{'multiplex'} = [] ;
			foreach my $rec_href (@progs)
			{
				if ($rec_href->{'rid'} != $rid)
				{
					push @{$href->{'multiplex'}}, $rec_href ;
				}
			}
			
			# see how many progs are left inside the multiplex container
			if (scalar(@{$href->{'multiplex'}}) > 1)
			{
				# still got more than 1, so keep the multiplex
				push @$schedule_aref, $href ;
			}
			elsif (scalar(@{$href->{'multiplex'}}) > 0)
			{
				# only got 1 prog in multiplex, so just save that (delete multiplex)
				my $prog_href = $href->{'multiplex'}[0] ;
				push @$schedule_aref, $prog_href ;
				
				# Need to amend the prog to remove it from the multiplex
				$prog_href->{'multid'} = 0 ;
			}
		}
		else
		{
			if ($href->{'rid'} != $rid)
			{
				push @$schedule_aref, $href ;
			}
		}
	}
}

#---------------------------------------------------------------------
# Called by:
#	schedule_recordings()
#
# Input: 
#	$recording_schedule_aref - ARRAY ref of recording requests expanded
#								into schedule format and sorted by time
#
# Output:
#	$schedule_aref - ARRAY ref of scheduled recordings
#	$unscheduled_aref - ARRAY ref of any recordings not yet scheduled
# 
sub schedule
{
	my $this = shift ;
	my ($num_adapters, $recording_schedule_aref, $schedule_aref, $unscheduled_aref, %options) = @_ ;

print "\n -- schedule (adjacent=$options{adjacent}) --\n\n" if $this->debug ;	

	my $phase = $this->phase ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn("[PHASE: $phase] schedule") ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn("[PHASE: $phase]") ;

	# Sort recordings into order of date / priority
	my @recordings = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::prog_cmp($a, $b) } @$recording_schedule_aref ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Sorted recordings:", \@recordings) if $this->debug ;
	
	## Keep track of the DVB adapter
	my $default_adapter = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::index2adapter(0) ;
	my $adapter_idx = 0 ;
	
	# a schedule list per adapter - makes it quicker to search for overlaps
	my @adapter_schedule ;
	
	## Copy over any existing
	if (@$schedule_aref)
	{
		@$schedule_aref = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::prog_cmp($a, $b) } @$schedule_aref ;
		foreach my $prog_href (@$schedule_aref)
		{
			my $adap = $prog_href->{'adapter'} || $default_adapter ;
			my $adap_idx = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::adapter2index($adap) ;
			$adapter_schedule[$adap_idx] ||= [] ;
			push @{$adapter_schedule[$adap_idx]}, $prog_href ;

			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "copied existing") ;
		}
	}

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("copied any existing") ;

if ($this->debug)
{
	print "Existing schedule (Num PVR=$num_adapters):\n" ;
	for (my $adapter_num=0; $adapter_num < $num_adapters; ++$adapter_num)
	{
		my $adap = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::index2adapter($adapter_num) ;
		print "  [Adapter $adap]\n" ;
		foreach my $prog_href (@{$adapter_schedule[$adapter_num]})
		{
			print "    $prog_href->{title}  $prog_href->{date} $prog_href->{start} : start_dt_mins=$prog_href->{'start_dt_mins'}\n" ;	
		}
	}
	
	print "\n" ;	
}
	
		
	## Process the recordings
	@$unscheduled_aref = () ;
	foreach my $prog_href (@recordings)
	{
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, {
			'seen'	=> 1,	
		}) ;
		
		## try adding to current adapter schedule, otherwise cycle through the other adapters
		## and leave us pointing at either the one we managed to schedule the prog on, or the one we staretd
		## with
		my $scheduled = 0 ;
		for (my $adapter_num=0; !$scheduled && ($adapter_num < $num_adapters); ++$adapter_num)
		{
			my $adapter = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::index2adapter($adapter_idx) ;
			$adapter_schedule[$adapter_idx] ||= [] ;
			
			my $dvb = "dvb$adapter" ;

print "-> adapter=$adapter\n" if $this->debug ;	
			
			## check to see if we can add this to the current schedule
			if ($this->can_schedule($adapter_schedule[$adapter_idx], $prog_href))
			{
				Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "can schedule on $dvb") ;

				## iff required: only add if not adjacent
				if ($options{'adjacent'} || ! $this->prog_adjacent($adapter_schedule[$adapter_idx], $prog_href))
				{
					## add and set adapter
					$prog_href->{'adapter'} = $adapter ;
					push @{$adapter_schedule[$adapter_idx]}, $prog_href ;
					
					Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "** scheduled on $dvb **") ;

					++$scheduled ;
print " + + Scheduled onto adapter=$adapter!\n\n" if $this->debug ;	
				}
				else
				{
					Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "skipped adjacent on $dvb") ;
				}
			}
			else
			{
				Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "cannot schedule on $dvb") ;
			}
			
			if (!$scheduled)
			{		
				## next adapter
				$adapter_idx = ($adapter_idx+1) % $num_adapters ;

print " + + FAILED to schedule\n\n" if $this->debug ;	
			}
		}

		## if failed, add to unscheduled list
		if (!$scheduled)
		{
			## add to unscheduled list
			push @$unscheduled_aref, $prog_href ;
		}
	}

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("processed recordings") ;

if ($this->debug)
{
	print "Final schedule:\n" ;
	for (my $adapter_num=0; $adapter_num < $num_adapters; ++$adapter_num)
	{
		my $adap = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::index2adapter($adapter_num) ;
		print "  [Adapter $adap]\n" ;
		foreach my $prog_href (@{$adapter_schedule[$adapter_num]})
		{
			print "    $prog_href->{title}  $prog_href->{date} $prog_href->{start} : start_dt_mins=$prog_href->{'start_dt_mins'}\n" ;	
		}
	}
	
	print "\n" ;	
}
	
	
	## Create final schedule
	@$schedule_aref = () ;
	foreach (@adapter_schedule)
	{
		push @$schedule_aref, @$_ ;
	}
	
	# sort into date order
	@$schedule_aref = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @$schedule_aref ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("created final schedule") ;


print "\n -- schedule END --\n\n" if $this->debug ;	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
	
}



#---------------------------------------------------------------------
# Create a multiplex recording entry based on a single program
sub _new_multiplex
{
	my $this = shift ;
	my ($prog_href, $multid) = @_ ;
	
	my $mux_href = {
		%$prog_href,
		
		'type'			=> 'multiplex',
		'multiplex'		=> [ $prog_href ],
		'title'			=> 'Multiplex',
		'channel'		=> '(multiple)',
		'multid'		=> $multid,
	} ;

	return $mux_href ;	
}

#---------------------------------------------------------------------
# Input: 
#	$recording_schedule_aref - ARRAY ref of recording requests expanded
#								into schedule format and sorted by time
#
# Output:
#	$recording_schedule_aref - ARRAY ref of recording requests grouped
#								into multiplexes and sorted by time
# 
sub block_multiplex
{
	my $this = shift ;
	my ($recording_schedule_aref, %options) = @_ ;
	
	# used to track the multiplex record grouping (in sql) - i.e. which group a channel recording is in
	my $multid = $options{'multid'} || 1 ;

print "\n -- block_multiplex --\n\n" if $this->debug ;	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn("block_multiplex") ;

	# Sort recordings into order of date (ignore priority)
	my @recordings = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @$recording_schedule_aref ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Sorted recordings:", \@recordings) if $this->debug ;
	
		
	## Process each recording
	my $mux_recording_schedule_aref = [] ;
	return $mux_recording_schedule_aref unless @recordings ;
	
	do
	{
		## get this recording
		my $prog_href = shift @recordings ;

		#                                        timeslip
		#                   |-----------------|..............|
		#                     prog_href               |-------------------------|
		#                                               next_prog_href

		## get the TV channels that are in the same multiplex as this program
		my %multiplex_chans = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::multiplex_channels($prog_href->{'channel'}) ;
		my $end_mins = $prog_href->{'end_dt_mins'} ;
		my $priority = $prog_href->{'priority'} ;
		my $max_start = $end_mins + $options{'max_timeslip'} ;
		my $mux_locked = $prog_href->{'locked'} ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Looking at:", [$prog_href]) if $this->debug ;
print " * start_dt=$prog_href->{start_dt_mins} end_dt=$prog_href->{end_dt_mins} : max=$max_start\n" if $this->debug ;
print " * mux lock = $mux_locked\n" if $this->debug ;
$this->prt_data("Multiplex chans:", \%multiplex_chans) if $this->debug ;
		
		# Compare all subsequent recordings and compare with this one to see if they are in the same multiplex
		my @temp = @recordings ;
		@recordings = () ;
		my @multiplex ;
		foreach my $next_prog_href (@temp)
		{
			my $this_locked = $next_prog_href->{'locked'} ;
			
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched(" + sub prog:", [$next_prog_href]) if $this->debug >= 2 ;
print " * * start_dt=$next_prog_href->{start_dt_mins} end_dt=$next_prog_href->{end_dt_mins} : max=$max_start\n" if $this->debug >= 2;
print " * * locked = $this_locked\n" if $this->debug >= 2;

			# check within  "range" of first prog
			if ($next_prog_href->{'start_dt_mins'} > $max_start)
			{
				# nowt within range, so not in multiplex...
				push @recordings, $next_prog_href ;
print " + start > max\n" if $this->debug >= 2 ;
				next ;
			}
			
			# if the multiplex is locked (i.e. can't add any new items) then check that this new prog 
			# is also locked (i.e. part of the same mux)
			#
			# Actually 2 cases: 
			# 1. prog_href is part of locked mux and next prog is new
			# 2. prog_href is new and next prog is part of locked mux
			#
			# In either case we can't add them together into a mux
			#
			if ($mux_locked != $this_locked)
			{
				# can't add to the mux, so treat as normal prog
print " + + skip next prog due to lock mismatch (this=$mux_locked, next=$this_locked)\n" if $this->debug;
				push @recordings, $next_prog_href ;
				next ;
			}
			
			# see if in the same multiplex
			if (exists($multiplex_chans{$next_prog_href->{'channel'}}))
			{
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched(" + found mux:", [$next_prog_href]) if $this->debug ;
##print " + found mux\n" if $this->debug ;
				push @multiplex, $next_prog_href ;
				
				# update end time
				if ($end_mins < $next_prog_href->{'end_dt_mins'})
				{
					$end_mins = $next_prog_href->{'end_dt_mins'} ;
					$max_start = $end_mins + $options{'max_timeslip'} ;
print " * * * updated end: end_dt=$end_mins : max=$max_start\n" if $this->debug ;
				}
				
				# update priority
				if ($priority > $next_prog_href->{'priority'})
				{
					$priority = $next_prog_href->{'priority'} ;
				}

				next ;
			}
			
			
print " + normal\n" if $this->debug >= 2;
			push @recordings, $next_prog_href ;
		}
		
		# see if we have multiple entries
		if (@multiplex)
		{
			my $duration = $end_mins - $prog_href->{'start_dt_mins'} ;
			
			# create multiplex entry
			my $entry_href = $this->_new_multiplex($prog_href, $multid++) ;
			$entry_href->{'duration'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::mins2time($duration) ; ;
			$entry_href->{'priority'} = $priority ;
			push @{$entry_href->{'multiplex'}}, @multiplex ;

			Linux::DVB::DVBT::Apps::QuartzPVR::Prog::set_times($entry_href) ;
			push @$mux_recording_schedule_aref, $entry_href ;
			
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("final Multiplex:", [$entry_href]) if $this->debug ;
			
		}
		else
		{
			# simple single prog
			push @$mux_recording_schedule_aref, $prog_href ;
		}
		
	}
	while (@recordings) ;
	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("created mulriplex recordings") ;


print "\n -- schedule END --\n\n" if $this->debug ;	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Multiplex recs:", $mux_recording_schedule_aref) if $this->debug ;

	# sort into date order
	@$mux_recording_schedule_aref = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @$mux_recording_schedule_aref ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Sorted mulriplex recs:", $mux_recording_schedule_aref) if $this->debug ;
	
	return $mux_recording_schedule_aref ;
}


##---------------------------------------------------------------------
## Add new recordings to the existing set
##
## Input: 
##	$mux_recording_schedule_aref - ARRAY ref of recording requests grouped
##								into multiplexes and sorted by time
##
##	$mux_schedule_aref - ARRAY ref of existing schedule grouped
##								into multiplexes and sorted by time
##
## Output:
##	$mux_recording_schedule_aref - ARRAY ref of recording requests grouped
##								into multiplexes and sorted by time
## 
#sub schedule_block_multiplex
#{
#	my $this = shift ;
#	my ($mux_recording_schedule_aref, $mux_schedule_aref, %options) = @_ ;
#	
#	## get HASH of existing recordings and new recordings
#	my $demux_schedule_aref = $this->de_multiplex($schedule_aref) ;
#	my %sched_recordings = map { $_->{'pid'} => $_ } @$demux_schedule_aref ;
#	my %req_recordings = map { $_->{'pid'} => $_ } @$recording_schedule_aref ;
#
#	
#	return $mux_recording_schedule_aref ;
#}
#
#
##---------------------------------------------------------------------
## Remove any recordings that are duplicates
##
#sub remove_recording_duplicates
#{
#	my $this = shift ;
#	my ($recording_schedule_aref, $mux_schedule_aref) = @_ ;
#	
#	## get HASH of existing recordings and new recordings
#	my $demux_schedule_aref = $this->de_multiplex($schedule_aref) ;
#	my %sched_recordings = map { $_->{'pid'} => $_ } @$demux_schedule_aref ;
#	my %req_recordings = map { $_->{'pid'} => $_ } @$recording_schedule_aref ;
#	
#	## Strip out duplicates
#	my @recordings ;
#	foreach my $pid (keys %req_recordings)
#	{
#		if (!exists($sched_recordings{$pid}))
#		{
#			push @recordings, $req_recordings{$pid} ;
#		}
#	}
#	return \@recordings ;
#}
#
#		
#
##---------------------------------------------------------------------
## Get the next available multiplex id
## 
#sub next_multid
#{
#	my $this = shift ;
#	my ($schedule_aref) = @_ ;
#
#	my $next_multid = 0 ;
#	
#	foreach my $rec_href (@$schedule_aref)
#	{
#		if ($rec_href->{'type'} eq 'multiplex')
#		{
#			if ($next_multid < $rec_href->{'multid'})
#			{
#				$next_multid = $rec_href->{'multid'} ;
#			}
#		}
#	}
#	
#	return ++$next_multid ;
#}


#---------------------------------------------------------------------
# Mark any multiplex that is about to be recorded (or is being recorded) 
# as "locked". This then means we can't schedule recordings that will change 
# the multiplex.
#
# Adds the 'locked'=>1 field to multiplex AND the program
# 
sub mark_locked_recordings
{
	my $this = shift ;
	my ($recording_aref, $schedule_aref) = @_ ;

$this->prt_data("mark_locked_recordings() existing:", $schedule_aref) if $this->debug>=2 ;
	
	## First mark the schedule
	$this->lock_multiplexes($schedule_aref) ;
	
	## Get the list
	my $demux_schedule_aref = $this->de_multiplex($schedule_aref) ;
	my %sched_recordings = map { $_->{'pid'} => $_ } @$demux_schedule_aref ;
	my %req_recordings = map { $_->{'pid'} => $_ } @$recording_aref ;
	
	## Copy the locked flag to the recordings
	foreach my $pid (keys %req_recordings)
	{
		if (exists($sched_recordings{$pid}))
		{
			if ($sched_recordings{$pid}{'locked'})
			{
				$req_recordings{$pid}{'locked'} = 1 ;
			}
		}
	}
}

#---------------------------------------------------------------------
# Mark any multiplex that is about to be recorded (or is being recorded) 
# as "locked". This then means we can't schedule recordings that will change 
# the multiplex.
#
# Adds the 'locked'=>1 field to multiplex AND the program
# 
sub lock_multiplexes
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;
	
print "lock_multiplexes()\n" if $this->debug ;
#$this->prt_data("Schedule to lock:", $schedule_aref) if $this->debug>=2 ;
	
	# get current time with some margin
	#
	#	mux -----------| ok (s<C e<A)
	#	
	#	mux ---------------| lock (s<C e>A) - ending recording, can't change
	#	
	#	mux                 |--------------| lock (s<C e>A) - started recording, can't change
	#	
	#	mux                    |--------------| lock (s<C e>A) - imminent start, can't change
	#	
	#	mux                      |------------------| ok (s>=C e>A) - start far enough away to change
	#	
	#	now------------------^B
	#	 - margin  ......^A	
	#	 + margin  .............^C	
	#
	#
	my $today_mins = $this->today_mins ;
	my $MARGIN = 5 ;
	my $min_time = $today_mins - $MARGIN ;
	my $max_time = $today_mins + $MARGIN ;

print " * now=$today_mins (-margin=$min_time, +margin=$max_time)\n" if $this->debug ;
	
	# check each multiplex compared with the current time
	foreach my $rec_href (@$schedule_aref)
	{
print " + $rec_href->{'title'}\n" if $this->debug ;
		if ($rec_href->{'type'} eq 'multiplex')
		{
print " + mux start=$rec_href->{'start_dt_mins'}, end=$rec_href->{'end_dt_mins'}\n" if $this->debug ;

			# see if this is locked
			my $locked = 0 ;
			if ( ($rec_href->{'start_dt_mins'} < $max_time) && ($rec_href->{'end_dt_mins'} >= $min_time) ) 
			{
				++$locked ;
print " + + locked\n" if $this->debug ;
			}
			
			if ($locked)
			{
				$rec_href->{'locked'} = 1 ;
				foreach my $mux_href (@{$rec_href->{'multiplex'}})
				{
					$mux_href->{'locked'} = 1 ;
				}
			}
		}
	}
	
#$this->prt_data("Schedule locked:", $schedule_aref) if $this->debug>=2 ;
print "lock_multiplexes() - DONE\n" if $this->debug ;
	
}



#---------------------------------------------------------------------
# Input: 
#	$schedule_aref - ARRAY ref of scheduled recordings (with any multiplex recordings)
#
# Output:
#	$schedule_aref - ARRAY ref of scheduled recordings (without any multiplex recordings)
# 
sub de_multiplex
{
	my $this = shift ;
	my ($schedule_aref, %options) = @_ ;
	my $demux_aref = [] ;
	
	foreach my $rec_href (@$schedule_aref)
	{
		if ($rec_href->{'type'} eq 'multiplex')
		{
			push @$demux_aref, @{$rec_href->{'multiplex'}} ;
		}
		else
		{
			push @$demux_aref, $rec_href ;
		}
	}
	
	return $demux_aref ;
}


#---------------------------------------------------------------------
# Input: 
#	$schedule_aref - ARRAY ref of schedule format
#
# Propogates the DVB adapter number & the multiplex ID down into all progs contained
# in a multiplex recording
#
sub update_multiplex
{
	my $this = shift ;
	my ($schedule_aref, %options) = @_ ;

	my @FIELDS = qw/multid adapter timeslip/ ;
	
	foreach my $rec_href (@$schedule_aref)
	{
		# ensure defaults are set
		foreach my $field (@FIELDS)
		{
			$rec_href->{$field} ||= 0 ;
		}
		
		# propogate from top-level multiplex container down to the individual programs
		if ($rec_href->{'type'} eq 'multiplex')
		{
			foreach my $mux_href (@{$rec_href->{'multiplex'}})
			{
				foreach my $field (@FIELDS)
				{
					$mux_href->{$field} = $rec_href->{$field} ;
				}
			}
		}
	}
}

#---------------------------------------------------------------------
# Input: 
#	$schedule_aref - ARRAY ref in schedule format (read from SQL table)
#
# Output: 
#	$schedule_aref - ARRAY ref of schedule format (with multiplex recordings fixed)
#
#
sub fix_multiplex
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;
	
	my @mux_schedule = () ;
	my %multiplex ;

	foreach my $rec_href (@$schedule_aref)
	{
		my $multid = $rec_href->{'multid'} ;
		if ($multid > 0)
		{
			# create new entry if required
			if (!exists($multiplex{$multid}))
			{
				# create new multiplex entry based on this prog's info
				my $mux_href = $this->_new_multiplex($rec_href, $multid) ;
				push @mux_schedule, $mux_href ;
				
				$multiplex{$multid} = $mux_href ;
			}
			else
			{
				# get multiplex & update the start/end/duration/priority based on this new prog 
				my $mux_href = $multiplex{$multid} ;
				push @{$mux_href->{'multiplex'}}, $rec_href ;
				
				if ($mux_href->{'start_dt_mins'} > $rec_href->{'start_dt_mins'})
				{
					$mux_href->{'date'} = $rec_href->{'date'} ;
					$mux_href->{'start'} = $rec_href->{'start'} ;
					$mux_href->{'start_dt_mins'} = $rec_href->{'start_dt_mins'} ;
				}
				$mux_href->{'end_dt_mins'} = $rec_href->{'end_dt_mins'} if ($mux_href->{'end_dt_mins'} < $rec_href->{'end_dt_mins'}) ;
				$mux_href->{'priority'} = $rec_href->{'priority'} if ($mux_href->{'priority'} > $rec_href->{'priority'}) ;

			}
		}
		else
		{
			push @mux_schedule, $rec_href ;
		}
	}


	## Now ensure all multiplex times/durations etc are correct
	foreach my $rec_href (@mux_schedule)
	{
		if ($rec_href->{'type'} eq 'multiplex')
		{
			my $duration = $rec_href->{'end_dt_mins'} - $rec_href->{'start_dt_mins'} ;
			$rec_href->{'duration'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::mins2time($duration) ;
			Linux::DVB::DVBT::Apps::QuartzPVR::Prog::set_times($rec_href) ;
		}
	}
	
	return @mux_schedule ;
}

#---------------------------------------------------------------------
# Replace all rids set to NEW_RID with the specified new value
#
sub update_rid
{
	my $this = shift ;
	my ($new_rid, $schedule_aref) = @_ ;
	
	foreach my $href (@$schedule_aref)
	{
		my @progs = ($href) ;
		if ($href->{'type'} eq 'multiplex')
		{
			@progs = @{$href->{'multiplex'}} ;
		}
		foreach my $rec_href (@progs)
		{
			if ($rec_href->{'rid'} == $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::NEW_RID)
			{
				$rec_href->{'rid'} = $new_rid ;
			}
		}
	}
}

#---------------------------------------------------------------------
# Check the schedule list for overlapped programs.  
# Assumes the other programs are non-overlapping and checks to ensure 
# that this new one doesn't interfere with existing ones. Also assumes
# that the schedule list is for the same DVB adapter
#
sub can_schedule
{
	my $this = shift ;
	my ($schedule_aref, $prog_href) = @_ ;

print "can_sched($prog_href->{title}  $prog_href->{date} $prog_href->{start})\n" if $this->debug ;			
	
	my $ok = 1 ;
	
	# Start with the new entry, moving through the schedule list to see if it overlaps 

	# For each entry, need to check 
	# (a) it starts AFTER the end of the previous program
	#
	#  (prev)  end
	#  ----------|
	#      ^
	#      |---------------.....
	#     start   (current)
	#
	#
	# (b) it ends BEFORE the start of the next program
	#
	#                     start (next)
	#                       |--------....
	#                          ^
	#      |-------------------|
	#     start   (current)   end
	#
	#
	# NOTE: May we have:
	#
	#   start                                           end
	#    |-----------------------------------------------|
	#               |----------------|
	#              start (current)  end
	#
	# Easiest approach is to create a temporary sorted list, then just look at the new program and see if it overlaps
	#
	#

	# add new to list
	my $num_entries ;
	my $new_index ;
	my @new_list = $this->_insert_prog($schedule_aref, $prog_href, \$num_entries, \$new_index) ;

	# check for overlap
	if ($new_index > 0)
	{
		# check new start is AFTER previous end
		if ($new_list[$new_index]{'start_dt_mins'} < $new_list[$new_index-1]{'end_dt_mins'})
		{
			$ok = 0 ;
print " + new prog start is not AFTER prev end  ($new_list[$new_index-1]{'title'} $new_list[$new_index-1]{'start'} - $new_list[$new_index-1]{'end'})\n" if $this->debug ;	
			my $other = Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::format_rec($new_list[$new_index-1]) ;		
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "can't schedule: new prog start is not AFTER prev end [Prev: $other]") ;
		}
	}

	# if not the last one
	if ($new_index < $num_entries-1)
	{
		# check new end is BEFORE next start
		if ($new_list[$new_index]{'end_dt_mins'} > $new_list[$new_index+1]{'start_dt_mins'})
		{
			$ok = 0 ;
print " + new prog end is not BEFORE next start ($new_list[$new_index+1]{'title'} $new_list[$new_index+1]{'start'} - $new_list[$new_index+1]{'end'})\n" if $this->debug ;			
			my $other = Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::format_rec($new_list[$new_index+1]) ;		
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "can't schedule: new prog end is not BEFORE next start [Next: $other]") ;
		}
	}
		
print " + can sched=$ok\n" if $this->debug ;			

	return $ok ;
}

#---------------------------------------------------------------------
# Returns true if new program is adjacent to previous or next program
#
sub prog_adjacent
{
	my $this = shift ;
	my ($schedule_aref, $prog_href) = @_ ;

print "prog_adjacent($prog_href->{title}  $prog_href->{date} $prog_href->{start})\n" if $this->debug ;			

	my $adjacent = 0 ;

	# add new to list
	my $num_entries ;
	my $new_index ;
	my @new_list = $this->_insert_prog($schedule_aref, $prog_href, \$num_entries, \$new_index) ;

	# check for adjacent to prev
	if ($new_index > 0)
	{
		# check new start is ADJACENT previous end
		if ($new_list[$new_index]{'start_dt_mins'} == $new_list[$new_index-1]{'end_dt_mins'})
		{
			$adjacent = 1 ;
print " + new prog start is ADJACENT prev end ($new_list[$new_index-1]{'title'} $new_list[$new_index-1]{'start'} - $new_list[$new_index-1]{'end'})\n" if $this->debug ;			
			my $other = Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::format_rec($new_list[$new_index-1]) ;		
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "new prog start is ADJACENT to prev end [Next: $other]") ;
		}
	}

	# if not the last one
	if ($new_index < $num_entries-1)
	{
		# check new end is ADJACENT next start
		if ($new_list[$new_index]{'end_dt_mins'} == $new_list[$new_index+1]{'start_dt_mins'})
		{
			$adjacent = 1 ;
print " + new prog end is ADJACENT next start ($new_list[$new_index+1]{'title'} $new_list[$new_index+1]{'start'} - $new_list[$new_index+1]{'end'})\n" if $this->debug ;			
			my $other = Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::format_rec($new_list[$new_index+1]) ;		
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($prog_href, "new prog end is ADJACENT to next start [Next: $other]") ;
		}
	}
		
print " + adjacent=$adjacent\n" if $this->debug ;			

	return $adjacent ;
}


#---------------------------------------------------------------------
sub _insert_prog
{
	my $this = shift ;
	my ($schedule_aref, $prog_href, $num_entries_ref, $new_index_ref) = @_ ;

print "_insert_prog($prog_href->{title}  $prog_href->{date} $prog_href->{start})\n" if $this->debug ;			

	# add new to list
	my %new_entry = (%$prog_href) ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Prog::set_times(\%new_entry) ;
	my @new_list = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } (@$schedule_aref, \%new_entry) ;
	
	# find new
	$$num_entries_ref = scalar(@new_list) ;
	for(my $i=0; $i<$$num_entries_ref; ++$i)
	{
		if ($new_list[$i]{'pid'} == $prog_href->{'pid'})
		{
			$$new_index_ref = $i ;
			last ;
		}
	}
print " - num entries=$$num_entries_ref, new index=$$new_index_ref\n" if $this->debug ;			

	return @new_list ;	
}

#---------------------------------------------------------------------
# Start a new scheduling phase
sub _new_phase
{
	my $this = shift ;
	my ($phase) = @_ ;

	## save phase for tracing
	$this->phase($phase) ;
	
	## set report
	my $tvreport = $this->_tvreport ;
	$tvreport->new_phase($phase) ;
}

#---------------------------------------------------------------------
# filter out any recordings that are IPLAY only (they get handled elsewhere)
#
sub filter_dvbt
{
	my $this = shift ;
	my ($recording_schedule_aref) = @_ ;

	my @dvbt_recordings = () ;
	foreach my $prog_href (@$recording_schedule_aref)
	{
		if ($prog_href->{'type'} eq 'multiplex')
		{
			my @progs = @{$prog_href->{'multiplex'}} ;
			@{$prog_href->{'multiplex'}} = () ;
			foreach my $href (@progs)
			{
				if (!Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_dvbt($href->{'record'}))
				{
					# skip anything that doesn't have DVBT
					next
				}
				push @{$prog_href->{'multiplex'}}, $href ;
			}
			
			# save multiplex if multiplex actually contains something
			if (@{$prog_href->{'multiplex'}})
			{
				push @dvbt_recordings, $prog_href ;
			}
		}
		else
		{
			if (!Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_dvbt($prog_href->{'record'}))
			{
				# skip anything that doesn't have DVBT
				next
			}
			push @dvbt_recordings, $prog_href ;
		}

	}
	return @dvbt_recordings ;
}


#============================================================================================
# DEBUG
#============================================================================================
#



# ============================================================================================
# END OF PACKAGE
1;

__END__


