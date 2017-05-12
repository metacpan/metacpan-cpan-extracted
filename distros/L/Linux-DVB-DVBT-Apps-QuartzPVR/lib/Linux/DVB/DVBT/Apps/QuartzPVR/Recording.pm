package Linux::DVB::DVBT::Apps::QuartzPVR::Recording ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Recording - methods for processing the initial recording requests

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

our $VERSION = "1.010" ;

#============================================================================================
# USES
#============================================================================================
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Time ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Series ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object) ; 

#============================================================================================
# GLOBALS
#============================================================================================

my %FIELDS = (
	'margin'	=> 1,			# number of hours for fuzzy prog search

	'tvsql'		=> undef,		# An initialised Linux::DVB::DVBT::Apps::QuartzPVR::Sql object
	'channels'	=> {},
	
	'today'			=> 0,		# Today's date string
	'today_mins'	=> 0,		# Today's date/time in minutes
	'tommorrow'		=> undef,	# Tommorrow's date string
) ;

# Just the bits we need to update a recording with
my %RECSPEC_MAP = (
	'rec'	=> 'record',
	'pri'	=> 'priority',
	'pth'	=> 'pathspec',
) ;

my %RECSPEC_FULL_MAP = (
	'tit'	=> 'title',
	'pid'	=> 'pid',
	'rid'	=> 'rid',
	'ser'	=> 'tva_series',
	'ch'	=> 'channel',
	
#	'rec'	=> 'record',
#	'pri'	=> 'priority',
#	'pth'	=> 'pathspec',

	%RECSPEC_MAP,
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
	
	## Assume Sql object has been set
	if ($this->tvsql)
	{
		# set channel info
		$this->channels($this->tvsql->select_channels()) ;
	}

	my $today_dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::today_dt() ;
	my $today_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($today_dt) ;
	$this->today_mins($today_mins) ;
	my $today = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2date($today_dt) ;
	$this->today($today) ;

#print "Linux::DVB::DVBT::Apps::QuartzPVR::Recording - today $today_dt  today_mins $today_mins\n" ;
	
	my $tommorrow_dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($today_dt, "+ 1 day") ;
	my $tommorrow = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2date($tommorrow_dt) ;
	$this->tommorrow($tommorrow) ;
	

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
# Gets the latest scheduled recordings list from the database and also
# sets up various date/time values for later use
#
# HASH:
#	pid 
#	channel 
#	title 
#	date 
#	start 
#	duration 
#	episode 
#	num_episodes 
#	repeat 
#	adapter 
#	chan_type 
#	record
#
sub get_recording
{
	my $this = shift ;
	my ($start_date) = @_ ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;
		print "#== get_recording() ==\n" if $this->debug ;	

	## get recording from database
	my @recording = $this->tvsql->select_dvbt_recording() ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("read database") ;
	
	## Sort by date & priority etc
	@recording = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @recording ;
	
	## Set up times
	$this->fix_recording_times(\@recording) ;
	
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("fixed times") ;

#	## Set up pathspecs
#	$this->fix_pathspecs(\@recording) ;
#	
#		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("fixed pathspecs") ;

	## Set up channel types (tv/radio)
	$this->fix_chan_types(\@recording) ;
	
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("fixed chan_types") ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_init(\@recording) ;

	## Process recording (i.e. expand any repeated recordings) - ONLY HANDLE DVBT RECORDINGS
	@recording = $this->process_recording(\@recording, {'DVBT' => 1}) ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("processed recordings") ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("recording list before filter=", \@recording) if $this->debug ;

	## Filter out old events
	@recording = $this->filter_recording($start_date, \@recording) ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("filtered recordings=", \@recording) if $this->debug ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("filtered recordings") ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
	
	return @recording ;
}

#---------------------------------------------------------------------
# Gets the latest scheduled recordings list from the database and also
# sets up various date/time values for later use
#
# HASH:
#	pid 
#	channel 
#	title 
#	date 
#	start 
#	duration 
#	episode 
#	num_episodes 
#	repeat 
#	adapter 
#	chan_type 
#	record
#
sub get_iplay_recording
{
	my $this = shift ;
	my ($start_date) = @_ ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

		print "#== get_iplay_recording() ==\n" if $this->debug ;	

	## get recording from database
	my @recording = $this->tvsql->select_iplay_recording() ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("read database") ;
	
	## Sort by date & priority etc
	@recording = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @recording ;
	
	## Set up times
	$this->fix_recording_times(\@recording) ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("fixed times") ;

#	## Set up pathspecs
#	$this->fix_pathspecs(\@recording) ;
#	
#		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("fixed pathspecs") ;

	## Set up channel types (tv/radio)
	$this->fix_chan_types(\@recording) ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("fixed chan_types") ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_init(\@recording) ;

	## Process recording (i.e. expand any repeated recordings)
	@recording = $this->process_iplay_recording(\@recording) ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("processed recordings") ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("recording list before filter=", \@recording) if $this->debug ;

	## Filter out old events
	@recording = $this->filter_recording($start_date, \@recording) ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("filtered recordings=", \@recording) if $this->debug ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::waypoint("filtered recordings") ;
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
		
	return @recording ;
}

#---------------------------------------------------------------------
# Parse the record specification and return a HASH.
#
# Expect a record specification of one of the following two forms. First form creates a new recording:
#
#  'rec:<level>:pid:<program id>:'
#
# Second form modifies (or deletes if level=0) an existing recording:
#
#  'rec:<level>:rid:<record id>:'
#
# Integer values may also be specified in hex
#
#
sub parse_recspec
{
	my $this = shift ;
	my ($rec_spec) = @_ ;
	
print "parse_recspec($rec_spec)\n" if $this->debug >= 2 ;

	## start by converting any %NN% into CHR(NN) (allows for an easier interface between PHP and running the Perl)
	$rec_spec =~ s/%([\da-f]{2})%/chr(hex($1))/gei ;

	## start by converting any % into $ (allows for an easier interface between PHP and running the Perl)
	$rec_spec =~ s/%/\$/g ;

print " + recspec=\"$rec_spec\"\n" if $this->debug >= 2 ;

	## get params
	my %params ;
	while ($rec_spec =~ m/(\w+):([^:]*):?/g)
	{
		my ($var, $val) = ($1, $2) ;
		
		# hex value
		if ($val =~ /0x([\da-f]+)/i)
		{
			$val = hex($1) ;
		}
		
		# remove spaces
		$val =~ s/^\s+// ;
		$val =~ s/\s+$// ;
		
		# get value
		$params{$var} = $val ;

print " + $var = $val\n" if $this->debug >= 2 ;
	}

$this->prt_data("parse_recspec=", \%params) if $this->debug >= 2 ;

	return \%params ;
}

#---------------------------------------------------------------------
# Get the expanded recording list after parsing a record specification.
#
# Expect a record specification HASH containing:
#
#  'rec 	=> <level>
#  'pid' 	=> <program id>
#
# or
#
#  'rec' 	=> <level>
#  'rid'	=> <record id>
#
#  'pri'    => priority
#  'ser'    => series
#
# Also, assuming it finds any recordings, creates an example rec_href based on the
# recording info and puts it into the ref to the HASH ref ($recspec_rec_href_ref)
#
#
#
sub get_recording_from_spec
{
	my $this = shift ;
	my ($recspec_href, $recspec_rec_href_ref, $start_date) = @_ ;

print "#== get_recording_from_spec() ==\n" if $this->debug ;

	$$recspec_rec_href_ref ||= {} ;	

	my @recording = () ;
	my $record_group = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_group($recspec_href->{'rec'}) ;

	my $fuzzy_title ;
	if ( ($record_group eq 'FUZZY') && ($recspec_href->{'tit'}) )
	{
		$fuzzy_title = $this->_fuzzy_title($recspec_href->{'tit'}) ;
	}
			
	## get ALL recordings from database
	my @existing_recordings = $this->tvsql->select_recording() ;
	
$this->prt_data("existing recordings=", \@existing_recordings) if $this->debug >= 5 ;
$this->prt_data("recspec_href=", $recspec_href) if $this->debug ;

	## Is this a request to modify an existing recording?
	my $rec_href ;
	if ($recspec_href->{'rid'})
	{
		## Amending an existing recording
		
		# check that record id is in the list
		foreach my $href (@existing_recordings)
		{
			if ($recspec_href->{'rid'} eq $href->{'id'})
			{
				$rec_href = $href ;
$this->prt_data("Found existing rec_href=", $rec_href) if $this->debug ;
				last ;
			}
		}
	}
	else
	{
		#### New recording
		
		## Specified program id
		if ($recspec_href->{'pid'})
		{
			# just check to see if pid is already in the recording list
			foreach my $href (@existing_recordings)
			{
				if ($recspec_href->{'pid'} eq $href->{'pid'})
				{
					# it's there already so just amend
					$rec_href = $href ;
	$this->prt_data("found program in recordings=", \$rec_href) if $this->debug ;
					last ;
				}
			}
			
			# if not found, create a new recording based on the program
			if (!$rec_href)
			{
				my @listings = $this->tvsql->select_program_pid({'pid' => $recspec_href->{'pid'}}) ;
	$this->prt_data("program search=", \@listings) if $this->debug >= 2 ;
				if (@listings)
				{
					my $listing_href = $listings[0] ;
					
					my $record_id = $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::NEW_RID ;
					my $priority = $recspec_href->{'pri'} || $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::DEFAULT_PRIORITY ;
	
	print " + create new (pri=$priority)\n" if $this->debug ;
	
					$rec_href = Linux::DVB::DVBT::Apps::QuartzPVR::Prog::new_recording($listing_href, $recspec_href->{'rec'}, $record_id, $priority, $recspec_href->{'pth'}) ;
				}
			}
		}
		
		## Otherwise, check for fuzzy recording
		elsif ( ($record_group eq 'FUZZY') && ($recspec_href->{'tit'}) )
		{
	print " + create new fuzzy (title=$fuzzy_title)\n" if $this->debug ;

			my $channel = $recspec_href->{'ch'} ;
			if (!$channel)
			{
				# Probably need to set it to something...
				my $channels_href = $this->channels() ;
				$channel = (sort {$channels_href->{$a}{'lcn'} <=> $channels_href->{$b}{'lcn'}} keys %$channels_href)[0] ;
	print " + + new fuzzy chan = $channel\n" if $this->debug ;
			}
	print " + fuzzy chan = $channel\n" if $this->debug ;

			my $record_id = $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::NEW_RID ;
			my $priority = $recspec_href->{'pri'} || $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::DEFAULT_PRIORITY ;
	
			## Do a search for any existing programs that match the search criteria
			my $search_href = {
				'title' => $fuzzy_title,
				'channel' => $channel,
			} ;
			my @listings = $this->tvsql->select_listings($recspec_href->{'rec'}, $search_href) ;

	$this->prt_data("program search=", \@listings) if $this->debug >= 2 ;
			if (@listings)
			{
				## Found at least one existing program to base this recording on
				my $listing_href = $listings[0] ;

print " + create fuzzy from existing (pri=$priority)\n" if $this->debug ;

				$rec_href = Linux::DVB::DVBT::Apps::QuartzPVR::Prog::new_recording($listing_href, $recspec_href->{'rec'}, $record_id, $priority, $recspec_href->{'pth'}) ;
			}
			else
			{
				
print " + create new fuzzy\n" if $this->debug ;

				## Can't find any matching recordings - make one up!
				$rec_href = $this->_create_fuzzy_entry($channel, $fuzzy_title, $recspec_href->{'rec'}, $record_id, $priority, $recspec_href->{'pth'}) ;
			}
		}
	}
	
$this->prt_data("rec_href=", $rec_href) if $this->debug ;

	## Process the recording iff we've found one
	if ($rec_href)
	{
		## Transfer recspec properties to recording
		foreach my $field (keys %RECSPEC_MAP)
		{
			if (exists($recspec_href->{$field}))
			{
				$rec_href->{ $RECSPEC_MAP{$field} } = $recspec_href->{$field} ;
			}
		}
		
		## Return recording (expanded from recspec)
		my $new_rec_href = { %$rec_href } ;
		$$recspec_rec_href_ref = $new_rec_href ;
		if ($fuzzy_title)
		{
			## Handle fuzzy recording
			
			# return new fuzzy recording specification (to be used to save in Recordings sql table)
			$new_rec_href->{'title'} = $fuzzy_title ;
			
			# set fuzzy title (to be used in process_recording() to gather any matching titles)
			$rec_href->{'title'} = $fuzzy_title ;
		}

$this->prt_data("Updated (fuzzy=$fuzzy_title) rec_href=", $rec_href) if $this->debug ;
		
		## create list
		push @recording, $rec_href ;
		
		## Set up times
		$this->fix_recording_times(\@recording) ;
	
		## Set up channel types (tv/radio)
		$this->fix_chan_types(\@recording) ;

		# trace
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_init(\@recording) ;
	
		## Process recording (i.e. expand any repeated recordings)
		@recording = $this->process_recording(\@recording) ;
		my @processed_recording = @recording ;
$this->prt_data("processed recordings=", \@recording) if $this->debug ;
	
		## Filter out old events
		@recording = $this->filter_recording($start_date, \@recording) ;
		
		## Special case - move old IPLAY recordings to today
		@recording = $this->fix_iplay_date($new_rec_href, \@recording) ;

$this->prt_data("recordings after fix_iplay_date=", \@recording) if $this->debug ;

	}
	return @recording ;
}

#---------------------------------------------------------------------
# Gets the latest scheduled recordings list from the database and also
# sets up various date/time values for later use
sub fix_recording_times
{
	my $this = shift ;
	my ($recording_aref) = @_ ;

	# Set up times
	foreach (@$recording_aref)
	{
		# Set end time etc
		# only do so if extra information hasn't already been set
		unless (exists($_->{'start_dt_mins'}))
		{
			Linux::DVB::DVBT::Apps::QuartzPVR::Prog::set_times($_) ;
		}
		
		# Add a new field 'rid' which is the recording table original id (=id)
		$_->{'rid'} ||= $_->{'id'} ;
	}
}

##---------------------------------------------------------------------
## Ensure a valid pathspec is set
#sub fix_pathspecs
#{
#	my $this = shift ;
#	my ($recording_aref) = @_ ;
#
#	# Set up pathspecs
#	foreach (@$recording_aref)
#	{
#		$_->{'pathspec'} ||= Linux::DVB::DVBT::Apps::QuartzPVR::Series::default_pathspec($_) ;
#	}
#}

#---------------------------------------------------------------------
# Set the channel type 'chan_type' field based on channel info
sub fix_chan_types
{
	my $this = shift ;
	my ($recording_aref) = @_ ;

	my $chans_href = $this->channels ;
	
	# Set up chan_type
	foreach (@$recording_aref)
	{
		# Set end time etc
		# only do so if extra information hasn't already been set
		unless (exists($_->{'chan_type'}))
		{
			my $chan = $_->{'channel'} ;
			
			$_->{'chan_type'} = 'tv' ;
			if (exists($chans_href->{$chan}))
			{
				$_->{'chan_type'} = $chans_href->{$chan}{'type'} ;
			}
		}
	}
}

#---------------------------------------------------------------------
# If required, set the title to the specified fuzzy search title
sub fix_fuzzy
{
	my $this = shift ;
	my ($recording_aref, $fuzzy_title) = @_ ;

	return unless $fuzzy_title ;

	# Overwrite title
	foreach (@$recording_aref)
	{
		$_->{'title'} = $fuzzy_title ;
	}
}

#---------------------------------------------------------------------
# Ensure all scheduled recordings are set to the correct time 
# Options includes processing only for DVBT or IPLAY
#
sub process_recording
{
	my $this = shift ;
	my ($recording_aref, $options_href) = @_ ;
	my @recording ;

	$options_href ||= {} ;
	
	my $margin_hours = $this->margin ;
	
print "#== process_recording(margin_hours=$margin_hours, $recording_aref) [debug=".$this->debug."] ==\n" if $this->debug ;	
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("existing recording list=", $recording_aref) if $this->debug ;

$this->prt_data("recordings=", $recording_aref) if $this->debug>=10 ;	

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('process_recording') ;

	## track each program added to recordings (ensure only one instance added at a time)
	my %pid ;

	# Look at each entry in turn, process it and add the results to
	# the processed list
	
	# do this lowest priority first, so higher priority overwrites lower
	foreach my $rec_href (sort {$b->{'priority'} <=> $a->{'priority'}} @$recording_aref)
	{
		my $record = $rec_href->{'record'} ;
		if ($options_href->{'DVBT'})
		{
			next unless Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_dvbt($record) ;
		}
		if ($options_href->{'IPLAY'})
		{
			next unless Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_iplay($record) ;
		}
		
		my $record_group = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_group($record) ;
		my $record_id = $rec_href->{'rid'} ;
		my $priority = $rec_href->{'priority'} ;
		my $pathspec = $rec_href->{'pathspec'} ;

		my @listings = $this->_process_recording($rec_href) ;

		# do new entries
		foreach my $listing_href (@listings)
		{
			#next unless $listing_href ;
			
			my $new_sched_href = Linux::DVB::DVBT::Apps::QuartzPVR::Prog::new_recording($listing_href, $record, $record_id, $priority, $pathspec) ;

print "New PID : $new_sched_href->{'pid'} $new_sched_href->{'title'} $new_sched_href->{'date'} $new_sched_href->{'start'}\n" if $this->debug ;	
			
			# Add only if not already seen
			if (exists($pid{$new_sched_href->{'pid'}}))
			{
				## Amend existing priority
				my $existing_sched_href = $pid{$new_sched_href->{'pid'}} ;
print " + AMENDED PID : $new_sched_href->{'pid'} : old priority=$existing_sched_href->{'priority'}, new pri=$new_sched_href->{'priority'}\n" if $this->debug ;	
				$existing_sched_href->{'priority'} = $new_sched_href->{'priority'} ;
			}
			else
			{
				## Add new
				push @recording, $new_sched_href ;
	$this->prt_data("!!ADDED NEW Sched=", $new_sched_href, "pids now=", \%pid) if $this->debug>=10 ;	
print " + ADD NEW PID : $new_sched_href->{'pid'}\n" if $this->debug ;	
			
				Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($new_sched_href, "added new : PID $new_sched_href->{'pid'}") ;

				# keep track of pids
				$pid{$new_sched_href->{'pid'}} = $new_sched_href ;
			}

print ">> PID : $new_sched_href->{'pid'}\n" if $this->debug ;	

		}
	}

print "== process_recording() - END ==\n" if $this->debug ;	
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("recording list=", \@recording) if $this->debug ;

$this->prt_data("recording list=", \@recording) if $this->debug>=10 ;	

	# Set up times
	$this->fix_recording_times(\@recording) ;

	## Set up channel types (tv/radio)
	$this->fix_chan_types(\@recording) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("recording list (fixed times/types)=", \@recording) if $this->debug ;

	return @recording ;
}

#---------------------------------------------------------------------
# Force special values onto the fuzzy recording 
sub _set_fuzzy_entry
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
	$rec_href->{'pid'} = $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::FUZZY_PID ;
	$rec_href->{'start'} = $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::FUZZY_TIME ;
	$rec_href->{'duration'} = $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::FUZZY_DURATION ;
	$rec_href->{'tva_series'} = '-' ;
	$rec_href->{'tva_prog'} = '-' ;
}


#---------------------------------------------------------------------
# Create a dummy Prog for use as a fuzzy recording 
sub _create_fuzzy_entry
{
	my $this = shift ;
	my ($channel, $fuzzy_title, $record, $record_id, $priority, $pathspec) = @_ ;
	
	# TODO: Somehow schedule (or special tag?) so we can put program into a valid
	# empty slot????
	#
	my $listing_href = {
		'title'		=> $fuzzy_title,
		'channel' 	=> $channel,
		'date'		=> $this->tommorrow(),
	} ;
	$this->_set_fuzzy_entry($listing_href) ;
	my $rec_href = Linux::DVB::DVBT::Apps::QuartzPVR::Prog::new_recording($listing_href, $record, $record_id, $priority, $pathspec) ;

	return $rec_href ;
}

#---------------------------------------------------------------------
# Ensure all scheduled IPLAY recordings are set to the correct time 
sub process_iplay_recording
{
	my $this = shift ;
	my ($recording_aref) = @_ ;
	my @recording ;

print "#== process_iplay_recording($recording_aref) ==\n" if $this->debug ;	
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("existing recording list=", $recording_aref) if $this->debug ;

$this->prt_data("recordings=", $recording_aref) if $this->debug>=10 ;	

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('process_iplay_recording') ;

	## track each program added to recordings (ensure only one instance added at a time)
	my %pid ;

	# Look at each entry in turn, process it and add the results to
	# the processed list
	foreach my $href (@$recording_aref)
	{
		my $rec_href = { %$href } ;
		
		my $record = $rec_href->{'record'} ;
		next unless Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_iplay($record) ;
		
		my @listings ;
		my $record_type = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_base($rec_href->{'record'}) ;
		my $record_group = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_group($rec_href->{'record'}) ;
		my $record_id = $rec_href->{'rid'} ;
		my $priority = $rec_href->{'priority'} ;
		my $pathspec = $rec_href->{'pathspec'} ;

print " + checking entry RID $record_id ($rec_href->{title} @ $rec_href->{date} $rec_href->{start}) - type=$record_type rec=$record pri=$priority\n" if $this->debug ;	
$this->prt_data("rec_href=", $rec_href) if $this->debug>=4 ;	

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'seen') ;
		
		# Check record type
		if ($record_type >= Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('multi'))
		{
			# Special case for Multi/All - schedule daily recording regardless of whether
			# program is found or not
			
			# First check the real list of programs
			my @real_listings = $this->_process_recording($rec_href) ;
			
			# If we've found some real programs, use them as the basis
			if (@real_listings)
			{
				# ensure stuff like pathspec is copied over from recording - override everything else
				$rec_href = {
					%$rec_href,
					%{$real_listings[0]},	
				} ;
				
				Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'iplay seen this real prog') ;
$this->prt_data(" + using real : rec_href=", $rec_href) if $this->debug>=4 ;	
			}
			
			# map date -> prog
			my %date_map ;
			foreach my $prog_href (@real_listings)
			{
				## map date
				my $date = $prog_href->{'date'} ;
				$date_map{$date} ||= [] ;
				push @{$date_map{$date}}, $prog_href ;
			}

			# For any multiple recordings, just schedule an update every day
			my @days = $this->tvsql->select_listings_days($rec_href->{'date'}) ; 
			foreach my $date (@days)
			{
				# if a real program exists - use it
				if (exists($date_map{$date}))
				{
	print " + + + use existing\n" if $this->debug ;	
					foreach my $new_href (@{$date_map{$date}})
					{
						push @listings, $new_href ;
	print " + + * * adding new IPLAY entry for $date : new pid=$new_href->{'pid'} [old $rec_href->{'pid'}]\n" if $this->debug ;	
					}
					Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'use existing real program') ;
					
				}
				else
				{
					# create a dummy
					my $new_href = {
						%$rec_href,
						'date' => $date,
						'prog_pid' => $rec_href->{'pid'},
					} ;
					
					## Use  prog_pid to match with a real program so we can get program details from 
					## listings
					
					if ($date ne $rec_href->{'date'})
					{
						## For all other "created" recordings, adjust the 'psuedo-pid' to be valid
						## (so that the filtering that removes dulpicate pids, doesn't remove it)
						my $pdate = $date ;
						$pdate =~ s/\-//g ;
						
						# 16179-301-20110519
						$new_href->{'pid'} =~ s/\-([^-]+)\s*$/-$pdate/ ;
	print " + + + adjusted pid\n" if $this->debug ;	
	
						Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "created dummy based on $new_href->{'prog_pid'}") ;
	
					}
					push @listings, $new_href ;
	print " + + adding new IPLAY entry for $date : new pid=$new_href->{'pid'} [old $rec_href->{'pid'}]\n" if $this->debug ;	
$this->prt_data(" + + rec_href=", $rec_href) if $this->debug>=4 ;	
				}
			}
		}
		else
		{
$this->prt_data(" + + process this : rec_href=", $rec_href) if $this->debug>=4 ;	
			@listings = $this->_process_recording($rec_href) ;
		}	
		

		## All entries get added in here (also handles updates to 'prog_pid')
		$this->_add_recordings($record, $record_id, $priority, $pathspec, \@listings, \%pid, \@recording) ;			
	}

print "== process_iplay_recording() - END ==\n" if $this->debug ;	
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("existing recording list=", $recording_aref) if $this->debug ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("new recording list=", \@recording) if $this->debug ;

$this->prt_data("recording list=", \@recording) if $this->debug>=10 ;	

	# Set up times
	$this->fix_recording_times(\@recording) ;

	## Set up channel types (tv/radio)
	$this->fix_chan_types(\@recording) ;

#	## Ensure all entries have a 'prog_pid' field
#	$this->fix_iplay_pid(\@recording) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("recording list (fixed times/types)=", \@recording) if $this->debug ;

	return @recording ;
}


#---------------------------------------------------------------------
# Create a title string suitable for fuzzy SQL search (using 'LIKE')
# Normally adds % to start and end of string unless ^$ start/end string anchors
# are present
#
sub _fuzzy_title
{
	my $this = shift ;
	my ($title) = @_ ;
print " + + Fuzzy title=$title\n" if $this->debug>=10 ;	

	if ($title =~ /^\^/)
	{
		$title = substr $title, 1 ;
	}
	else
	{
		if ($title !~ /^\%/)
		{
			$title = "%$title" ;
		}
	}
	
	if ($title =~ /\$$/)
	{
		$title =~ s/\$$// ;
	}
	else
	{
		if ($title !~ /\%$/)
		{
			$title = "$title%" ;
		}
	}

print " + + Fuzzy title new=$title\n" if $this->debug>=10 ;	

	return $title ;	
}

#---------------------------------------------------------------------
# Ensure all scheduled recordings are set to the correct time 
sub _process_recording
{
	my $this = shift ;
	my ($rec_href) = @_ ;

	my $margin_hours = $this->margin ;
	
	my @listings ;
	my $record = $rec_href->{'record'} ;
	my $record_type = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_base($rec_href->{'record'}) ;
	my $record_group = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_group($rec_href->{'record'}) ;
	my $record_id = $rec_href->{'rid'} ;
	my $priority = $rec_href->{'priority'} ;

	my $start_dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::parse_date($rec_href->{date}, $rec_href->{start}) ;
	my $start_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::time2mins($rec_href->{start}) ;

print " + checking entry RID $record_id ($rec_href->{title} @ $rec_href->{date} $rec_href->{start}) - type=$record_type rec=$record [$record_group:$record_type] pri=$priority\n" if $this->debug ;	

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'seen') ;
	
	
	## Do some initial checks
	my $ignore_recording = 0 ;
	if ($record_type == Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('once'))
	{
		my $start_dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($start_dt) ;
		
print " + Start ($rec_href->{date} $rec_href->{start} => $start_dt) mins=$start_dt_mins, Today mins=".$this->today_mins."\n" if $this->debug ;	

		## first ensure that this single recording is still worth recording i.e. date >= today
		## Special case - allow old IPLAY recordings
		if ( ($start_dt_mins >= $this->today_mins) || Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_iplay($record) )
		{
			# Once - ensure this program hasn't changed
			@listings = $this->tvsql->select_program($rec_href) ;
	
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'search : single') ;
		}
		else
		{
			# an old recording so skip it
			$ignore_recording = 1 ;

			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'skip old : single') ;
		}
	}
	
	## If passed initial checks, then search 
	if (!$ignore_recording)
	{
		if (! @listings)
		{
			# If program is not there any more, try a windowed search looking at a window of time
print " + doing windowed search\n" if $this->debug>=10 ;	

			# Create the extra params for the windowed search (i.e. allow for time shift etc)
			my $margin_mins = $margin_hours*60 ;
print " + + start_dt=$start_dt, start_mins=$start_mins, margin_mins=$margin_mins\n" if $this->debug>=10 ;	

			$rec_href->{'start_min'} = "00:00" ;
			if ($start_mins > $margin_mins)
			{
				$rec_href->{'start_min'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::mins2time($start_mins - $margin_mins) ;
print " + + + Set min=$rec_href->{'start_min'}\n" if $this->debug>=10 ;	
			}
			$rec_href->{'start_max'} = "23:59" ;
			if (($start_mins + $margin_mins) < $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::DAY_MINS )
			{
				$rec_href->{'start_max'} = Linux::DVB::DVBT::Apps::QuartzPVR::Time::mins2time($start_mins + $margin_mins) ;
print " + + + Set max=$rec_href->{'start_max'}\n" if $this->debug>=10 ;	
			}
			
			$rec_href->{'dayofweek'} = Linux::DVB::DVBT::Apps::QuartzPVR::Sql->dayofweek($start_dt) ; 
			
			## Check for series record
			if ($record_type == Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('series'))
			{
				# if no series specified, then fall back to recording all on this channel
				if (!$rec_href->{'tva_series'} || ($rec_href->{'tva_series'} eq '-'))
				{
					$record_type = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('multi') ;
					$rec_href->{'record'} = $record_group + $record_type ;
				}			
			}
		
print " + Search title=$rec_href->{'title'}\n" if $this->debug>=10 ;	

			# Get sql query
			@listings = $this->tvsql->select_listings($record_type, $rec_href) ; 

	$this->prt_data("windowed listings=", \@listings) if $this->debug>=10 ;	
			
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, {
				'msg' 	=> 'search : windowed time',
				'listings'	=> \@listings,
			}) ;
		}
	}
	return @listings ;
}

#---------------------------------------------------------------------
# Ensure all scheduled recordings are set to the correct time 
sub _add_recordings
{
	my $this = shift ;
	my ($record, $record_id, $priority, $pathspec, $listings_aref, $pids_href, $recording_aref) = @_ ;


		# do new entries
		foreach my $listing_href (@$listings_aref)
		{
			my $new_sched_href = Linux::DVB::DVBT::Apps::QuartzPVR::Prog::new_recording($listing_href, $record, $record_id, $priority, $pathspec) ;
			
			## New: for IPLAY we have a special 'prog_pid' field that tracks the real PID
			$new_sched_href->{'prog_pid'} = $listing_href->{'prog_pid'} || $listing_href->{'pid'} ;

print "New PID : $new_sched_href->{'pid'} $new_sched_href->{'title'} $new_sched_href->{'date'} $new_sched_href->{'start'}\n" if $this->debug ;	
			
			# Add only if not already seen
			if (exists($pids_href->{$new_sched_href->{'pid'}}))
			{
				## Amend existing priority
				my $existing_sched_href = $pids_href->{$new_sched_href->{'pid'}} ;
print " + AMENDED PID : $new_sched_href->{'pid'} : old priority=$existing_sched_href->{'priority'}, new pri=$new_sched_href->{'priority'}\n" if $this->debug ;	
				$existing_sched_href->{'priority'} = $new_sched_href->{'priority'} ;
			}
			else
			{
				## Add new
				push @$recording_aref, $new_sched_href ;
	$this->prt_data("!!ADDED NEW Sched=", $new_sched_href, "pids now=", $pids_href) if $this->debug>=10 ;	
print " + ADD NEW PID : $new_sched_href->{'pid'}\n" if $this->debug ;	
			
				Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($new_sched_href, "added new : PID $new_sched_href->{'pid'}") ;

				# keep track of pids
				$pids_href->{$new_sched_href->{'pid'}} = $new_sched_href ;
			}

print ">> PID : $new_sched_href->{'pid'}\n" if $this->debug ;	

		}

}



#---------------------------------------------------------------------
# Filter out recordings that start before now 
sub filter_recording
{
	my $this = shift ;
	my ($start_date, $recording_aref) = @_ ;
	my @filtered_recording ;

print "#== filter_recording() ==\n" if $this->debug ;	

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('filter_recording') ;

	# Get now to compare with
	my $now = Linux::DVB::DVBT::Apps::QuartzPVR::Time::parse_date($start_date) ;
	my $now_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($now) ;

print "Filter sched: now=$now, now_mins=$now_mins\n" if $this->debug ;

	## see if start/end is after now
	foreach my $rec_href (@$recording_aref)
	{
print " + prog sched=$rec_href->{'title'} $rec_href->{'start'} : start_mins=$rec_href->{'start_dt_mins'} @ $rec_href->{'date'} (end_mins=$rec_href->{'end_dt_mins'})\n" if $this->debug ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'seen') ;

		if ($now_mins < $rec_href->{'end_dt_mins'})
		{
print " + comp now=$now_mins < sched=$rec_href->{'end_dt_mins'}\n" if $this->debug ;
print " + + Added $rec_href->{'title'} @ $rec_href->{'date'} $rec_href->{'start'}\n" if $this->debug ;
			push @filtered_recording, $rec_href ;

			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, '** Accepted **') ;
		}
		else
		{
print " + + missed start/end\n" if $this->debug ;
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'missed start/end') ;
		}
	}

	return @filtered_recording ;
}


#---------------------------------------------------------------------
# Move single one-off IPLAY recording to today. Caller has already determined that
# the date needs to be fixed
# 
sub _fix_iplay_date
{
	my $this = shift ;
	my ($rec_href) = @_ ;

	## Adjust to today's date
	$rec_href->{'date'} = $this->today ;
	
	## Re-adjust the rest of the settings
	Linux::DVB::DVBT::Apps::QuartzPVR::Prog::set_times($rec_href) ;
	
}

#---------------------------------------------------------------------
# Move any one-off IPLAY recordings to today (multiple recordings will automatically
# fall on, or after, today)
#
# Only used by get_recording_from_recspec() - i.e. adjusts old recordings to be scheduled
# for today
# 
sub fix_iplay_date
{
	my $this = shift ;
	my ($new_rec_href, $recording_aref) = @_ ;
	my @recording ;

print "#== fix_iplay_date() ==\n" if $this->debug ;	

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('fix_iplay_date') ;
	
	my $RECORD_ONCE = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('once') ;
	my $TODAY_MINS = $this->today_mins ;
	
	my $record = $new_rec_href->{'record'} ;
	my $record_type = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_base($new_rec_href->{'record'}) ;
	
	## See if one-off IPLAY recording
	my $needs_fixing = 0 ;
	if (Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::has_iplay($record) && ($record_type == $RECORD_ONCE) )
	{
print " + + IPLAY : one-off\n" if $this->debug ;

		## Old recording
		my $start_dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::parse_date($new_rec_href->{date}, $new_rec_href->{start}) ;
		my $start_dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($start_dt) ;
print " + + prog mins = $start_dt_mins, today = $TODAY_MINS\n" if $this->debug ;

		if ($start_dt_mins <= $TODAY_MINS)
		{
			$needs_fixing = 1 ;
		}
	}	
	
	if ($needs_fixing)
	{
		# process all recordings - assume the "list" is a single entry
		$this->_fix_iplay_date($new_rec_href) ;
		
		foreach my $rec_href (@$recording_aref)
		{
			## Amend date to today
			$this->_fix_iplay_date($rec_href) ;

	print " + + amended date $rec_href->{'date'}\n" if $this->debug ;

			push @recording, $rec_href ;
		}
		
	}
	else
	{
		# return un-altered list
		@recording = @$recording_aref ;
	}
	
	return @recording ;
}


##---------------------------------------------------------------------
## Ensure all entries have 'prog_pid' field (which is usually a copy of 'pid'
## unless this is a "created" recording)
##
## Only used by get_iplay_recording()
## 
#sub fix_iplay_pid
#{
#	my $this = shift ;
#	my ($recording_aref) = @_ ;
#
#print "#== fix_iplay_pid() ==\n" if $this->debug ;	
#Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched(" + before fix_iplay_pid=", $recording_aref) if $this->debug >= 2 ;
#
#	foreach my $rec_href (@$recording_aref)
#	{
#		$rec_href->{'prog_pid'} ||= $rec_href->{'pid'} ;
#	}
#
#Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched(" + after fix_iplay_pid=", $recording_aref) if $this->debug >= 2 ;
#}


#============================================================================================
# UTILITY
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE
1;

__END__


