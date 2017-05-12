package Linux::DVB::DVBT::Apps::QuartzPVR::Report ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Report - Write report of new scheduling

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

our $VERSION = "1.004" ;

#============================================================================================
# USES
#============================================================================================
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Crontab ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object) ; 

#============================================================================================
# GLOBALS
#============================================================================================

my %FIELDS = (
	'_report'		=> {
		'recspec'		=> "",
		'devices'		=> [],
		'recordings'	=> [],
		'phases'		=> [],
		'scheduling'	=> {
		},
		'cron'	=> [],
	},
) ;


## split schedule diagram up into chunks of approx this maximum width
my $MAX_SCHED_WIDTH = 80 ;

my $EXTRA_INFO = 1 ;


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
# Save devices
sub devices
{
	my $this = shift ;
	my ($devices_aref) = @_ ;

	my $report_href = $this->_report ;
	$report_href->{'devices'} = [ @$devices_aref ] ;
}

#---------------------------------------------------------------------
# Save recspec
sub recspec
{
	my $this = shift ;
	my ($recspec) = @_ ;

	my $report_href = $this->_report ;
	$report_href->{'recspec'} = $recspec ;
}

#---------------------------------------------------------------------
# Save initial recordings 
sub recordings
{
	my $this = shift ;
	my ($recording_aref) = @_ ;

	my $report_href = $this->_report ;
#	$report_href->{'recordings'} = [ @$recording_aref ] ;
	push @{$report_href->{'recordings'}}, @$recording_aref ;
}

#---------------------------------------------------------------------
# Start a new scheduling phase
sub new_phase
{
	my $this = shift ;
	my ($phase) = @_ ;

	my $report_href = $this->_report ;
	push @{$report_href->{'phases'}}, $phase ;
	
	$report_href->{'scheduling'}{$phase} = {
		'performed'		=> 0,
		'schedule'		=> [],
		'unscheduled'	=> [],
	} ;
	
}

#---------------------------------------------------------------------
# Save scheduling
sub scheduling
{
	my $this = shift ;
	my ($schedule_aref, $unschedule_aref) = @_ ;

	my $report_href = $this->_report ;
	if (scalar(@{$report_href->{'phases'}}))
	{
		## get current phase
		my $phase = $report_href->{'phases'}[-1] ;
		
		## save scheduling info
		$report_href->{'scheduling'}{$phase}{'performed'} = 1 ;
		$report_href->{'scheduling'}{$phase}{'schedule'} = [ @$schedule_aref ] if $schedule_aref ;
		$report_href->{'scheduling'}{$phase}{'unscheduled'} = [ @$unschedule_aref ] if $unschedule_aref ;
	}
}

#---------------------------------------------------------------------
# Save scheduling
sub cron
{
	my $this = shift ;
	my (@cron_jobs) = @_ ;

	my $report_href = $this->_report ;
	$report_href->{'cron'} = \@cron_jobs ;
}

#---------------------------------------------------------------------
# Create text for this entry
sub report_prog_entry
{
	my $this = shift ;
	my ($prog_href) = @_ ;
	
	my $text = "" ;
	$text .= sprintf "RID %3d : ", $prog_href->{'rid'} ;
	$text .= "$prog_href->{channel} '$prog_href->{title}' " ;
	$text .= "$prog_href->{date} $prog_href->{start} - $prog_href->{end} " ;
	$text .= "[$prog_href->{record}::"
		.Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_group($prog_href->{record})
		.":"
		.Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types($prog_href->{record})
		."] " ;
	if (defined($prog_href->{'adapter'}))
	{
		$text .= ": DVB$prog_href->{'adapter'}" ;
	}
	$text .= ": Priority $prog_href->{priority} " ;
	$text .= ": PID $prog_href->{pid} " ;
	
	if ($EXTRA_INFO)
	{
		if (exists($prog_href->{'timeslip'}))
		{
			$text .= sprintf ": Timeslip %d ", $prog_href->{'timeslip'} ;
		}
		$text .= "< " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'start_datetime'}) . " - " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'end_datetime'}) . " > " ;
	}
	
	return $text ;
}

#---------------------------------------------------------------------
# Create list of text lines for this list of programs
sub report_prog_list
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;
	my @lines ;
	
	my @sorted = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @$schedule_aref ;

	my $prev_end_dt_mins = undef ;
#my $prev_end_dt ;
	
	# RID 217 : ITV1 'Midsomer Murders' Wednesday 11th Feb [weekly]
	foreach my $prog_href (@sorted)
	{
		if ($EXTRA_INFO)
		{
#print "\nGAP? prog=".Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2date($prog_href->{'start_datetime'})." - ".Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2date($prog_href->{'end_datetime'})."\n" ;
			if ($prev_end_dt_mins)
			{
				my $start_dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($prog_href->{'start_datetime'}) ;
#print "GAP? prev=".Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prev_end_dt)." ($prev_end_dt_mins), start=".Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'start_datetime'})." ($start_dt_mins), diff=".($prev_end_dt_mins - $start_dt_mins)."\n" ;
				if ( ($start_dt_mins - $prev_end_dt_mins) >= 30)
				{
					push @lines, "..." ;
#print " + GAP FOUND\n" ;
				}
			}
			$prev_end_dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($prog_href->{'end_datetime'}) ;
#$prev_end_dt = $prog_href->{'end_datetime'} ;
		}
		
		if ($prog_href->{'type'} eq 'multiplex')
		{
			my $text = ",--[ Multiplex ($prog_href->{multid}) ]--------------------------" ;
			$text .= " : $prog_href->{date} $prog_href->{start} - $prog_href->{end} " ;
			if ($EXTRA_INFO)
			{
				if (exists($prog_href->{'timeslip'}))
				{
					$text .= sprintf ": Timeslip %d ", $prog_href->{'timeslip'} ;
				}
				$text .= "< " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'start_datetime'}) . " - " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($prog_href->{'end_datetime'}) . " > " ;
			}
			
			push @lines, $text ;
			
			foreach my $mux_prog_href (@{$prog_href->{'multiplex'}})
			{
				my $text = $this->report_prog_entry($mux_prog_href) ;
				push @lines, "| $text" ;	
			}
			push @lines, "'-----------------------------------------" ;
		}
		else
		{
			my $text = $this->report_prog_entry($prog_href) ;
			push @lines, "  $text" ;	
		}
	}
	
	return @lines ;
}

#---------------------------------------------------------------------
# Scheduling
sub scheduling_lines
{
	my $this = shift ;
	
	my ($schedule_lines, $final_schedule_aref, $final_unscheduled_aref) = ("", [], []);
	
	my $report_href = $this->_report ;

	## phases
	my $phase_num = 1 ;
	foreach my $phase (@{$report_href->{'phases'}})
	{
		$final_schedule_aref = $report_href->{'scheduling'}{$phase}{'schedule'} ;
		$final_unscheduled_aref = $report_href->{'scheduling'}{$phase}{'unscheduled'} ;
		
		my @lines = $this->report_prog_list($report_href->{'scheduling'}{$phase}{'schedule'}) ;
		my ($phase_schedule_lines, $phase_unscheduled_lines) = ("", "") ;
		
		foreach (@lines)
		{
			$phase_schedule_lines .= "			$_\n" ;
		}
		$phase_schedule_lines ||= "			(NONE)\n" ;
	
		@lines = $this->report_prog_list($report_href->{'scheduling'}{$phase}{'unscheduled'}) ;
		foreach (@lines)
		{
			$phase_unscheduled_lines .= "			$_\n" ;
		}
		$phase_unscheduled_lines ||= "			(NONE)\n" ;
		
		my $lines =<<PHASE ;

	PHASE$phase_num - $phase

		Schedule:
		
$phase_schedule_lines

		Un-Scheduled:
		
$phase_unscheduled_lines


PHASE
	
		$schedule_lines .= $lines ;
		++$phase_num ;
	}

	return ($schedule_lines, $final_schedule_aref, $final_unscheduled_aref) ;
}


#---------------------------------------------------------------------
# Scheduling per adapter
sub scheduling_dvb_lines
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;
	
	my ($schedule_dvb_lines) = "" ;
	

	## Build HASH based on adapter
	my %sched ;
	foreach my $sched_href (@$schedule_aref)
	{
		my $adap = $sched_href->{'adapter'} ;
		
		$sched{$adap} ||= [] ;
		push @{$sched{$adap}}, $sched_href ;
	}
	
	## display each
	foreach my $adap (sort {$a <=> $b} keys %sched)
	{
#print "\nscheduling_dvb_lines(DVB $adap)\n" ;
		
		$schedule_dvb_lines .= "==[ DVB$adap ]==\n\n" ;
		my @lines = $this->report_prog_list($sched{$adap}) ;
		$schedule_dvb_lines .= "    " . join "\n    ", @lines ;
		$schedule_dvb_lines .= "\n\n" ;
	}

#print "\nscheduling_dvb_lines() - END\n" ;

	return $schedule_dvb_lines ;
}




#---------------------------------------------------------------------
# Create text report
sub create_report
{
	my $this = shift ;
	my ($report_href) = $this->_report ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $date = sprintf "%02d/%02d/%04d", $mday,$mon+1,$year+1900;
	my $time = sprintf "%02d:%02d:%02d", $hour,$min,$sec;

	my ($devices_lines, $recordings_lines) = ("", "");
	my ($schedule_by_chan_lines, $schedule_by_adap_lines) = ("", "");
	
	## recspec (if set)
	my $recspec_lines = "" ;
	if ($report_href->{'recspec'})
	{
		$recspec_lines .= <<RECSPECLINES ;

RECSPEC
=======
"$report_href->{'recspec'}"

RECSPECLINES
	}
	
	## cron
	my $cron_lines = Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::block_lines() ;
	
	## devices
	foreach my $dev_href (@{$report_href->{'devices'}})
	{
		$devices_lines .= "DVB$dev_href->{'adapter_num'}:$dev_href->{'frontend_num'} : $dev_href->{'name'} [ $dev_href->{'device'} ]\n" ;
	}
	
	## recordings
	my @lines = $this->report_prog_list($report_href->{'recordings'}) ;
	foreach (@lines)
	{
		$recordings_lines .= "$_\n" ;
	}

	## phases
	my ($schedule_lines, $final_schedule_aref, $final_unscheduled_aref) = $this->scheduling_lines() ;

	## Final
	my $unscheduled_lines = "" ;
	@lines = $this->report_prog_list($final_unscheduled_aref) ;
	foreach (@lines)
	{
		$unscheduled_lines .= "$_\n" ;
	}
	$unscheduled_lines ||= "(NONE)\n" ;
	
	@lines = $this->format_schedule_by_chan($final_schedule_aref) ;
	foreach (@lines)
	{
		$schedule_by_chan_lines .= "$_\n" ;
	}
	
	if (@$final_unscheduled_aref)
	{
		@lines = $this->format_unschedule_by_adap($final_schedule_aref, $final_unscheduled_aref) ;
	}
	else
	{
		@lines = $this->format_schedule_by_adap($final_schedule_aref) ;
	}
	foreach (@lines)
	{
		$schedule_by_adap_lines .= "$_\n" ;
	}
	
	# schedule per adapter
	my $schedule_dvb_lines = $this->scheduling_dvb_lines($final_schedule_aref) ;

	my $report = <<REPORT ;
DVB SCHEDULE REPORT $date $time
########################################
$recspec_lines
UN-SCHEDULED
============

$unscheduled_lines

DEVICES
=======

$devices_lines

RECORDINGS
==========

$recordings_lines

SCHEDULING
==========

$schedule_lines

CRON JOBS
=========

$cron_lines

SCHEDULE PER DVB
================

$schedule_dvb_lines

REPORT


	if (Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_flag() )
	{
		$report .= "DEBUG TRACE\n" ;
		$report .= "===========\n\n" ;
			
		## Print trace (if required)
		$report .= Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::create_trace_report() ;
	}

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;

	return $report ;
}


#---------------------------------------------------------------------
# Create text report
sub print_report
{
	my $this = shift ;

	my $report = $this->create_report() ;
	print $report ; 
}



#=================================================================================
# SCHEDULE DISPLAY
#=================================================================================

# Want something like:
#

#       BBC1        BBC1              BBC1                BBC1      BBC1
#       prog1       prog2             prog3               prog4     prog5
#       22/01/2009  22/01/2009        22/01/2009          22/01/200922/01/2009 
#		17:00       18:00             20:00               21:00     22:00      
#BBC1	|-----------|---------|       |--------------|    |---------|----------|
#               18:00     19:00                  20:45          22:00      23:00
#

# i.e. 8 lines per "thing":
#
# [0] channel
# [1] program title
# [2] start date
# [3] start time
# [4] timeline
# [5] end time
# [6] adapter
# [7] blank


#---------------------------------------------------------------------
sub format_schedule
{
	my $this = shift ;
	my ($title, $start_mins, $schedule_aref) = @_ ;

print "format_schedule($title) start=$start_mins\n" if $this->debug ;

	my @headings = () ;
	my @lines = () ;

	## Sort by start
	my @sorted = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @$schedule_aref ;

	## Some contants
	my $TITLE_LEN = 20 ;
	my $PER_MIN = 1 ;
	
	my $INDEX_CHAN = 0 ;
	my $INDEX_PROG = 1 ;
	my $INDEX_DATE = 2 ;
	my $INDEX_START = 3 ;
	my $INDEX_TIMELINE = 4 ;
	my $INDEX_ADAPTER = 5 ;
	my $INDEX_END = 6 ;
	
	## Start with padding for title
	foreach (my $i=0; $i <= $INDEX_END; ++$i)
	{
		$headings[$i] = " "x$TITLE_LEN ;
	}
	foreach (my $i=0; $i <= $INDEX_END; ++$i)
	{
		$lines[$i] = "" ;
	}
	
	$headings[$INDEX_TIMELINE] = sprintf("%-*s", $TITLE_LEN, $title) ;
	
	## Process the schedule
	my $prev_href = {
		'end_dt_mins' => $start_mins,
	};
	foreach my $sched_href (@sorted)
	{
		# See how long it's for
		my $block_width = $sched_href->{'duration_secs'} / 60 * $PER_MIN ;
		# halve width
		$block_width /= 2 ;
		my $timeline = "|" . ("-" x ($block_width-2)) . "|" ;
		
		if ($prev_href)
		{
			my $diff_mins = $sched_href->{'start_dt_mins'} - $prev_href->{'end_dt_mins'} ;

			if ($diff_mins)
			{
				# need a spacer
				my $space_width = $diff_mins * $PER_MIN ;
				$space_width /= 2 ;
				foreach my $line (@lines)
				{
					$line .= " "x$space_width ;
				}
			}
			else
			{
				# tack timeline onto end of previous
				$timeline = ("-" x ($block_width-1)) . "|" ;
			}
		}

if ($this->debug)
{
	my $col = length $lines[$INDEX_CHAN] ;
	my $col2 = length $lines[$INDEX_DATE] ;
	print " + \"$sched_href->{title}\" $sched_href->{'date'} $sched_href->{'start'} : $sched_href->{'start_dt_mins'} : col $col ($col2)\n"  ;
}		
		
		$lines[$INDEX_CHAN] 	.= sprintf("%-*.*s", $block_width, $block_width, $sched_href->{'channel'}) ;
		$lines[$INDEX_PROG] 	.= sprintf("%-*.*s", $block_width, $block_width, $sched_href->{'title'}) ;
		$lines[$INDEX_DATE] 	.= sprintf("%-*.*s", $block_width, $block_width, $sched_href->{'date'}) ;
		$lines[$INDEX_START] 	.= sprintf("%-*.*s", $block_width, $block_width, $sched_href->{'start'}) ;
		$lines[$INDEX_ADAPTER] 	.= sprintf("%-*.*s", $block_width, $block_width, "DVB$sched_href->{'adapter'}" ) ;

		$lines[$INDEX_END] 		.= sprintf("%*.*s", $block_width, $block_width, $sched_href->{'end'}) ;
		
		$lines[$INDEX_TIMELINE] .= $timeline ;
		
		## save for next time
		$prev_href = $sched_href ;
	}
	
	return (\@headings, \@lines) ;
}

#---------------------------------------------------------------------
# Blanks replacement string
sub blanks_replace
{
	my $this = shift ;
#	my $replace = " ... " ;
	my $replace = "   ~   " ;

	return $replace ;
}

#---------------------------------------------------------------------
sub format_schedule_by_chan
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;

print "format_schedule_by_chan()\n" if $this->debug ;
	
	my %sched ;
	my $start_mins ;
	foreach my $sched_href (@$schedule_aref)
	{
		my $chan = $sched_href->{'channel'} ;
		$start_mins = $sched_href->{'start_dt_mins'} if !defined($start_mins) ;
		$start_mins = $sched_href->{'start_dt_mins'} if $start_mins > $sched_href->{'start_dt_mins'} ;
		
		$sched{$chan} ||= [] ;
		push @{$sched{$chan}}, $sched_href ;
	}
	
	## display each
	my @blanks ;
	my @headings ;
	my @lines ;
	foreach my $chan (sort keys %sched)
	{
		my ($head_aref, $lines_aref) = $this->format_schedule($chan, $start_mins, $sched{$chan}) ;
		push @lines, @$lines_aref ;
		push @headings, @$head_aref ;
		$this->find_blanks($lines_aref, \@blanks) ;
	}
	
	## Strip blanks
	$this->format_blanks(\@lines, \@blanks, 22) ;

	## format into multiple blocks if the width is too large
	my @final_lines = $this->format_blocks(\@headings, \@lines) ;

	return @final_lines ;
}

#---------------------------------------------------------------------
sub format_schedule_by_adap
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;

print "format_schedule_by_adap()\n" if $this->debug ;
	
	## Build HASH based on adapter
	my %sched ;
	my $start_mins ;
	foreach my $sched_href (@$schedule_aref)
	{
		my $adap = $sched_href->{'adapter'} ;
		$start_mins = $sched_href->{'start_dt_mins'} if !defined($start_mins) ;
		$start_mins = $sched_href->{'start_dt_mins'} if $start_mins > $sched_href->{'start_dt_mins'} ;
		
		$sched{$adap} ||= [] ;
		push @{$sched{$adap}}, $sched_href ;
	}
	
	## display each
	my @blanks ;
	my @headings ;
	my @lines ;
	foreach my $adap (sort {$a <=> $b} keys %sched)
	{
		my ($head_aref, $lines_aref) = $this->format_schedule("DVB$adap", $start_mins, $sched{$adap}) ;
		push @lines, @$lines_aref ;
		push @headings, @$head_aref ;
		$this->find_blanks($lines_aref, \@blanks) ;
	}
	
	## Strip blanks
	$this->format_blanks(\@lines, \@blanks, 22) ;
	
	## format into multiple blocks if the width is too large
	my @final_lines = $this->format_blocks(\@headings, \@lines) ;

	return @final_lines ;
}

#---------------------------------------------------------------------
sub format_unschedule_by_adap
{
	my $this = shift ;
	my ($schedule_aref, $unschedule_aref) = @_ ;

print "format_unschedule_by_adap()\n" if $this->debug ;
	
	## Build HASH based on adapter
	my %sched ;
	my $start_mins ;
	foreach my $sched_href (@$schedule_aref)
	{
		my $adap = $sched_href->{'adapter'} ;
		$start_mins = $sched_href->{'start_dt_mins'} if !defined($start_mins) ;
		$start_mins = $sched_href->{'start_dt_mins'} if $start_mins > $sched_href->{'start_dt_mins'} ;
		
		my $key = "DVB$adap" ;
		$sched{$key} ||= [] ;
		push @{$sched{$key}}, $sched_href ;
	}
	foreach my $sched_href (@$unschedule_aref)
	{
		$start_mins = $sched_href->{'start_dt_mins'} if !defined($start_mins) ;
		$start_mins = $sched_href->{'start_dt_mins'} if $start_mins > $sched_href->{'start_dt_mins'} ;
		
		my $key = "UNSCHED" ;
		$sched{$key} ||= [] ;
		push @{$sched{$key}}, $sched_href ;
	}
	
	## display each
	my @blanks ;
	my @headings ;
	my @lines ;
	foreach my $key (sort {$a <=> $b} keys %sched)
	{
		my ($head_aref, $lines_aref) = $this->format_schedule($key, $start_mins, $sched{$key}) ;
		push @lines, @$lines_aref ;
		push @headings, @$head_aref ;
		$this->find_blanks($lines_aref, \@blanks) ;
	}
	
	## Strip blanks
	$this->format_blanks(\@lines, \@blanks, 22) ;
	
	## format into multiple blocks if the width is too large
	my @final_lines = $this->format_blocks(\@headings, \@lines) ;

	return @final_lines ;
}


#---------------------------------------------------------------------
# create an array each element being TRUE if the line char is a space;
# FALSE otherwise. Accumulates information over all lines
sub find_blanks
{
	my $this = shift ;
	my ($lines_aref, $blanks_aref) = @_ ;

print "find_blanks()\n" if $this->debug >= 5 ;

	my $blanks_len = @$blanks_aref ;
	foreach my $line (@$lines_aref)
	{
	print " + line  : \"$line\"\n" if $this->debug >= 5 ;
		$line =~ s/\S/0/g ;
		$line =~ s/\s/1/g ;
	
	print " + line b: \"$line\"\n" if $this->debug >= 5 ;
	
		my @line = split //, $line ;
		for (my $i=0; $i<@line; ++$i)
		{
			if ($i >= $blanks_len)
			{
				# add
				$blanks_aref->[$i] = $line[$i] ;
				++$blanks_len ;
			}
			else
			{
				# adjust
				$blanks_aref->[$i] &= $line[$i] ;
			}
		}
	}
	
	
if ($this->debug >= 5)
{	
	print " + blanks: \"" ;
	foreach (@$blanks_aref)
	{
		print "$_" ;
	}
	print "\"\n" ;
}
	
}

#---------------------------------------------------------------------
# strip out all blanks > $min_blanks
sub format_blanks
{
	my $this = shift ;
	my ($lines_aref, $blanks_aref, $min_blanks) = @_ ;

	my $regexp = "1{$min_blanks,}" ;
	my $blanks = join '', @$blanks_aref ;
	
	# replacement string
	my $replace = $this->blanks_replace() ;
	
print "format_blanks()\nblanks: $blanks\n" if $this->debug >= 5 ;

	# extend all lines
	my $blanks_len = @$blanks_aref ;
	foreach my $line (@$lines_aref)
	{
		my $len = length $line ;
		$len = $blanks_len - $len ;
		if ($len > 0)
		{
			$line .= (" "x$len) ;
		}
	}
	
	# Keep replacing until finished
	while ($blanks =~ s/(.*?)($regexp)/$1$replace/)
	{
		my ($pre, $match) = ($1, $2) ;
		my $pos = length $pre ;
		my $len = length $match ;

print "pos=$pos, len=$len match=\"$2\"\nblanks now: $blanks\n" if $this->debug >= 5 ;
		
		foreach (@$lines_aref)
		{
			substr $_, $pos, $len, $replace ;
		}
	}
}

#---------------------------------------------------------------------
sub format_blocks
{
	my $this = shift ;
	my ($headings_aref, $lines_aref) = @_ ;	
	
print "- split into blocks:\n" if $this->debug >= 5 ;
	
	## Chop into suitable width "blocks"
	# i.e. convert:
	#	..............................................................................	
	#	..............................................................................	
	#	..............................................................................	
	#	..............................................................................	
	#	
	#	into:
	#	
	#	.................
	#	.................
	#	.................  (=block 1)
	#	.................
	#	
	#	.................
	#	.................
	#	.................  (=block 2)
	#	.................
	#	
	#	.. etc
	#
	my @block_lines ;
	my $num_blocks=0 ;
	my $block_height = 1 + @$lines_aref ;	# allow for extra seperator between blocks

	# replacement string
	my $replace = $this->blanks_replace() ;
	
	# find all places where we can chop the lines
	my @pos ;
	my $blanks = $lines_aref->[0] ;
	while ($blanks =~ /\Q$replace\E/g)
	{
		my $pos = pos $blanks ;
print " + + found $replace at $pos\n" if $this->debug >= 5 ;
		push @pos, $pos ;
	}

print " + blanks=$blanks\npos = @pos\n" if $this->debug >= 5 ;
	
	# keep going until we're done
	my $start=0 ;
	my $blank_len = length $blanks ;
	while (($blank_len > $MAX_SCHED_WIDTH) && (@pos))
	{
print " + blank_len=$blank_len\n" if $this->debug >= 5 ;

		my $split ;
		my $pos = $start ;
		while ( ($pos - $start <= $MAX_SCHED_WIDTH) && @pos)
		{
			$pos = shift @pos ;
			$split = $pos ;
		}

print " + split = $split\n" if $this->debug >= 5 ;
		
		if ($split)
		{
			my $len = $split - $start ;

print " + + split len = $len\n" if $this->debug >= 5 ;

			for (my $i=0; $i < @$lines_aref; ++$i)
			{
				$block_lines[$num_blocks][$i] = substr $lines_aref->[$i], $start, $len ;
			}
			++$num_blocks ;

			$start = $split ;
			$blank_len -= $len ;

print " + + new blank_len=$blank_len\n" if $this->debug >= 5 ;
print " + + new start=$start\n" if $this->debug >= 5 ;
		}
	}

	# final	
	for (my $i=0; $i < @$lines_aref; ++$i)
	{
		$block_lines[$num_blocks][$i] = substr $lines_aref->[$i], $start ;
	}
	++$num_blocks if scalar(@block_lines) ;

print "BLOCKS=" . Data::Dumper->Dump([\@block_lines]) if $this->debug >= 5 ;
print " + num_blocks = $num_blocks\n" if $this->debug >= 5 ;


	## Save as final output
	my @final_lines ;
	for (my $block=0; $block < $num_blocks; ++$block)
	{
print " + block = $block\n" if $this->debug >= 5 ;

		# titles
		for (my $i=0; $i < @$headings_aref; ++$i)
		{
			$final_lines[$block*$block_height + $i] = $headings_aref->[$i] ;
		}
		
		# seperator
		$final_lines[$block*$block_height + $block_height-1] = "-"x(2*$MAX_SCHED_WIDTH) ;
		
		# Lines
		for (my $i=0; $i < @{$block_lines[$block]}; ++$i)
		{
			$final_lines[$block*$block_height + $i] .= $block_lines[$block][$i] ;
		}
		
	}
	
	return @final_lines ;
}



#---------------------------------------------------------------------
sub display_schedule_by_chan
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;
	
	print "SCHEDULE (By channel)\n" ;
	print "=====================\n" ;

	my @lines = $this->format_schedule_by_chan($schedule_aref) ;

	## dump it out
	foreach (@lines)
	{
		print "$_\n" ;
	}
	
}

#---------------------------------------------------------------------
sub display_schedule_by_adap
{
	my $this = shift ;
	my ($schedule_aref) = @_ ;
	
	print "SCHEDULE (By adapter)\n" ;
	print "====================\n" ;

	my @lines = $this->format_schedule_by_adap($schedule_aref) ;

	## dump it out
	foreach (@lines)
	{
		print "$_\n" ;
	}
	
}

#---------------------------------------------------------------------
sub display_unschedule_by_adap
{
	my $this = shift ;
	my ($schedule_aref, $unschedule_aref) = @_ ;
	
	print "SCHEDULE/UNSCHEDULE (By adapter)\n" ;
	print "=================================\n" ;

	my @lines = $this->format_unschedule_by_adap($schedule_aref, $unschedule_aref) ;

	## dump it out
	foreach (@lines)
	{
		print "$_\n" ;
	}
}


#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE
1;

__END__


