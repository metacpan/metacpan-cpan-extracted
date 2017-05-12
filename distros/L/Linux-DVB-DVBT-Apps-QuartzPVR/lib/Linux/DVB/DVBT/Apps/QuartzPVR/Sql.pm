package Linux::DVB::DVBT::Apps::QuartzPVR::Sql ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Sql - (MySql) database access

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

our $VERSION = "1.011" ;

#============================================================================================
# USES
#============================================================================================
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Time ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(Linux::DVB::DVBT::Apps::QuartzPVR::Base::Object) ; 

#============================================================================================
# GLOBALS
#============================================================================================

my %FIELDS = (
	'sql'			=> undef,		# set to Database handler object
	
	'database'		=> undef,		# Database name
	'tbl_recording'	=> undef,		# database table for recordings requests
	'tbl_listings'	=> undef,		# database table for tvguide listings
	'tbl_schedule'	=> undef,		# database table for resulting scheduled recordings
	'tbl_multirec'	=> undef,		# database table for multiplex recordings
	'tbl_iplay'		=> undef,		# database table for get_iplayer scheduled recordings
	'tbl_chans'		=> undef,		# database table for list of channels used with EPG
	'tbl_recorded'	=> undef,		# database table for recorded programs
	
	# record levels for IPLAY-related recordings. The order is of the form:
	#
	#	|	DVBT
	#	|	Fuzzy
	#	|	...
	#	v	DVBT+IPLAY	|
	#		IPLAY		v
	#
	# Recordings >0 AND < IPLAY all have DVB-T type recordings (i.e. need to be scheduled onto a DVB adapter)
	# Recordings >= DVBT+ILPAY all have IPLAY type recordings (i.e. need to be scheduled to use get_iplayer)
	#
	'rec_dvbt_iplay'=> undef,	# record level for DVBT+IPLAY
	'rec_iplay'		=> undef,	# record level for IPLAY 
	
	'user'			=> '',
	'password'		=> '',
	
	# internal
	'sql_vars'	=> {},
	
	'today'		=> undef,
) ;

# Map from DateManip day of week to MySql day of week (1=sun, 2=mon, .. 7=sat)
my %SQL_DOW = (
	'Sun'	=> 1,
	'Mon'	=> 2,
	'Tue'	=> 3,
	'Wed'	=> 4,
	'Thu'	=> 5,
	'Fri'	=> 6,
	'Sat'	=> 7,
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
	my $today = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2date($today_dt) ;
	$this->today($today) ;
	

	return($this) ;
}



#============================================================================================
# CLASS METHODS 
#============================================================================================

#-----------------------------------------------------------------------------

=item C<init_class([%args])>

Initialises the object class variables. Creates a class instance so that these
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

#	SELECT schedule.rid, schedule.priority, listings.*
#	FROM schedule,listings
#	where (record > 0)
#	and (schedule.pid = listings.pid)


#---------------------------------------------------------------------------------------------------
sub init_sql
{
	my $this = shift ;
	
	my $sql = $this->sql() ;
	my $sql_vars_href = $this->sql_vars ;
	my $database = $this->database ;
	my $tbl_recording = $this->tbl_recording ;
	my $tbl_listings = $this->tbl_listings ;
	my $tbl_schedule = $this->tbl_schedule ;
	my $tbl_multirec = $this->tbl_multirec ;
	my $tbl_iplay = $this->tbl_iplay ;
	my $tbl_chans = $this->tbl_chans ;
	my $tbl_recorded = $this->tbl_recorded ;
	
	my $rec_dvbt_iplay = $this->rec_dvbt_iplay ;
	my $rec_iplay = $this->rec_iplay ;
	
	my $today = $this->today ;
	
	my $RECMASK = $Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::REC_MASK ;
	my $REC_NONE = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('none') ;
	my $REC_ONCE = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types_lookup('once') ;
	

	# Set up database access
	$sql->set(
			'database'	=> $database,
			'user'		=> $this->user,
			'password'	=> $this->password,
			'debug'		=> 0,  ## $this->debug,
			
			'prepare'	=> {

				# Select the complete channels table
				'select_channels'		=> {
					'table'		=> $tbl_chans,
					'where'		=> "`show`>0",
				}, # 'select'


				##-----------------------------------------------------------------------------
				## Recording 
				'delete_old_recording'		=> {
					'table'		=> $tbl_recording,
					'where'		=> "`record`=$REC_NONE OR ( (record&$RECMASK=$REC_ONCE) AND `date`<'$today' ) ",
				}, 
				
				'delete_recording'		=> {
					'table'		=> $tbl_recording,
					'where'		=> {
						'vars'		=> [qw/id/],
						'vals'		=> $sql_vars_href,
					},
				}, 

				'select_recording'		=> {
					'table'		=> $tbl_recording,
					'where'		=> "`record`>$REC_NONE",
				}, # 'select'


				# Select all recordings (ignore just IPLAY recordings)
				'select_dvbt_recording'		=> {
					'table'		=> $tbl_recording,
					'where'		=> "`record`>$REC_NONE and `record`<$rec_iplay",
				}, # 'select'

				'select_iplay_recording'	=> {
					'table'		=> $tbl_recording,
					'where'		=> "`record`>=$rec_dvbt_iplay",
				}, # 'select'

				# get last insert id
				'select_latest_recording'		=> {
					'sql'		=> 	"SELECT id ".
									"FROM $tbl_recording ".
									"ORDER BY id DESC ".
									"LIMIT 1 ".
									"",
				}, # 'select'



				'insert_recording'		=> {
					'table'		=> $tbl_recording,
					'vars'		=> [qw/pid channel title date start duration record tva_series priority pathspec/],
					'vals'		=> $sql_vars_href,
				}, 

				'update_recording'	=> {
					'table'		=> $tbl_recording,
					'vars'		=> [qw/pid channel title date start duration record tva_series priority pathspec/],
					'vals'		=> $sql_vars_href,
					'where'		=> {
						'vars'		=> [qw/id/],
						'vals'		=> $sql_vars_href
					}, 
					'limit'	=> 1,
				}, 


				##-----------------------------------------------------------------------------
				## Track recorded programs
				
				#  *id int(11) NOT NULL AUTO_INCREMENT,
				#  pid varchar(128) NOT NULL,
				#  rid int(11) NOT NULL COMMENT 'Record ID',
				#  *ipid varchar(128) NOT NULL DEFAULT '-' COMMENT 'IPLAY: The IPLAYER id (e.g. b00r4wrl)',
				#  rectype enum('dvbt','iplay') NOT NULL COMMENT 'Recording type',
				#  title varchar(128) NOT NULL,
				#  text varchar(255) NOT NULL DEFAULT '',
				#  date date NOT NULL,
				#  start time NOT NULL,
				#  duration time NOT NULL,
				#  channel varchar(128) NOT NULL,
				#  adapter tinyint(8) NOT NULL DEFAULT '0' COMMENT 'DVB adapter number',
				#  type enum('video','audio') NOT NULL DEFAULT 'video' COMMENT 'Type of recording',
				#  record int(11) NOT NULL COMMENT '[0=no record; 1=once; 2=weekly; 3=daily; 4=all(this channel); 5=all, 6=series] + [DVBT=0, FUZZY=0x20 (32), DVBT+IPLAY=0xC0 (192), IPLAY=0xE0 (224)] ',
				#  priority int(11) NOT NULL COMMENT 'Set priority of recording: 1 is highest; 100 is lowest',
				#  file varchar(255) NOT NULL COMMENT 'Recorded filename',
				#  *changed timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Last modification date/time',
				#  *status set('started','recorded','error','repaired','mp3tag','split','complete') NOT NULL DEFAULT '' COMMENT 'State of recording',
				#  *statErrors int(11) NOT NULL DEFAULT '0' COMMENT 'Recording error count',
				#  *statOverflows int(11) NOT NULL DEFAULT '0' COMMENT 'Recording overflow count',
				#  *statTimeslipStart int(11) NOT NULL DEFAULT '0' COMMENT 'Seconds timeslipped start of recording',
				#  *statTimeslipEnd int(11) NOT NULL DEFAULT '0' COMMENT 'Seconds timeslipped recordign end',
				#  *errorText varchar(255) NOT NULL DEFAULT '' COMMENT 'Summary of any errors',
				#
				# * has default 

				'insert_recorded'		=> {
					'table'		=> $tbl_recorded,
					'vars'		=> [qw/pid rid rectype title text date start duration channel adapter type record priority file/],
					'vals'		=> $sql_vars_href,
				}, 

				'update_recorded'		=> {
					'table'		=> $tbl_recorded,
					'vars'		=> [qw/pid rid rectype title text date start duration channel adapter type record priority file  genre tva_series tva_prog/],
					'vals'		=> $sql_vars_href,
					'where'		=> {
						'vars'		=> [qw/pid rectype/],
						'vals'		=> $sql_vars_href,
					},
				}, 

				'delete_recorded'		=> {
					'table'		=> $tbl_recorded,
					'where'		=> {
						'vars'		=> [qw/pid rectype/],
						'vals'		=> $sql_vars_href,
					},
				}, 

				'select_recorded'		=> {
					'table'		=> $tbl_recorded,
					'where'		=> {
						'vars'		=> [qw/pid rectype/],
						'vals'		=> $sql_vars_href,
					},
				}, 

				##-----------------------------------------------------------------------------
				## Schedule
				
				'select_schedule'		=> {
					'sql'		=> 	"SELECT $tbl_schedule.rid, $tbl_schedule.priority, $tbl_schedule.adapter, ".
									"  $tbl_schedule.record, $tbl_schedule.multid, $tbl_listings.*, $tbl_chans.chan_type ".
									"FROM $tbl_schedule,$tbl_listings,$tbl_chans ".
									"WHERE (record > $REC_NONE) ".
									"AND ($tbl_schedule.pid = $tbl_listings.pid) ".
									"AND ($tbl_schedule.channel = $tbl_chans.channel) ".
									"",
				}, # 'select'


				# NOTE: start/date are only for debug purposes!
				'insert_schedule'		=> {
					'table'		=> $tbl_schedule,
					'vars'		=> [qw/pid rid channel record adapter priority multid     date start/],
					'vals'		=> $sql_vars_href,
				}, # 'insert'

				##-----------------------------------------------------------------------------
				## Iplay
				
				'select_iplay'		=> {
					'sql'		=> 	"SELECT $tbl_iplay.pid, $tbl_iplay.rid, $tbl_iplay.record, $tbl_iplay.date, " .
									"  $tbl_iplay.start, $tbl_iplay.channel, $tbl_iplay.prog_pid, " .
									"  $tbl_listings.title, $tbl_listings.duration, $tbl_listings.text, " .
									"  $tbl_listings.date as prog_date, $tbl_listings.start as prog_start, " .
									"  $tbl_chans.chan_type ".
									"FROM $tbl_iplay,$tbl_listings,$tbl_chans ".
									"WHERE (record > $REC_NONE) ".
									"AND ($tbl_iplay.prog_pid = $tbl_listings.pid) ".
									"AND ($tbl_iplay.channel = $tbl_chans.channel) ".
									"",
				}, # 'select'


				'insert_iplay'		=> {
					'table'		=> $tbl_iplay,
					'vars'		=> [qw/pid prog_pid rid channel record date start/],
					'vals'		=> $sql_vars_href,
				}, # 'insert'


				##-----------------------------------------------------------------------------
				## Multirec
				
				'insert_multirec'		=> {
					'table'		=> $tbl_multirec,
					'vars'		=> [qw/multid date start duration adapter/],
					'vals'		=> $sql_vars_href,
				}, # 'insert'


				##-----------------------------------------------------------------------------
				## Listings

				# NOTE: Listings pids contain the date (since I created them) so we don't need to add the "date>current_date" check
				# This allows us to go back a few days and recording recordings based on previous progs even when we can't see the
				# newer ones (e.g. if they've been postponed due to sport etc.)
				'select_prog'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'vars'	=> [qw/channel pid title/],
						'vals'	=> $sql_vars_href,
					}
				},

				'select_prog_pid'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'vars'	=> [qw/pid/],
						'vals'	=> $sql_vars_href,
					}
				},


				'select_once'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'sql'	=> "`channel`=?
									AND `title` like ?
									AND `date`=? 
									AND (`start`>=? AND `start`<=?)",
						'vars'	=> [qw/channel title date start_min start_max/],
						'vals'	=> $sql_vars_href,
					},
					'limit' => 1,
				},

				'select_daily'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'sql'	=> "`channel`=?
									AND `title` like ?
									AND (`start`>=? AND `start`<=?)",
						'vars'	=> [qw/channel title start_min start_max/],
						'vals'	=> $sql_vars_href,
					},
					'order' => "`date`,`start`",
				},

				'select_weekly'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'sql'	=> "`channel`=?
									AND `title` like ?
									AND DAYOFWEEK(`date`)=?
									AND (`start`>=? AND `start`<=?)",
						'vars'	=> [qw/channel title dayofweek start_min start_max/],
						'vals'	=> $sql_vars_href,
					},
					'order' => "`date`,`start`",
				},

				'select_multi'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'sql'	=> "`channel`=?
									AND `title` like ?",
						'vars'	=> [qw/channel title/],
						'vals'	=> $sql_vars_href,
					},
					'order' => "`date`,`start`",
				},

				'select_all'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'sql'	=> "`title` like ?",
						'vars'	=> [qw/title/],
						'vals'	=> $sql_vars_href,
					},
					'order' => "`date`,`start`",
				},
				
				'select_series'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'vars'	=> [qw/channel tva_series/],
						'vals'	=> $sql_vars_href,
					},
					'order' => "`date`,`start`",
				},


				## List of dates from the one specified to the end of the EPG
				## (Used to create daily updates)
				'select_listings_days'	=> {
					'table'	=> $tbl_listings,
					'where' => {
						'sql'	=> "`date`>=? 
									group by date",
						'vars'	=> [qw/date/],
						'vals'	=> $sql_vars_href,
					},
					'order' => "`date`",
				},

				
				
			}, # 'prepare'
	) ;

}

#---------------------------------------------------------------------------------------------------
# copy contents of hash into sql vars hash
sub sql_prepare_vals
{
	my $this = shift ;
	my ($href) = @_ ;
	
	my $sql_vars_href = $this->sql_vars ;
	
	# clear out existing
	foreach my $key (keys %$sql_vars_href)
	{
		$sql_vars_href->{$key} = "" ;
	}
	
	# copy over new set
	foreach my $key (keys %$href)
	{
		$sql_vars_href->{$key} = $href->{$key} ;
	}
}

#---------------------------------------------------------------------------------------------------
# convert date to day of week in Sql format
sub dayofweek
{
	my $this = shift ;
	my ($dt) = @_ ;

	return $SQL_DOW{Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2dayname($dt)} ;
}

#============================================================================================
# QUERIES
#============================================================================================
#

#---------------------------------------------------------------------------------------------------
# Return the complete table of useable channels
sub select_channels
{
	my $this = shift ;
	
print "\n\n[select_channels]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	my @chans = $this->sql->sth_query_all('select_channels') ;

$this->prt_data("[select_chans] results=", \@chans) if $this->debug ;
$this->sql->debug(0) ;

	# Convert into a HASH
	my %channels ;
	foreach my $chan_href (@chans)
	{
		# channel (Channel name used by DVB-T)	
		# display_name (Displayed channel name)	????
		# chan_num (Channel number)	
		# chan_type (TV or Radio)	
		# show
		my $chan = $chan_href->{'channel'} ;
		$channels{$chan} = {
			'name'		=> $chan_href->{'display_name'},
			'lcn'		=> $chan_href->{'chan_num'},
			'type'		=> $chan_href->{'chan_type'}
		};
	}

	return \%channels ;	
}



#---------------------------------------------------------------------------------------------------
# Return ALL requested recordings 
sub select_recording
{
	my $this = shift ;
	
print "\n\n[select_recording]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	my @recordings = $this->sql->sth_query_all('select_recording') ;

$this->prt_data("[select_recording] results=", \@recordings) if $this->debug ;
$this->sql->debug(0) ;

	return @recordings ;	
}

#---------------------------------------------------------------------------------------------------
# Return only DVBT recordings
sub select_dvbt_recording
{
	my $this = shift ;
	
print "\n\n[select_dvbt_recording]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	my @recordings = $this->sql->sth_query_all('select_dvbt_recording') ;

$this->prt_data("[select_dvbt_recording] results=", \@recordings) if $this->debug ;
$this->sql->debug(0) ;

	return @recordings ;	
}

#---------------------------------------------------------------------------------------------------
# Return only IPLAY recordings
sub select_iplay_recording
{
	my $this = shift ;
	
print "\n\n[select_iplay_recording]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	my @recordings = $this->sql->sth_query_all('select_iplay_recording') ;

$this->prt_data("[select_iplay_recording] results=", \@recordings) if $this->debug ;
$this->sql->debug(0) ;

	return @recordings ;	
}

#---------------------------------------------------------------------------------------------------
# Delete a specific recording
sub delete_recording
{
	my $this = shift ;
	my ($rid) = @_ ;
	
print "\n\n[delete_recording $rid]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	# prepare search vars
	$this->sql_prepare_vals({'id' => $rid}) ;

	# do delete
	$this->sql->sth_query('delete_recording') ;
$this->sql->debug(0) ;
	
}

#---------------------------------------------------------------------------------------------------
# Insert new recording
sub insert_recording
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
print "\n\n[insert_recording]\n" if $this->debug ;
$this->sql->debug($this->debug) ;


	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('insert_recording') ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[insert_recording] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# do insert
	$this->sql->sth_query('insert_recording') ;

# Don't know why, but this doesn't work!	
#	# get insert id
#	my $dbh = $this->sql->connect() ;
#	my $rid = $dbh->{'mysql_insertid'} ;
#print "dbh=$dbh rid=$rid\n" if $this->debug ;

	# get insert id
	my $rid = -2 ;
	my @recordings = $this->sql->sth_query_all('select_latest_recording') ;
	if (@recordings)
	{
		$rid = $recordings[0]{'id'} ;
	}

print " + rid=$rid\n" if $this->debug ;
	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "inserted - new rid $rid") ;
$this->sql->debug(0) ;
	
	return $rid ;
}

#---------------------------------------------------------------------------------------------------
# Update recording
sub update_recording
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
print "\n\n[update_recording]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('update_recording') ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[update_recording] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# do delete
	$this->sql->sth_query('update_recording') ;
$this->sql->debug(0) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'updated') ;
}

#---------------------------------------------------------------------------------------------------
# Return the scheduled recordings 
sub select_scheduled
{
	my $this = shift ;
	
print "\n\n[select_scheduled]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	my @recordings = $this->sql->sth_query_all('select_schedule') ;
	
$this->prt_data("[select_scheduled] results=", \@recordings) if $this->debug ;
$this->sql->debug(0) ;

	return @recordings ;	
}

#---------------------------------------------------------------------------------------------------
# Return the scheduled iplay recordings 
sub select_iplay
{
	my $this = shift ;
	
print "\n\n[select_iplay]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	my @recordings = $this->sql->sth_query_all('select_iplay') ;
	
$this->prt_data("[select_iplay] results=", \@recordings) if $this->debug ;
$this->sql->debug(0) ;

	return @recordings ;	
}

#---------------------------------------------------------------------------------------------------
# Select a single program based on channel/pid/title
sub select_program
{
	my $this = shift ;
	my ($rec_href) = @_ ;

$this->sql->debug($this->debug) ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;
	
my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[select_prog] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# perform query
	my @listings = $this->sql->sth_query_all('select_prog') ;

	my $sth_href = $this->sql->_sth_record('select_prog') ;
	my $sql_query = $sth_href->{'query'} ;
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, {
		'msg' 	=> "sql : $sql_query",
	}) ;

$this->prt_data(" + Single : ", \@listings) if $this->debug>=2 ;	
$this->sql->debug(0) ;
	
	# return results
	return @listings ;
}

#---------------------------------------------------------------------------------------------------
# Select a single program based on pid
sub select_program_pid
{
	my $this = shift ;
	my ($rec_href) = @_ ;

$this->sql->debug($this->debug) ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;
	
my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[select_prog_pid] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# perform query
	my @listings = $this->sql->sth_query_all('select_prog_pid') ;

$this->prt_data(" + Single : ", \@listings) if $this->debug>=2 ;	
$this->sql->debug(0) ;
	
	# return results
	return @listings ;
}

#---------------------------------------------------------------------------------------------------
# Perform search for all matching programs
sub select_listings
{
	my $this = shift ;
	my ($record_type, $rec_href) = @_ ;

$this->sql->debug($this->debug) ;
		
	# Get sql query name
	my $query_name = Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::query_name($record_type) ;
print "Record=$record_type : Query name=$query_name\n" if $this->debug>=2 ;	

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;
	
my $sql_vars_href = $this->sql_vars ;
$this->prt_data("sched_href=", $rec_href) if $this->debug ;
$this->prt_data("[$query_name] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# perform query
	my @listings = $this->sql->sth_query_all($query_name) ;

$this->prt_data(" + Query=$query_name, Sched=", $rec_href) if $this->debug>=2 ;	
$this->prt_data(" + Windowed : ", \@listings) if $this->debug>=2 ;	
$this->sql->debug(0) ;
	
	# return results
	return @listings ;
}

#---------------------------------------------------------------------------------------------------
# Get a list of all dates from specified to the end of the EPG
sub select_listings_days
{
	my $this = shift ;
	my ($date) = @_ ;

$this->sql->debug($this->debug) ;
		
	# prepare search vars
	$this->sql_prepare_vals({'date' => $date}) ;
	
my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[select_listings_days] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# perform query
	my @listings = $this->sql->sth_query_all('select_listings_days') ;

$this->prt_data(" + Listings : ", \@listings) if $this->debug>=2 ;	
$this->sql->debug(0) ;
	
	# create a list of just the dates
	my @days ;
	foreach my $entry_href (@listings)
	{
		push @days, $entry_href->{'date'} ;
	}
	
	# return results
	return @days ;
}



#---------------------------------------------------------------------
# Gets the latest scheduled recordings list from the database and also
# sets up various date/time values for later use
sub update_schedule_table
{
	my $this = shift ;
	my ($recording_aref) = @_ ;

$this->sql->debug($this->debug) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('update_schedule_table') ;

	my $tbl_schedule = $this->tbl_schedule ;
	my $tbl_multirec = $this->tbl_multirec ;

$this->prt_data("[insert_schedule] recording_aref=", $recording_aref) if $this->debug ;
	
	# clear tables
	$this->sql->do("TRUNCATE TABLE $tbl_schedule") ;
	$this->sql->do("TRUNCATE TABLE $tbl_multirec") ;

	# Insert a line for each program
	foreach my $href (@$recording_aref)
	{
		my @recs = ($href) ;
		if ($href->{'type'} eq 'multiplex')
		{
			# insert multiplex container
			$this->sql_prepare_vals($href) ;
	
	my $sql_vars_href = $this->sql_vars ;
	$this->prt_data("[insert_multirec] sql_vars_href=", $sql_vars_href) if $this->debug ;
	
			$this->sql->sth_query('insert_multirec') ;
	
			# insert the multiplex programs
			@recs = @{$href->{'multiplex'}} ;
		}
		
		foreach my $rec_href (@recs)
		{
			# insert program details
			$this->sql_prepare_vals($rec_href) ;
	
	my $sql_vars_href = $this->sql_vars ;
	$this->prt_data("[insert_schedule] sql_vars_href=", $sql_vars_href) if $this->debug ;
	
			$this->sql->sth_query('insert_schedule') ;
	
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'updated') ;
		}
	}
	
	
	## Update recording recording - prune out old jobs
	$this->sql->sth_query('delete_old_recording') ;

$this->sql->debug(0) ;

}

#---------------------------------------------------------------------
# Gets the latest scheduled iplay recordings list from the database and also
# sets up various date/time values for later use
sub update_iplay_table
{
	my $this = shift ;
	my ($recording_aref) = @_ ;

$this->sql->debug($this->debug) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('update_iplay_table') ;

	my $tbl_iplay = $this->tbl_iplay ;

$this->prt_data("[insert_iplay] recording_aref=", $recording_aref) if $this->debug ;
	
	# clear tables
	$this->sql->do("TRUNCATE TABLE $tbl_iplay") ;

	# Insert a line for each program
	foreach my $rec_href (@$recording_aref)
	{
		# insert program details
		$this->sql_prepare_vals($rec_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[insert_iplay] sql_vars_href=", $sql_vars_href) if $this->debug ;

		$this->sql->sth_query('insert_iplay') ;

		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, 'updated') ;
	}

$this->sql->debug(0) ;

}

#---------------------------------------------------------------------------------------------------
# Insert new recorded entry - tracks recordings
sub insert_recorded
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
print "\n\n[insert_recorded]\n" if $this->debug ;
$this->sql->debug($this->debug) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('insert_recorded') ;

	# prepare search vars
	my $vars_href = {
		%$rec_href,
	} ;
	$this->sql_prepare_vals($vars_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[insert_recorded] sql_vars_href=", $sql_vars_href) if $this->debug ;

	# do insert
	$this->sql->sth_query('insert_recorded') ;

$this->sql->debug(0) ;
	
}

#---------------------------------------------------------------------------------------------------
# Delete existing recorded entry - tracks recordings
sub delete_recorded
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
print "\n\n[delete_recorded] pid=$rec_href->{pid}, rectype=$rec_href->{rectype}\n" if $this->debug ;
$this->sql->debug($this->debug) if $this->debug >= 2 ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('delete_recorded') ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[delete_recorded] sql_vars_href=", $sql_vars_href) if $this->debug >= 2 ;

	# do delete
	$this->sql->sth_query('delete_recorded') ;

$this->sql->debug(0) if $this->debug >= 2 ;
	
}

#---------------------------------------------------------------------------------------------------
# Check for existence of recorded entry - tracks recordings
sub select_recorded
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
print "\n\n[select_recorded] pid=$rec_href->{pid}, rectype=$rec_href->{rectype}\n" if $this->debug ;
$this->sql->debug($this->debug) if $this->debug >= 2 ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('select_recorded') ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[select_recorded] sql_vars_href=", $sql_vars_href) if $this->debug >= 2 ;

	# do select
	my @list = $this->sql->sth_query_all('select_recorded') ;

$this->prt_data("[select_recorded] results=", \@list) if $this->debug ;
$this->sql->debug(0) ;

	return \@list ;	
}

#---------------------------------------------------------------------------------------------------
# Update an existing recorded entry - tracks recordings
sub update_recorded
{
	my $this = shift ;
	my ($rec_href) = @_ ;
	
print "\n\n[update_recorded] pid=$rec_href->{pid}, rectype=$rec_href->{rectype}\n" if $this->debug ;
$this->sql->debug($this->debug) if $this->debug >= 2 ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('update_recorded') ;

	# prepare search vars
	$this->sql_prepare_vals($rec_href) ;

my $sql_vars_href = $this->sql_vars ;
$this->prt_data("[update_recorded] sql_vars_href=", $sql_vars_href) if $this->debug >= 2 ;

	# do update
	$this->sql->sth_query('update_recorded') ;

$this->sql->debug(0) if $this->debug >= 2 ;
	
}



# ============================================================================================
# END OF PACKAGE
1;

__END__


