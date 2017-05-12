package Linux::DVB::DVBT::Apps::QuartzPVR ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR - PVR Application 

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Apps::QuartzPVR ;
  
	print "Verion: " . Linux::DVB::DVBT::Apps::QuartzPVR::version() . "\n" ;
	

=head1 DESCRIPTION

This is a bundle module that installs a complete PVR application that uses a web frontend for 
TV listings display and for managing recordings.


=head2 INSTALLING

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head2 INSTALL QUESTIONS

When you run 'perl Makefile.PL' a number of questions are asked to determine your setup. The answers are then 
embedded into various config files in the installation.

Questions asked are:

=over 4

=item * SQL_ROOT_PASSWORD - MySQL root user password so I can create the pvr database

The root user password for your MySQL server. This allows the installation to create the new MySQL user
and database used for the tv guide. 

=item * DVBT_FREQFILE - full path to DVB-T tuning frequency file (usually under /usr/share/dvb/dvb-t)

Give the path to the frequency file. This is used by dvbt-scan to initialise the tuner. Can alternatively supply
a 2 letter country code (for example GB) to initiatate a (much longer) full frequency scan.

=item * MAIL_TO - email account to mail PVR errors to

Give a mail account (e.g. fred@bloggs) to which all script errors will be sent. This is useful for cases where a 
program has failed to record. 

=item * WEB_USER - user name of the web server

User name that your web server uses (e.g. on Ubuntu this is www-data). Script should have worked out the correct
setting, but change if it's not correct for your system.

=item * WEB_GROUP - group name of the web server

Group name that your web server uses (e.g. on Ubuntu this is www-data). Script should have worked out the correct
setting, but change if it's not correct for your system.

=back

The script then asks if you want to use the default values for the "extra" options. These defaults will work on any 
system, but you may answer 'no' to allow you chance to see and change all of the following settings:

=over 4

=item * SERVER_PORT - TCP port of the new PVR server that I will install

Specify a different TCP port number for the PVR server to use. The server provides the interface between the scheduling
Perl script and the web frontend 

=item * SQL_USER - username of the MySQL pvr database owner

Change the MySQL username that will be created for the tv guide database

=item * SQL_PASSWORD - password of the MySQL pvr database owner

Change the MySQL password that will be used for the tv guide database

=item * PVR_USER - Linux user name created for recording

Specify a username to use for running the recording scripts. By default a new system user will be created, but you can
also specify an existing user. Note that recordings are added to that user's crontab

=item * PVR_GROUP - Linux group name for PVR_USER

Specify a group to use for running the recording scripts. By default uses 'video' to allow access to the DVB-T drivers.

=item * PVR_LOGDIR - location of PVR logs

A directory under which all PVR logs are stored

=item * DATABASE - PVR database name

The MySQL database name to use for the tv guide

=item * VIDEO_DIR - Video recording top-level directory

The directory under which all videos are recorded

=item * AUDIO_DIR - Audio recording top-level directory

The directory under which all audio files are recorded

=item * VIDEO_TRASH - Video trashcan directory

During recording, various temporary video files are created and then removed. By default the "deleted" files are moved
to this trashcan location. A cron job is set up in the QUARTZPVR user's crontab which deletes trash files after a week.

This is done to ensure you always have access to the raw recording just in case the file left in the video directory
is not playable (allows for re-processing the original).

=item * VIDEO_PATH - Video file full path

Recorded video file will be stored with this full pathname. Obviously the filename must contain variables otherwise every
recording will overwrite the previous recording.

The default setting is: $video_dir/$title/$tva_series/$YmdHMS-$name.ts

The full list of variable that can be used are:

=over 4

=item $Y
Four digit year (e.g. 2011) of recording start date.

=item $m
Two digit month with leading zero of recording start date.

=item $d
Two digit day with leading zero of recording start date.

=item $H
Two digit hour with leading zero of recording start time.

=item $M
Two digit minute with leading zero of recording start time.

=item $S
Two digit second with leading zero of recording start time.

=item $Ymd
Shortcut to using Y, m, d variables individually (e.g. results in 20110901 for September 1st, 2011)

=item $HMS
Shortcut to using H, M, S variables individually (e.g. results in 173500 for 17:35:00)

=item $Ymd
Shortcut to using Y, m, d, H, M, S variables individually (e.g. results in 20110901173500 for September 1st, 2011 at 17:35:00)

=item $genre
Broadcast genre string. This is usually not much use as it only conveys 'Film', 'Show', or 'News'.

=item $series
If the program is part of a series, then this variable is set to 'Series X'.

=item $series_num
If the program is part of a series, then this variable is set to the series number e.g. 'X'.

=item $episode
If the program is part of a series, then this variable is set to 'Episode Y'.

=item $episode_num
If the program is part of a series, then this variable is set to the episode number e.g. 'Y'.

=item $tva_series
Set to the TVAnytime series string (f present).

=item $tva_prog
Set to the TVAnytime program string (f present).

=item $title
Set to the program title (e.g. 'The Big Bang Theory').

=item $subtitle
This is the "minor title" or extra details string extracted from the program description.

=item $name
Set to a meaningful name for the program. Default is to the use the title.

=item $audio_dir
Set to the top-level path for recording all audio files. This is initialised when the application is installed.

=item $video_dir
Set to the top-level path for recording all video files. This is initialised when the application is installed.

=item $dir
Automatically set to video_dir or audio_dir depending on the file type.

=back



=item * AUDIO_PATH - Audio file full path

Recorded audio file will be stored with this full pathname. 

The default setting is: $audio_dir/$title/$series/$YmdHMS-$name.mp3

=item * PVR_ROOT - Installation directory. This is where all of the PVR software is installed.

This is where the web frontend files (PHP, CSS, Javascript) are installed. You will need to add an entry to your 
web server configuration to allow access to this directory (and it is up to you to protect site access).

=item * ADAPTERS - DVB-T/T2 adapters to be used

Space separated list of the adapter numbers to use (leave blank for default)

=item * ADSKIP - Advert removal

Advert removal (1=remove adverts, 0=do not remove adverts)

=item * DATE_TZ - Timezone
Your timezone (as defined for the PHP Date object)

=item * PHP_SEARCH - Include all PHP libs

Allow use of other installed PHP (may cause name clashes). 

=item * PHP_LOG - PHP log file

Debug: Log file to use for PHP application. Default is no log file specified so no logging is done. 

Note: You are responsible for ensuring the directory is writable by the web server.

=item * SERVER_DEBUG - QuartzPVR server debugging

Debug: Level of server debug logging. Debug logs will be stored in /var/log/quartzpvr-server.log

=back

=head2 UBUNTU

If you haven't already got DBD::mysql, then you may need to install libmysqlclient-dev package for the cpan install
to work properly (it needs mysql_config). Run:

	sudo apt-get install libmysqlclient-dev

=head2 DEPENDENCIES

To run the web frontend you need to have installed:

	web server (preferably apache)
	php
	MySql
	a dvb package (to provide the initial frequency file)

This module requires these other modules and libraries:

	use App::Framework ;
	use Linux::DVB::DVBT ;
	use Linux::DVB::DVBT::TS ;
	use Linux::DVB::DVBT::Advert ;
	use MP3::Tag ;
	use DBI ;
	use DBD::mysql ;
	use Net::Server::Fork ;


=head2 OPTIONAL

If you have access to the BBC iplayer, you can schedule iplayer file downloads via the EPG. To do this you need
to install get_iplayer from http://www.infradead.org/get_iplayer/html/get_iplayer.html



=over 4

=cut


#============================================================================================
# USES
#============================================================================================
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Series ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Recording ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Report ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Schedule ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Iplayer ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Sql ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Crontab ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Mail ;
use Linux::DVB::DVBT::Apps::QuartzPVR::DVB ;

#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '0.07';


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object) ; 

# TODO: Create HTML report page (optional) - include date/time in filename

# TODO: Re-schedule based on chan+1 ?
# TODO: Re-schedule based on prog repeat (same title+description etc?)

# TODO: Series link
# TODO: Series - record to title dir / episode name


#============================================================================================
# GLOBALS
#============================================================================================

my %FIELDS = (

	## User specified settings
	'date'			=> 'today',		# start date
	'trace_flag'	=> 0,			# set to print out trace
	'profile_flag'	=> 0,			# set to print out profile
	'test'			=> 0,			# test mode - don't do final schedule commit
	
	'enable_multirec'	=> 0,		# allow multiplex recording
	'max_timeslip'		=> 0,		# 
	'run_dir'			=> '',
	'log_dir'			=> '',
	'run_ext'			=> '.lst',

	'video_dir'			=> undef,		# video recording dir
	'audio_dir'			=> undef,		# audio recording dir
	'video_path'		=> undef,		# video recording path spec
	'audio_path'		=> undef,		# audio recording path spec
	'variables'			=> undef,
	
	'padding'		=> undef,
	'margin'		=> 1,			# number of hours for fuzzy prog search
	'early'			=> undef,
	'date'			=> undef,
	'log'			=> undef,
	'report'		=> undef,
	'php'			=> undef,
	
	'recprog'		=> undef,
	'iplayprog'		=> undef,
	'iplay_time'	=> undef,

	## Sql - user specified
	'sql'			=> undef,		# set to Database handler object
	
	'database'		=> undef,		# Database name
	'tbl_recording'	=> undef,		# database table for recordings requests
	'tbl_listings'	=> undef,		# database table for tvguide listings
	'tbl_schedule'	=> undef,		# database table for resulting scheduled recordings
	'tbl_multirec'	=> undef,		# database table for multiplex recordings
	'tbl_iplay'		=> undef,		# database table for get_iplayer scheduled recordings
	'tbl_chans'		=> undef,		# database table for list of channels
	'tbl_recorded'	=> undef,		# database table for recorded programs
	
	'user'			=> '',
	'password'		=> '',
	
	## DVB
	'adapters'		=> undef,		# string list of adapters tro use
	'num_adapters'	=> 0,
	'devices'		=> [],
	
	## Internal
	'_tvsql'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Sql object
	'_tvrec'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Recording object
	'_tvreport'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Report object
	'_tvsched'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Schedule object
	'_tviplay'		=> undef,		# Linux::DVB::DVBT::Apps::QuartzPVR::Iplayer object
) ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

#=item C<new([%args])>
#
#Create a new object.
#
#The %args are specified as they would be in the B<set> method, for example:
#
#	'mmap_handler' => $mmap_handler
#
#The full list of possible arguments are :
#
#	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 
#
#=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;
	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_flag($this->trace_flag) ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::profile_flag($this->profile_flag) ;
	
	## Variables
	my $vars_href = $this->variables() || {} ;
	my %vars = (
#		%ENV,
		%$vars_href,
	) ;

	## Linux::DVB::DVBT::Apps::QuartzPVR::Sql object
	my $tvsql = Linux::DVB::DVBT::Apps::QuartzPVR::Sql->new(
		'app'			=> $this->app,
		'sql'			=> $this->sql,		
		'database'		=> $this->database,
		'tbl_recording'	=> $this->tbl_recording,
		'tbl_listings'	=> $this->tbl_listings,	
		'tbl_schedule'	=> $this->tbl_schedule,
		'tbl_multirec'	=> $this->tbl_multirec,
		'tbl_iplay'		=> $this->tbl_iplay,
		'tbl_chans'		=> $this->tbl_chans,
		'tbl_recorded'	=> $this->tbl_recorded,
		
		'rec_dvbt_iplay'=> $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::REC_GROUPS{'DVBT_IPLAY'},
		'rec_iplay'		=> $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::REC_GROUPS{'IPLAY'},
		
		'user'			=> $this->user,
		'password'		=> $this->password,
		
		'debug'			=> $args{'dbg_sql'},
	) ;
	$tvsql->init_sql() ;

	## Linux::DVB::DVBT::Apps::QuartzPVR::Recording object
	my $tvrec = Linux::DVB::DVBT::Apps::QuartzPVR::Recording->new(
		'app'		=> $this->app,
		'tvsql'		=> $tvsql,
		'margin'	=> $this->margin,
		'debug'		=> $args{'dbg_recording'},
	) ;

	## Linux::DVB::DVBT::Apps::QuartzPVR::Report object
	my $tvreport = Linux::DVB::DVBT::Apps::QuartzPVR::Report->new(
		'app'		=> $this->app,
		'debug'		=> $args{'dbg_report'},
	) ;

	## Linux::DVB::DVBT::Apps::QuartzPVR::Schedule object
	my $tvsched = Linux::DVB::DVBT::Apps::QuartzPVR::Schedule->new(
		'app'		=> $this->app,
		'debug'		=> $args{'dbg_schedule'},
	) ;

	## Linux::DVB::DVBT::Apps::QuartzPVR::Iplayer object
	my $tviplay = Linux::DVB::DVBT::Apps::QuartzPVR::Iplayer->new(
		'app'			=> $this->app,
		'iplay_time'	=> $this->iplay_time,
		'debug'			=> $args{'dbg_iplay'},
	) ;

	## save objects
	$this->set(
		'_tvsql'		=> $tvsql,	
		'_tvrec'		=> $tvrec,	
		'_tvreport'		=> $tvreport,
		'_tvsched'		=> $tvsched,
		'_tviplay'		=> $tviplay,
	) ;
	$tvsched->set(
		'_tvsql'		=> $tvsql,	
		'_tvrec'		=> $tvrec,	
		'_tvreport'		=> $tvreport,
	) ;
	$tviplay->set(
		'_tvsql'		=> $tvsql,	
		'_tvrec'		=> $tvrec,	
		'_tvreport'		=> $tvreport,
	) ;

	## Get number of available DVB adapters
	my @devices = Linux::DVB::DVBT::Apps::QuartzPVR::DVB::set_useable_adapters($this->adapters) ;
	my $num_adapters = scalar(@devices) ;
	
	$this->set(
		'num_adapters'	=> $num_adapters,
		'devices'		=> \@devices,
	) ;
	
	# report
	$tvreport->devices(\@devices) ;

	## Init cron
	Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::set(
		'app'			=> $this->app,

		'padding'		=> $this->padding,
		'early'			=> $this->early,
		'recprog'		=> $this->recprog,
		'iplayprog'		=> $this->iplayprog,
		'video_dir'			=> $this->video_dir,
		'audio_dir'			=> $this->audio_dir,
		'log'			=> $this->log,
		'crontag'		=> 'dvb-record',
		'debug'			=> $args{'dbg_cron'},
		
		'log_dir'		=> $this->log_dir,
		'run_dir'		=> $this->run_dir,
		'run_ext'		=> $this->run_ext,
		'max_timeslip'	=> $this->max_timeslip,		# max timeslip time in minutes ; 0 = no timeslip
	) ;

	## Init Series
	Linux::DVB::DVBT::Apps::QuartzPVR::Series::set(
		'app'				=> $this->app,
		'video_dir'			=> $this->video_dir,
		'audio_dir'			=> $this->audio_dir,
		'video_path'		=> $this->video_path,
		'audio_path'		=> $this->audio_path,
		'variables'			=> \%vars,

		'debug'			=> $args{'dbg_series'},
	) ;

	## Init mail
	Linux::DVB::DVBT::Apps::QuartzPVR::Mail::set(
		'tvreport'	=> $tvreport,
		'debug'		=> $args{'dbg_mail'},
	) ;
	
	## debug
	$Linux::DVB::DVBT::Apps::QuartzPVR::Prog::debug = $args{'dbg_prog'} ;
	$Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::debug = $args{'dbg_dbg_trace'} ;

	return($this) ;
}



#============================================================================================
# CLASS METHODS 
#============================================================================================

#-----------------------------------------------------------------------------
#
#=item C<init_class([%args])>
#
#Initialises the Cwrsync object class variables. Creates a class instance so that these
#methods can also be called via the class (don't need a specific instance)
#
#=cut
#
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

#--------------------------------------------------------------------------------------------
# Works out what to do based on the command options, then does it
sub process
{
	my $this = shift ;
	my ($opts_href) = @_ ;
	
	my $num_adapters = $this->num_adapters ;
	
	if ($opts_href->{'info'})
	{
		## Display settings
		$this->show_info($opts_href) ;
	}
	elsif ($opts_href->{'rec'})
	{
		die "Error: You must have at least one DVB-T adapter available for recording" unless $num_adapters ;
	
		
		## Handle new/changed recording 
		$this->modify_recording($opts_href->{'rec'}) ;
	}
	else
	{
		die "Error: You must have at least one DVB-T adapter available for recording" unless $num_adapters ;
	
		
		## Do the update
		$this->update() ;
	}
	
}

#--------------------------------------------------------------------------------------------
# Gathers all the latest information from the EPG database and the recordings database and re-schedules
sub update
{
	my $this = shift ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_clear() ;

print "Linux::DVB::DVBT::Apps::QuartzPVR::update() : ".$this->date."\n" if $this->debug ;
	
	my $tvrec = $this->_tvrec ;
	my $tvreport = $this->_tvreport ;
	my $tvsched = $this->_tvsched ;
	my $tviplay = $this->_tviplay ;
	my $num_adapters = $this->num_adapters ;


	## Get list of recordings and expand into schedule (ignoring any old programs) 
	my @schedule = () ;
	my @iplay_schedule = () ;
	my @unscheduled = () ;
	my @recording_schedule = $tvrec->get_recording($this->date) ;
	my @iplay_recordings = $tvrec->get_iplay_recording($this->date) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("IPLAY recordings=", \@iplay_recordings) if $tviplay->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("DVBT recordings=", \@recording_schedule) if $tvsched->debug >= 4 ;

	
	## Ensure any current recordings are marked as "locked"
	my @existing_schedule = $tvsched->existing_schedule() ;
	$tvsched->mark_locked_recordings(\@recording_schedule, \@existing_schedule) ;
	
	## Handle any get_iplayer recordings
	$tviplay->schedule_recordings(\@iplay_recordings, \@iplay_schedule) ;

	## Perform the scheduling (of DVBT recordings)
	my $ok = $tvsched->schedule_recordings($num_adapters, \@recording_schedule, \@schedule, \@unscheduled, 
		'enable_multirec' 	=> $this->enable_multirec,
		'max_timeslip' 		=> $this->max_timeslip,
	) ;

Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("IPLAY schedule=", \@iplay_schedule) if $tviplay->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("DVBT schedule=", \@schedule) if $tvsched->debug >= 4 ;

	
	## If unscheduled programs
	if (!$ok && !$this->test)
	{
		## Mail warning
		Linux::DVB::DVBT::Apps::QuartzPVR::Mail::mail_error("dvb_record_mgr unscheduled", "Warning: some programs left unscheduled during update") ;
	}

	## Update schedule
	$tvsched->update_cron(\@schedule) ;
	$tviplay->update_cron(\@iplay_schedule) ;
	$tvsched->commit(\@schedule, $this->test) ;
	$tviplay->commit(\@iplay_schedule, $this->test) ;

	## Print report if required
	if ($this->report)
	{
		## Create report
		$tvreport->print_report() ;
	
		# check cron
		Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::check_cron() ;
	}

	## Output to PHP if required
	if ($this->php)
	{
		if (!$ok)
		{
			## Report warning
			$this->php_unscheduled(\@unscheduled) ;
		}		
	}

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;

	return $ok ;
}

#--------------------------------------------------------------------------------------------
# Uses the existing schedule, but adds/modifies the specified recording(s)
#
#Expect a record specification of one of the following two forms. First form creates a new recording:
#
#  'rec:<level>:pid:<program id>:'
#
#Second form modifies (or deletes if level=0) an existing recording:
#
#  'rec:<level>:rid:<record id>:'
#
# Mainly intended for PHP use
#
sub modify_recording
{
	my $this = shift ;
	my ($rec_spec) = @_ ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::trace_clear() ;

print "Linux::DVB::DVBT::Apps::QuartzPVR::modify_recording() : ".$this->date."\n" if $this->debug ;

	my $ok = 0 ;
	
	my $tvsql = $this->_tvsql ;
	my $tvrec = $this->_tvrec ;
	my $tvreport = $this->_tvreport ;
	my $tvsched = $this->_tvsched ;
	my $tviplay = $this->_tviplay ;
	my $num_adapters = $this->num_adapters ;

	$tvreport->recspec($rec_spec) ;

	## Get currently scheduled recordings
	my @schedule = $tvsched->existing_schedule() ;
	my @iplay_schedule = $tviplay->existing_schedule() ;
	my @unscheduled = () ;
	my @recording_schedule = () ;
	my @requested_recording = () ;

print "Modify rec : $rec_spec\n" if $this->debug ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Existing IPLAY schedule=", \@iplay_schedule) if $tviplay->debug >= 4 ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("Existing DVBT schedule=", \@schedule) if $tvsched->debug >= 4 ;

	## Parse spec
	## NOTE: recspec_href is NOT a full program HASH - just the recording specifics 
	my $recspec_href = $tvrec->parse_recspec($rec_spec) ;
	my $record = $recspec_href->{'rec'} ;
	
	if ($record)
	{
		## Modify/Create

		# expand rid/pid into new recordings
		my $recspec_rec_href = {} ;
		@recording_schedule = $tvrec->get_recording_from_spec($recspec_href, \$recspec_rec_href, $this->date) ;
		@requested_recording = @recording_schedule ;

if ($this->debug)
{
$this->prt_data("expanded recspec=", $recspec_rec_href) ;
Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched("spec recordings=", \@recording_schedule) ;
print "\n-=-=-=-=-=-=-=-=-=-=-=-=-=\n" ;
	if ($this->debug >= 2)
	{
	$this->prt_data("Existing schedule=", \@schedule) ;
	print "\n-=-=-=-=-=-=-=-=-=-=-=-=-=\n" ;
	}
}

		# if RID, remove existing from schedule
		if ($recspec_rec_href->{'rid'} > 0)
		{
			$tvsched->unschedule(\@schedule, $recspec_href->{'rid'}) ;
			$tviplay->unschedule(\@iplay_schedule, $recspec_href->{'rid'}) ;
$this->prt_data("removed $recspec_href->{'rid'} from schedule=", \@schedule) if $this->debug ;
$this->prt_data("removed $recspec_href->{'rid'} from IPLAY schedule=", \@iplay_schedule) if $this->debug ;
		}

print "schedule recordings...\n" if $this->debug ;

		## Handle any get_iplayer recordings
		@recording_schedule = @requested_recording ;
		$tviplay->schedule_recordings(\@recording_schedule, \@iplay_schedule) ;

		# attempt to schedule
		@recording_schedule = @requested_recording ;
		$ok = $tvsched->schedule_recordings($num_adapters, \@recording_schedule, \@schedule, \@unscheduled, 
			'enable_multirec' 	=> $this->enable_multirec,
			'max_timeslip' 		=> $this->max_timeslip,
		) ;

print "schedule recordings: ok=$ok\n" if $this->debug ;
		
		# Update database
		if ($ok)
		{
			my $rid = $recspec_rec_href->{'rid'} ;

print "$rid == $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::NEW_RID\n" if $this->debug ;

			# New or modified
			if ($rid == $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::NEW_RID)
			{
$this->prt_data("INSERT NEW RECORDING recspec=", $recspec_rec_href) if $this->debug ;
				# insert into database
				my $new_rid = $tvsql->insert_recording($recspec_rec_href) ;

print " + New RID = $new_rid\n" if $this->debug ;

				# replace NEW_RID (which is a placeholder value) with the real new RID value
				$tvsched->update_rid($new_rid, \@schedule) ;
				$tviplay->update_rid($new_rid, \@iplay_schedule) ;
			}
			else
			{
$this->prt_data("UPDATE EXISTING RECORDING recspec=", $recspec_rec_href) if $this->debug ;
				$tvsql->update_recording($recspec_rec_href) ;
			}
		}

##TODO: Check - if unscheduled priority > new priority (i.e. higher pri has been scheduled) then its ok
#if (!$ok)
#{
##	$ok = priority_check($rec_href, \@unscheduled) ;
#}

	}
	else
	{
		## Delete
		if ($recspec_href->{'rid'})
		{
print "DELETE EXISTING RECORDING\n" if $this->debug ;
			## delete this recording
			$tvsql->delete_recording($recspec_href->{'rid'}) ;

			##remove existing from schedule
			$tvsched->unschedule(\@schedule, $recspec_href->{'rid'}) ;
			$tviplay->unschedule(\@iplay_schedule, $recspec_href->{'rid'}) ;
$this->prt_data("removed $recspec_href->{'rid'} from schedule=", \@schedule) if $this->debug ;

			$ok = 1 ;
		}
	}

print "done ok=$ok...\n" if $this->debug ;

	## update cron jobs
	$tvsched->update_cron(\@schedule) ;
	$tviplay->update_cron(\@iplay_schedule) ;

	## If no unscheduled programs
	if ($ok)
	{
		## Update schedule
		$tvsched->commit(\@schedule, $this->test) ;
		$tviplay->commit(\@iplay_schedule, $this->test) ;
	}

	## Generate report if required
	if ($this->report)
	{
		## Create report
		$tvreport->print_report() ;
	
		# check cron
		Linux::DVB::DVBT::Apps::QuartzPVR::Crontab::check_cron() ;
	}	

	## Output to PHP if required
	if ($this->php)
	{
		if (!$ok)
		{
			if (@requested_recording)
			{
				## Report unscheduled
				$this->php_unscheduled(\@requested_recording) ;
			}
			else
			{
				$this->php_message("Warning", ["Unexpected perl script error"]) ;
			}
		}		
	}


	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
	
	return $ok ;
}

#--------------------------------------------------------------------------------------------
# Display info
#
sub show_info
{
	my $this = shift ;
	my ($opts_href) = @_ ;
	
print STDERR "QuartzPVR::show_info()\n" if $this->debug ;
	
	my %info; 
	
	$info{'NUM_PVRS'} = $this->num_adapters() ;
	
	$info{'PVRS'} = [] ;
	my $devices_aref = $this->devices() ;
	foreach my $device_href (@$devices_aref)
	{
		push @{$info{'PVRS'}}, {
			'adapter'	=> Linux::DVB::DVBT::Apps::QuartzPVR::DVB::device2adapter($device_href), 
			'name'		=> $device_href->{'name'},
		};
	}	
	
Linux::DVB::DVBT::prt_data("Devices=", $devices_aref) if $this->debug ;
Linux::DVB::DVBT::prt_data("Info=", \%info) if $this->debug ;
	
	## Output to PHP if required
	if ($this->php)
	{
		$this->php_info(\%info) ;
	}
	else
	{
		print "INFO:\n" ;
		foreach my $key (sort keys %info)
		{
			print "\t$key: $info{$key}\n" ;
		}
	}
	
}

#============================================================================================
# PHP
#============================================================================================
#



#--------------------------------------------------------------------------------------------
# Format the unscheduled list into a PHP message
#
sub php_unscheduled
{
	my $this = shift ;
	my ($unsched_aref) = @_ ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

	my @msg ;
	push @msg, "Unable to schedule all programs. Unscheduled programs:" ;
	foreach my $prog_href (@$unsched_aref)
	{
		push @msg, "\t$prog_href->{chan} : $prog_href->{title}" ;	
	}
	$this->php_message("Warning", \@msg) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
}

#--------------------------------------------------------------------------------------------
# Format an array of text into a PHP message
#
# Should be of the form:
#
#	<?php
#	$msg_type = "warning" ;
#	$messages = array(
#		"line 1",
#		"another line"
#	) ;
#	?>
#
sub php_message
{
	my $this = shift ;
	my ($msg_type, $msg_aref) = @_ ;

	$msg_type ||= "info" ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

	my $php = "<?php\n" ;
	$php .= "\t\$msg_type = \"$msg_type\";\n" ;
	$php .= "\t\$messages = array(\n" ;
	foreach my $text (@$msg_aref)
	{
		$php .= "\t\t\"$text\",\n" ;
	}
	$php .= "\t) ;\n" ;
	$php .= "?>\n\n" ;
	
	print $php ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
}

#--------------------------------------------------------------------------------------------
# Format a HASH (consisting of key/scalar value pairs)into PHP
#
# Should be of the form:
#
#	<?php
#	$key1 = "scalar1" ;
#	...
#	?>
#
sub php_var
{
	my $this = shift ;
	my ($var) = @_ ;

print STDERR "QuartzPVR::php_var($var)\n" if $this->debug ;

	my $php = "" ;
	if (!ref($var))
	{
		$php .= "\"$var\"" ;
	}
	elsif (ref($var) eq 'ARRAY')
	{
		$php .= " array( " ;
		for (my $i=0; $i < @$var; ++$i)
		{
			$php .= ", " if $i ;
			$php .= $this->php_var($var->[$i]) ;
		}
		$php .= " )\n" ;
	}
	elsif (ref($var) eq 'HASH')
	{
		$php .= " array( " ;
		
		my $i = 0 ;
		foreach my $key (sort keys %$var)
		{
			$php .= ", " if $i++ ;
			$php .= "'$key'=>" ;
			$php .= $this->php_var($var->{$key}) ;
		}
		$php .= " )\n" ;
	}
	
print STDERR "QuartzPVR::php_var($var) - done : php=$php\n" if $this->debug ;

	return $php ;
}



#--------------------------------------------------------------------------------------------
# Format a HASH (consisting of key/scalar value pairs)into PHP
#
# Should be of the form:
#
#	<?php
#	$key1 = "scalar1" ;
#	...
#	?>
#
sub php_info
{
	my $this = shift ;
	my ($hash_ref) = @_ ;

print STDERR "QuartzPVR::php_info()\n" if $this->debug ;
	
	my $php = "<?php\n" ;
	foreach my $key (sort keys %$hash_ref)
	{
		$php .= "\$$key = " ;
		$php .= $this->php_var($hash_ref->{$key}) ;
		$php .= ";\n" ;
	}

	$php .= "?>\n\n" ;

print STDERR "QuartzPVR::php_info() - done : php=$php\n" if $this->debug ;
	
	print $php ;
}




# ============================================================================================
# END OF PACKAGE
1;

__END__

=back

=head1 ACKNOWLEDGEMENTS

=head2 jQuery

This program uses the jQuery Javascript library:

 * jQuery JavaScript Library v1.4
 * http://jquery.com/
 *
 * Copyright 2010, John Resig
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://docs.jquery.com/License
 *
 * Includes Sizzle.js
 * http://sizzlejs.com/
 * Copyright 2010, The Dojo Foundation
 * Released under the MIT, BSD, and GPL Licenses.
 *
 * Date: Wed Jan 13 15:23:05 2010 -0500


=head1 AUTHOR

Steve Price

Please report bugs using L<http://rt.cpan.org>.

=head1 BUGS

None that I know of!

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Steve Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

