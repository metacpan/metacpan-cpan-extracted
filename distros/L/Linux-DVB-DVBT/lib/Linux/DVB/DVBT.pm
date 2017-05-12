package Linux::DVB::DVBT;

=head1 NAME

Linux::DVB::DVBT - Perl extension for DVB terrestrial recording, epg, and scanning 

=head1 SYNOPSIS

	use Linux::DVB::DVBT;
  
  	# get list of installed adapters
  	my @devices = Linux::DVB::DVBT->device_list() ;
  	foreach (@devices)
  	{
  		printf "%s : adapter number: %d, frontend number: %d\n", 
  			$_->{name}, $_->{adapter_num}, $_->{frontend_num} ;
  	}
  
	# Create a dvb object using the first dvb adapter in the list
	my $dvb = Linux::DVB::DVBT->new() ;
	
	# .. or specify the device numbers
	my $dvb = Linux::DVB::DVBT->new(
		'adapter_num' => 2,
		'frontend_num' => 1,
	) ;


	# Scan for channels - using frequency file
	$dvb->scan_from_file('/usr/share/dvb/dvb-t/uk-Oxford') ;
	
	# Scan for channels - using country code
	$dvb->scan_from_file('GB') ;
	
	# Scan for channels - if scanned before, use previous frequencies
	$dvb->scan_from_previous() ;
	
	# Set channel
	$dvb->select_channel("BBC ONE") ;
	
	# Get EPG data
	my ($epg_href, $dates_href) = $dvb->epg() ;

	# Record 30 minute program (after setting channel using select_channel method)
	$dvb->record('test.ts', 30*60) ;

	## Record multiple programs in parallel (in the same multiplex)
	
		# parse arguments
		my @args = qw/file=itv2.mpeg ch=itv2 len=0:30 event=41140
	   	               file=five.mpeg ch=five len=0:30 off=0:15 event=11134 max_timeslip=2:00
	   	               file=itv1.mpeg ch=itv1 len=0:30 off=0:30
	   	               file=more4.mpeg ch=more4 len=0:05 off=0:15
	   	               file=e4.mpeg ch=e4 len=0:30 off=0:05
	   	               file=ch4+1.mpeg ch='channel4+1' len=1:30 off=0:05/ ;
	   	
		my @chan_spec ;
		$dvb->multiplex_parse(\@chan_spec, @ARGV);
	
		# Select the channel(s)
		$dvb->multiplex_select(\@chan_spec) ;
   	
		# Get multiplex info
		my %multiplex_info = $dvb->multiplex_info() ;

		# Record
		$dvb->multiplex_record(%multiplex_info) ;


	## Release the hardware (to allow a new recording to start)
	$dvb->dvb_close() ;
	

	# show the logical channel numbers
	my $tuning_href = $dvb->get_tuning_info() ;
	my $channels_aref = $dvb->get_channel_list() ;
	
	print "Chans\n" ;
	foreach my $ch_href (@$channels_aref)
	{
		my $chan = $ch_href->{'channel'} ;
		printf "%3d : %-40s %5d-%5d $ch_href->{type}\n", 
			$ch_href->{'channel_num'},
			$chan,
			$tuning_href->{'pr'}{$chan}{'tsid'},
			$tuning_href->{'pr'}{$chan}{'pnr'} ;
	}



=head1 DESCRIPTION

B<Linux::DVB::DVBT> is a package that provides an object interface to any installed Freeview 
tuner cards fitted to a Linux PC. The package supports initial set up (i.e. frequency scanning),
searching for the latest electronic program guide (EPG), and selectign a channel for recording
the video to disk.

=head2 Additional Modules

Along with this module, the following extra modules are provided:

=over 4

=item L<Linux::DVB::DVBT::Config>

Configuration files and data utilities

=item L<Linux::DVB::DVBT::Utils>

Miscellaneous utilities

=item L<Linux::DVB::DVBT::Ffmpeg>

Helper module that wraps up useful L<ffmpeg|http://ffmpeg.org/> calls to post-process recorded files. 

=back


=head2 Logical Channel Numbers (LCNs)

Where broadcast, the scan function will gather the logical channel number information for all of the channels. The scan() method now stores the LCN information
into the config files, and makes the list of channels available through the L</get_channel_list()> method. So you can now get the channel number you
see (and enter) on any standard freeview TV or PVR.

This is of most interest if you want to use the L</epg()> method to gather data to create a TV guide. Generally, you'd like the channel listings
to be sorted in the order to which we've all become used to through TV viewing (i.e. it helps to have BBC1 appear before channel 4!). 


=head2 TVAnytime

New in this version is the gathering of TV Anytime series and program information by the epg function. Where available, you now have a 'tva_series' and 
'tva_program' field in the epg HASH that contains the unique TV Anytime number for the series and program respectfully. This is meant to ensure that 
you can determine the program and series uniquely and allow you to not re-record programs. In reality, I've found that some broadcasters use different
series identifiers even when the same series is shown at a different time!

At present, I use the series identifier to group recordings within a series (I then rename the series directory something more meaningful!). Within a 
series, the program identifier seems to be useable to determine if the program has been recorded before.


=head2 Multiplex Recording

Another new feature in this version is support for multiplex recording (i.e. being able to record multiple streams/programs at the same time, as long as they are all
in the same multiplex). As you can imagine, specifying the recording of multiple programs (many of which will be different lengths and start at 
diffent times) can get quite involved. 

To simplify these tasks in your scripts, I've written various "helpers" that handle parsing command line arguments, through to optionally running
ffmpeg to transcode the recorded files. These are all in addition to the base function that adds a demux filter to the list that will be recorded
(see L</add_demux_filter($pid, $pid_type [, $tsid])>). Feel free to use as much (or as little) of the helper functions as you like - you can always write
your own scripts using add_demux_filter().

For details of the ffmpeg helper functions, please see L<Linux::DVB::DVBT::Ffmpeg>. Obviously, you need to have ffmpeg installed on your system
for any of the functions to work!

To record multiple channels (in the same multiplex) at once, you need something like:

	use Linux::DVB::DVBT;

	## Parse command line
	my @chan_spec ;
	my $error = $dvb->multiplex_parse(\@chan_spec, @ARGV);
	
	## Select the channel(s)
	my %options = (
		'lang'		=> $lang,
		'out'		=> $out,
		'tsid'		=> $tsid,
	) ;
	$error = $dvb->multiplex_select(\@chan_spec, %options) ;
	
	## Get multiplex info
	my %multiplex_info = $dvb->multiplex_info() ;

	## Record
	$dvb->multiplex_record(%multiplex_info) ;

	## Release the hardware (to allow a new recording to start)
	$dvb->dvb_close() ;
	
	## [OPTIONAL] Transcode the recordings (uses ffmpeg helper module)
	$error = $dvb->multiplex_transcode(%multiplex_info) ;

Note, the old L<record()|/record($file, $duration)> function has been re-written to use the same underlying multiplex functions. This means that,
even though you are only recording a single program, you can still use the ffmpeg helper transcode functions after the 
recording has finished. For example:

	## Record
	$dvb->record("$dir$name$ext", $duration) ;
	
	## Release DVB (for next recording)
	$dvb->dvb_close() ;
	
	## Get multiplex info
	my %multiplex_info = $dvb->multiplex_info() ;
	
	## Transcode the recordings (uses ffmpeg helper module)
	$dvb->multiplex_transcode(%multiplex_info) ;
	
	## Display ffmpeg output / warnings / errors
	foreach my $line (@{$multiplex_info{'lines'}})
	{
		info("[ffmpeg] $line") ;
	}
	
	foreach my $line (@{$multiplex_info{'warnings'}})
	{
		info("[ffmpeg] WARN: $line") ;
	}
	
	foreach my $line (@{$multiplex_info{'errors'}})
	{
		info("[ffmpeg] ERROR: $line") ;
	}

Since this is a new feature, I've left access to the original recording method but renamed it L<record_v1()|/record_v1($file, $duration)>. If, for any reason,
you wish to use the original recording method, then you need to change your scripts to call the renamed function. But please contact me if you are
having problems, and I will do my best to fix them. Future releases will eventually drop the old recording method.


=head2 Using UDEV

If, like me, you have more than one adapter fitted and find the order in which the adapters are numbered changes with reboots,
then you may like to use udev to define rules to fix your adapters to known numbers (see L<http://www.mythtv.org/wiki/Device_Filenames_and_udev>
for further details).

To create rules you make a file in /etc/udev/rules.d and call it something like 100-dvb.rules. The rules file then needs to
create a rule for each adapter that creates a link for all of the low-level devices (i.e. the frontend0, dvr0 etc). Each line
matches information about the device (using rules with "=="), then applies some setting rules (signified by using "=") to create
the symlink.

For example, the following:

	 SUBSYSTEM=="dvb", ATTRS{manufacturer}=="Hauppauge", ATTRS{product}=="Nova-T Stick", ATTRS{serial}=="4030521975"

matches a Hauppage Nova-T adapter with serial number "4030521975". Note that this will match B<all> of the devices (dvr0, frontend0 
etc) for this adapter. The "set" rule needs to use some variables to create a link for each device.

The set rule we use actually calls a "program" to edit some variables and output the final string followed by a rule that creates the
symlink:

	PROGRAM="/bin/sh -c 'K=%k; K=$${K#dvb}; printf dvb/adapter101/%%s $${K#*.}'", SYMLINK+="%c"
	
The PROGRAM rule runs the sh shell and manipulates the kernel name string (which will be something like dvb/adapter0/dvr0) and creates
a string with a new adapter number (101 in this case). The SYMLINK rule uses this output (via the %c variable).

Putting this together in a file:

	# /etc/udev/rules.d/100-dvb.rules
	# 
	# To Ientify serial nos etc for a Device call
	# udevadm info -a -p $(udevadm info -q path -n /dev/dvb/adapter0/frontend0)
	#
	
	# Locate 290e at 100
	SUBSYSTEM=="dvb", ATTRS{manufacturer}=="PCTV Systems", ATTRS{product}=="PCTV 290e", PROGRAM="/bin/sh -c 'K=%k; K=$${K#dvb}; printf dvb/adapter100/%%s $${K#*.}'", SYMLINK+="%c"
	
	# Locate Nova-T at 101
	SUBSYSTEM=="dvb", ATTRS{manufacturer}=="Hauppauge", ATTRS{product}=="Nova-T Stick", PROGRAM="/bin/sh -c 'K=%k; K=$${K#dvb}; printf dvb/adapter101/%%s $${K#*.}'", SYMLINK+="%c"

On my system this locates my PCTV DVB-T2 stick at /dev/dvb/adapter100 and my Nova-T stick at /dev/dvb/adapter101.

You can then refer to these devices using the 'adapter_num' field as 100 and 101 (or via the 'adapter' field as '100:0' and '101:0').




=head2 Example Scripts

Example scripts have been provided in the package which illustrate the expected use of the package (and
are useable programs in themeselves). To see the full man page of each script, simply run it with the '-man' option.

=over 4

=item L<dvbt-devices|Linux::DVB::DVBT::..::..::..::script::dvbt-devices>

Shows information about fited DVB-T tuners

=item L<dvbt-scan|Linux::DVB::DVBT::..::..::..::script::dvbt-scan>

Run this by providing the frequency file (usually stored in /usr/share/dvb/dvb-t). If run as root, this will set up the configuration
files for all users. For example:

   $ dvbt-scan /usr/share/dvb/dvb-t/uk-Oxford

NOTE: Frequency files are provided by the 'dvb' rpm package available for most distros

=item L<dvbt-chans|Linux::DVB::DVBT::..::..::..::script::dvbt-chans>

Use to display the current list of tuned channels. Shows them in logical channel number order. The latest version shows information on
the PID numbers for the video, audio, teletext, and subtitle streams that make up each channel.

It also now has the option (-multi) to display the channels grouped into their multiplexes (i.e. their transponder or TSIDs). This becomes
really useful if you want to schedule a multiplex recording and need to check which channels you can record at the same time. 


=item L<dvbt-epg|Linux::DVB::DVBT::..::..::..::script::dvbt-epg>

When run, this grabs the latest EPG information and prints out the program guide:

   $ dvbt-epg

NOTE: This process can take quite a while (it takes around 30 minutes on my system), so please be patient.

=item L<dvbt-record|Linux::DVB::DVBT::..::..::..::script::dvbt-record>

Specify the channel, the duration, and the output filename to record a channel:

   $ dvbt-record "bbc1" spooks.ts 1:00 
   
Note that the duration can be specified as an integer (number of minutes), or in HH:MM format (for hours and minutes)

=item L<dvbt-ffrec|Linux::DVB::DVBT::..::..::..::script::dvbt-ffrec>

Similar to dvbt-record, but pipes the transport stream into ffmpeg and uses that to transcode the data directly into an MPEG file (without
saving the transport stream file).

Specify the channel, the duration, and the output filename to record a channel:

   $ dvbt-ffrec "bbc1" spooks.mpeg 1:00 
   
Note that the duration can be specified as an integer (number of minutes), or in HH:MM format (for hours and minutes)

It's worth mentioning that this relies on ffmpeg operating correctly. Some versions of ffmpeg are fine; others have failed reporting:

  "error, non monotone timestamps"

which appear to be related to piping the in via stdin (running ffmpeg on a saved transport stream file always seems to work) 

=item L<dvbt-multirec|Linux::DVB::DVBT::..::..::..::script::dvbt-multirec>

Record multiple channels at the same time (as long as they are all in the same multiplex).

Specify each recording with a filename, duration, and optional offset start time. Then specify the channel name, or a list of the pids you
want to record. Repeat this for every file you want to record.

For example, you want to record some programs starting at 13:00. The list of programs are:

=over 4

=item * ITV2 start 13:00, duration 0:30

=item * FIVE start 13:15, duration 0:30

=item * ITV1 start 13:30, duration 0:30

=item * More 4 start 13:15, duration 0:05

=item * E4 start 13:05, duration 0:30

=item * Channel 4+1 start 13:05, duration 1:30

=back

To record these (running the script at 13:00) use:

   $ dvbt-multirec file=itv2.mpeg ch=itv2 len=0:30  \
   	               file=five.mpeg ch=five len=0:30 off=0:15 \
   	               file=itv1.mpeg ch=itv1 len=0:30 off=0:30 \
   	               file=more4.mpeg ch=more4 len=0:05 off=0:15 \
   	               file=e4.mpeg ch=e4 len=0:30 off=0:05 \
   	               file=ch4+1.mpeg ch='channel4+1' len=1:30 off=0:05 
   

=back


=head2 HISTORY

I started this package after being lent a Hauppauge WinTV-Nova-T usb tuner (thanks Tim!) and trying to 
do some command line recording. After I'd failed to get most applications to even talk to the tuner I discovered
xawtv (L<http://linux.bytesex.org/xawtv/>), started looking at it's source code and started reading the DVB-T standards.

This package is the result of various expermients and is being used for my web TV listing and program
record scheduling software.

=cut


#============================================================================================
# USES
#============================================================================================
use strict;
use warnings;
use Carp ;

use Cwd qw/realpath/ ;
use File::Basename ;
use File::Path ;
use File::Spec ;
use POSIX qw(strftime);

use Linux::DVB::DVBT::Config ;
use Linux::DVB::DVBT::Utils ;
use Linux::DVB::DVBT::Ffmpeg ;
use Linux::DVB::DVBT::Freq ;
use Linux::DVB::DVBT::Constants ;

#============================================================================================
# EXPORTER
#============================================================================================
require Exporter;
our @ISA = qw(Exporter);

#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '2.20';
our $AUTOLOAD ;

#============================================================================================
# XS
#============================================================================================
require XSLoader;
XSLoader::load('Linux::DVB::DVBT', $VERSION);

#============================================================================================
# CLASS VARIABLES
#============================================================================================

my $DEBUG=0;
my $VERBOSE=0;
my $devices_aref ;

## New device "list"
my $devices_href ;

#============================================================================================


=head2 FIELDS

All of the object fields are accessed via an accessor method of the same name as the field, or
by using the B<set> method where the field name and value are passed as key/value pairs in a HASH

=over 4

=item B<adapter_num> - DVB adapter number

Number of the DVBT adapter. When multiple DVBT adapters are fitted to a machine, they will be numbered from 0 onwards. Use this field to select the adapter.

=item B<frontend_num> - DVB frontend number

A single adapter may have multiple frontends. If so then use this field to select the frontend within the selected adapter.

=item B<adapter> - DVB adapter 

Instead of supplying an individual adapter number and frontend number, you can use this field to supply both using the syntax:

	<adapter number>:<frontend number>

If no frontend number is specified then the firast valid frontend number for that adapter is used.


=item B<frontend_name> - Device path for frontend (set multiplex)

Once the DVBT adapter has been selected, read this field to get the device path for the frontend. It will be of the form: /dev/dvb/adapter0/frontend0

=item B<demux_name> - Device path for demux (select channel within multiplex)

Once the DVBT adapter has been selected, read this field to get the device path for the demux. It will be of the form: /dev/dvb/adapter0/demux0

=item B<dvr_name> - Device path for dvr (video record access)

Once the DVBT adapter has been selected, read this field to get the device path for the dvr. It will be of the form: /dev/dvb/adapter0/dvr0

=item B<debug> - Set debug level

Set this to the required debug level. Higher values give more verbose information.

=item B<devices> - Fitted DVBT adapter list

Read this ARRAY ref to get the list of fitted DVBT adapters. This is equivalent to running the L</device_list()> class method (see L</device_list()> for array format)

=item B<merge> - Merge scan results 

Set this flag before running the scan() method. When set, the scan will merge the new results with any previous scan results (read from the config files)

By default this flag is set (so each scan merge with prvious results). Clear this flag to re-start from fresh - useful when broadcasters change the frequencies.

=item B<frontend_params> - Last used frontend settings 

This is a HASH ref containing the parameters used in the last call to L</set_frontend(%params)> (either externally or internally by this module).

=item B<config_path> - Search path for configuration files

Set to ':' separated list of directories. When the module wants to either read or write configuration settings (for channel frequencies etc) then it uses this field
to determine where to read/write those files from.

By default this is set to:

    /etc/dvb:~/.tv

Which means that the files are read from /etc/dvb if it has been created (by root); or alternatively it uses ~/.tv (which also happens to be where xawtv stores it's files). 
Similarly, when writing files these directories are searched until a writeable area is found (so a user won't be able to write into /etc/dvb).

=item B<tuning> - Channel tuning information

Use this field to read back the tuning parameters HASH ref as scanned or read from the configuration files (see L</scan()> method for format)

This field is only used internally by the object but can be used for debug/information.

=item B<errmode> - Set error handling mode

Set this field to one of 'die' (the default), 'return', or 'message' and when an error occurs that error mode action will be taken.

If the mode is set to 'die' then the application will terminate after printing all of the errors stored in the errors list (see L</errors> field).
When the mode is set to 'return' then the object method returns control back to the calling application with a non-zero status (which is actually the 
current count of errors logged so far). Similalrly, if the mode is set to 'message' then the object method simply returns the error message. 
It is the application's responsibility to handle the errors (stored in  L</errors>) when setting the mode to 'return' or 'message'.

=item B<timeout> - Timeout

Set hardware timeout time in milliseconds. Most hardware will be ok using the default (900ms), but you can use this field to increase
the timeout time. 

=item B<add_si> - Automatically add SI tables

By default, recorded files automatically have the SI tables (the PAT & PMT for the program) recorded along with the
usual audio/video streams. This is the new default since the latest version of ffmpeg refuses to understand the
encoding of any video streams unless this information is added.

If you really want to, you can change this flag to 0 to prevent SI tables being added in all cases.

NOTE: You still get the tables whenever you add subtitles.


=item B<errors> - List of errors

This is an ARRAY ref containing a list of any errors that have occurred. Each error is stored as a text string.

=back

=cut

# List of valid fields
my @FIELD_LIST = qw/dvb 
					adapter
					adapter_num frontend_num
					frontend_name demux_name dvr_name
					debug 
					devices
					channel_list
					frontend_params
					config_path
					tuning
					errmode errors
					merge
					timeout
					prune_channels
					add_si
					
					scan_allow_duplicates
					scan_prefer_more_chans
					
					scan_cb_start
					scan_cb_end
					scan_cb_loop_start
					scan_cb_loop_end
					
					_scan_freqs
					_device_index
					_device_info
					_demux_filters
					_multiplex_info
					_scan_info
					/ ;
my %FIELDS = map {$_=>1} @FIELD_LIST ;

# Default settings
my %DEFAULTS = (
	'adapter'		=> undef,
	'adapter_num'	=> undef,
	'frontend_num'	=> 0,
	
	'frontend_name'	=> undef,
	'demux_name'	=> undef,
	'dvr_name'		=> undef,
	
	'dvb'			=> undef,
	
	# List of channels of the form:
	'channel_list'	=> undef,

	# parameters used to tune the frontend
	'frontend_params' => undef,
	
	# Search path for config dir
	'config_path'	=> $Linux::DVB::DVBT::Config::DEFAULT_CONFIG_PATH,

	# tuning info
	'tuning'		=> undef,
	
	# Information
##	'devices'		=> [],
	
	# Error log
	'errors'		=> [],
	'errmode'		=> 'die',
	
	# merge scan results with existing
	'merge'			=> 1,
	
	# scan callback
	'scan_cb_start'			=> undef,
	'scan_cb_end'			=> undef,
	'scan_cb_loop_start'	=> undef,
	'scan_cb_loop_end'		=> undef,
	
	# timeout period ms
	'timeout'		=> 900,

	# remove un-tuneable channels
	'prune_channels'	=> 1,
	
	# Automatically add SI tables to recording
	'add_si'		=> 1,

	# scan merge options
	'scan_allow_duplicates'	=> 0,
	'scan_prefer_more_chans' => 0,
	
	######################################
	# Internal
	
	# scanning driven by frequency file
	'_scan_freqs'		=> 0,
	
	# which device in the device list are we
	'_device_index' 	=> undef,
	
	# ref to this device's info from the device list
	'_device_info'		=> undef,
	
	# list of demux filters currently active
	'_demux_filters'	=> [],
	
	# list of multiplex recordings scheduled
	'_multiplex_info'	=> {},
	
	# reasons for scan choosing the freq it does for each chan
	'_scan_info'		=> {},
) ;

# Frequency must be at least 100 MHz
# The Stockholm agreement of 1961 says:
#   Band III  : 174 MHz - 230 MHz
#   Band IV/V : 470 MHz - 826 MHz
#
# Current dvb-t files range: 177.5 MHz - 858 MHz
#
# So 100 MHz allows for country "variations"!
#
my $MIN_FREQ = 100000000 ;

# Maximum PID value
my $MAX_PID = 0x2000 ;

# code value to use 'auto' setting
my $AUTO = 999 ;

#typedef enum fe_code_rate {
#	FEC_NONE = 0,
#	FEC_1_2,
#	FEC_2_3,
#	FEC_3_4,
#	FEC_4_5,
#	FEC_5_6,
#	FEC_6_7,
#	FEC_7_8,
#	FEC_8_9,
#	FEC_AUTO
#} fe_code_rate_t;
#
#    static char *ra_t[8] = {  ???
#	[ 0 ] = "12",
#	[ 1 ] = "23",
#	[ 2 ] = "34",
#	[ 3 ] = "56",
#	[ 4 ] = "78",
#    };
my %FE_CODE_RATE = (
	'NONE'		=> 0,
	'1/2'		=> 12,
	'2/3'		=> 23,
	'3/4'		=> 34,
	'4/5'		=> 45,
	'5/6'		=> 56,
	'6/7'		=> 67,
	'7/8'		=> 78,
	'8/9'		=> 89,
	'AUTO'		=> $AUTO,
) ;

#
#typedef enum fe_modulation {
#	QPSK,
#	QAM_16,
#	QAM_32,
#	QAM_64,
#	QAM_128,
#	QAM_256,
#	QAM_AUTO,
#	VSB_8,
#	VSB_16
#} fe_modulation_t;
#
#    static char *co_t[4] = {
#	[ 0 ] = "0",
#	[ 1 ] = "16",
#	[ 2 ] = "64",
#    };
#
my %FE_MOD = (
	'QPSK'		=> 0,
	'QAM16'		=> 16,
	'QAM32'		=> 32,
	'QAM64'		=> 64,
	'QAM128'	=> 128,
	'QAM256'	=> 256,
	'AUTO'		=> $AUTO,
) ;


#typedef enum fe_transmit_mode {
#	TRANSMISSION_MODE_2K,
#	TRANSMISSION_MODE_8K,
#	TRANSMISSION_MODE_AUTO
#} fe_transmit_mode_t;
#
#    static char *tr[2] = {
#	[ 0 ] = "2",
#	[ 1 ] = "8",
#    };
my %FE_TRANSMISSION = (
	'2k'		=> 2,
	'8k'		=> 8,
	'AUTO'		=> $AUTO,
) ;

#typedef enum fe_bandwidth {
#	BANDWIDTH_8_MHZ,
#	BANDWIDTH_7_MHZ,
#	BANDWIDTH_6_MHZ,
#	BANDWIDTH_AUTO
#} fe_bandwidth_t;
#
#    static char *bw[4] = {
#	[ 0 ] = "8",
#	[ 1 ] = "7",
#	[ 2 ] = "6",
#    };
my %FE_BW = (
	'8MHz'		=> 8,
	'7MHz'		=> 7,
	'6MHz'		=> 6,
	'AUTO'		=> $AUTO,
) ;

#
#typedef enum fe_guard_interval {
#	GUARD_INTERVAL_1_32,
#	GUARD_INTERVAL_1_16,
#	GUARD_INTERVAL_1_8,
#	GUARD_INTERVAL_1_4,
#	GUARD_INTERVAL_AUTO
#} fe_guard_interval_t;
#
#    static char *gu[4] = {
#	[ 0 ] = "32",
#	[ 1 ] = "16",
#	[ 2 ] = "8",
#	[ 3 ] = "4",
#    };
my %FE_GUARD = (
	'1/32'		=> 32,
	'1/16'		=> 16,
	'1/8'		=> 8,
	'1/4'		=> 4,
	'AUTO'		=> $AUTO,
) ;

#typedef enum fe_hierarchy {
#	HIERARCHY_NONE,
#	HIERARCHY_1,
#	HIERARCHY_2,
#	HIERARCHY_4,
#	HIERARCHY_AUTO
#} fe_hierarchy_t;
#
#    static char *hi[4] = {
#	[ 0 ] = "0",
#	[ 1 ] = "1",
#	[ 2 ] = "2",
#	[ 3 ] = "4",
#    };
#
my %FE_HIER = (
	'NONE'		=> 0,
	'1'			=> 1,
	'2'			=> 2,
	'4'			=> 4,
	'AUTO'		=> $AUTO,
) ;		

my %FE_INV = (
	'NONE'		=> 0,
	'0'			=> 0,
	'1'			=> 1,
	'AUTO'		=> $AUTO,
) ;		

## All FE params
my %FE_PARAMS = (
	bandwidth 			=> \%FE_BW,
	code_rate_high 		=> \%FE_CODE_RATE,
	code_rate_low 		=> \%FE_CODE_RATE,
	modulation 			=> \%FE_MOD,
	transmission 		=> \%FE_TRANSMISSION,
	guard_interval 		=> \%FE_GUARD,
	hierarchy 			=> \%FE_HIER,
	inversion 			=> \%FE_INV,
) ;

my %FE_CAPABLE = (
	bandwidth 			=> 'FE_CAN_BANDWIDTH_AUTO',
	code_rate_high 		=> 'FE_CAN_FEC_AUTO',
	code_rate_low 		=> 'FE_CAN_FEC_AUTO',
	modulation 			=> 'FE_CAN_QAM_AUTO',
	transmission 		=> 'FE_CAN_TRANSMISSION_MODE_AUTO',
	guard_interval 		=> 'FE_CAN_GUARD_INTERVAL_AUTO',
	hierarchy 			=> 'FE_CAN_HIERARCHY_AUTO',
	inversion			=> 'FE_CAN_INVERSION_AUTO',
) ;


## ETSI 300 468 SI TABLES
my %SI_TABLES = (
	# MPEG-2
	'PAT'		=> 0x00,
	'CAT'		=> 0x01,
	'TSDT'		=> 0x02,
	
	# DVB
	'NIT'		=> 0x10,
	'SDT'		=> 0x11,
	'EIT'		=> 0x12,
	'RST'		=> 0x13,
	'TDT'		=> 0x14,
) ;

my %SI_LOOKUP = reverse %SI_TABLES ;

my %EPG_FLAGS = (
    'AUDIO_MONO'      => (1 << 0),
    'AUDIO_STEREO'    => (1 << 1),
    'AUDIO_DUAL'      => (1 << 2),
    'AUDIO_MULTI'     => (1 << 3),
    'AUDIO_SURROUND'  => (1 << 4),
    'AUDIO_HEAAC'     => (1 << 5),

    'VIDEO_4_3'       => (1 << 8),
    'VIDEO_16_9'      => (1 << 9),
    'VIDEO_HDTV'      => (1 << 10),
    'VIDEO_H264'      => (1 << 11),

    'SUBTITLES'       => (1 << 16),
) ;


## Service type codings (i.e. program types)
my %SERVICE_TYPE = (
	'tv'					=> 0x01,
	'radio'					=> 0x02,
	'hd-tv'					=> 0x19,
) ;

## Service type name
my %SERVICE_NAME = map { $SERVICE_TYPE{$_} => $_ } keys %SERVICE_TYPE ;


#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================

=item B<new([%args])>

Create a new object.

The %args are specified as they would be in the B<set> method, for example:

	'adapter_num' => 0

The full list of possible arguments are as described in the L</FIELDS> section

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $self = {} ;
	bless ($self, $class) ;

	# Initialise object
	$self->_init(%args) ;

	# Set devices list
	$self->device_list() ; # ensure list has been created

	# Initialise hardware
	# Special case - allow for dvb being preset (for testing)
	unless($self->{dvb})
	{
		$self->hwinit() ;
	}

	return($self) ;
}


#-----------------------------------------------------------------------------
# Object initialisation
sub _init
{
	my $self = shift ;
	my (%args) = @_ ;

	# Defaults
	foreach (@FIELD_LIST)
	{
		$self->{$_} = undef  ;
		$self->{$_} = $DEFAULTS{$_} if (exists($DEFAULTS{$_})) ;
	}

	# Set fields from parameters
	$self->set(%args) ;
}



#-----------------------------------------------------------------------------
# Object destruction
sub DESTROY
{
	my $self = shift ;

	$self->dvb_close() ;
}


#-----------------------------------------------------------------------------

=item B<dvb_close()>

Close the hardware down (for example, to allow another script access), without
destroying the object.

=cut

sub dvb_close
{
	my $self = shift ;

	if (ref($self->{dvb}))
	{
		## Close any open demux filters
		$self->close_demux_filters() ;

		## Free up hardware
		dvb_fini($self->dvb) ;
		
		$self->{dvb} = undef ;
	}
}



#============================================================================================

=back

=head2 CLASS METHODS

Use as Linux::DVB::DVBT->method()

=over 4

=cut

#============================================================================================

#-----------------------------------------------------------------------------

=item B<debug([$level])>

Set new debug level. Returns setting.

=cut

sub debug
{
	my ($obj, $level) = @_ ;

	if (defined($level))
	{
		$DEBUG = $level ;
		
		## Set utility module debug levels
		$Linux::DVB::DVBT::Config::DEBUG = $DEBUG ;
		$Linux::DVB::DVBT::Utils::DEBUG = $DEBUG ;
		$Linux::DVB::DVBT::Ffmpeg::DEBUG = $DEBUG ;
	}

	return $DEBUG ;
}

#-----------------------------------------------------------------------------

=item B<dvb_debug([$level])>

Set new debug level for dvb XS code

=cut

sub dvb_debug
{
	my ($obj, $level) = @_ ;

	dvb_set_debug($level||0) ;
}

#-----------------------------------------------------------------------------

=item B<verbose([$level])>

Set new verbosity level. Returns setting.

=cut

sub verbose
{
	my ($obj, $level) = @_ ;

	if (defined($level))
	{
		$VERBOSE = $level ;
	}

	return $VERBOSE ;
}

#-----------------------------------------------------------------------------

=item B<device_list()>

Return list of available hardware as an array of hashes. Each hash entry is of the form:


    {
        'device'        => device name (e.g. '/dev/dvb/adapter0')
        'name'          => Manufacturer name
        'adpater_num'   => Adapter number
        'frontend_num'  => Frontend number
        'flags'         => Adapter capability flags

        'capabilities'  => HASH (see below)
        'fe_type' 		=> Frontend type (e.g. 'FE_OFDM')
        'type' 			=> adapter type (e.g. 'DVB-T')

        'frequency_max' => Maximum supported frequency
        'frequency_min' => Minimum supported frequency
        'frequency_stepsize' => Frequency stepping
    }

          
  The 'flags' field is split into a HASH under the 'capabilities' field, each capability a flag that is set or cleared:
          
        'capabilities' => {
                              'FE_CAN_QAM_16' => 1,
                              'FE_CAN_TRANSMISSION_MODE_AUTO' => 1,
                              'FE_IS_STUPID' => 0,
                              'FE_CAN_QAM_AUTO' => 1,
                              'FE_CAN_FEC_1_2' => 1,
                              'FE_CAN_QAM_32' => 0,
                              'FE_CAN_FEC_5_6' => 1,
                              'FE_CAN_FEC_6_7' => 0,
                              'FE_CAN_HIERARCHY_AUTO' => 1,
                              'FE_CAN_RECOVER' => 1,
                              'FE_CAN_FEC_3_4' => 1,
                              'FE_CAN_FEC_7_8' => 1,
                              'FE_CAN_FEC_2_3' => 1,
                              'FE_CAN_QAM_128' => 0,
                              'FE_CAN_FEC_4_5' => 0,
                              'FE_CAN_FEC_AUTO' => 1,
                              'FE_CAN_QPSK' => 1,
                              'FE_CAN_QAM_64' => 1,
                              'FE_CAN_QAM_256' => 0,
                              'FE_CAN_8VSB' => 0,
                              'FE_CAN_GUARD_INTERVAL_AUTO' => 1,
                              'FE_CAN_BANDWIDTH_AUTO' => 0,
                              'FE_CAN_INVERSION_AUTO' => 1,
                              'FE_CAN_MUTE_TS' => 0,
                              'FE_CAN_16VSB' => 0
                            }
                            

Where a device is actually a link to a real device, there is the additonal field:

	'symlink'	=> {
		
        'adpater_num'   => Adapter number
        'frontend_num'  => Frontend number
		
	}

which details the real device the link points to.

By default, this routine will only return details of DVB-T/T2 adapters. To return the list of all adapters
discovered (including DVB-C etc) add the optional arguments:

	'show' => 'all'

for example:

	my @devices = $dvb->device_list('show' => 'all') ;


Note that this information is also available via the object instance using the 'devices' method, but this
returns an ARRAY REF (rather than an ARRAY)

=cut

sub device_list
{
	my ($class, %args) = @_ ;

	if ( !$devices_href || (keys %args) )
	{
		my $showall = 0 ;
		if (exists($args{'show'}))
		{
			++$showall ;
		}
		
		# Get list of available devices & information for those devices
		foreach my $adap_d (glob("/dev/dvb/adapter*"))
		{
			if ( (-d $adap_d) && ($adap_d =~ /adapter(\d+)/) )
			{
				my $adap = $1 ;
				foreach my $fe_f (glob("$adap_d/frontend*"))
				{
					if ( $fe_f =~ /frontend(\d+)/ )
					{
						my $fe = $1 ;
						
						# get info
						my $info_href = dvb_device_probe($adap, $fe, $DEBUG) ;
	
						prt_data("dvb_device_probe(adap=$adap, fe=$fe)=", $info_href) if $DEBUG >= 10 ;
	
						# skip non DVB-T adapters unless we're displaying all adapters
						my $type = $info_href->{'type'} || "" ;
						next if ($type ne 'DVB-T') && !$showall ;
						next unless $type ;
						
						# check for this being a link (i.e. using udev to fix the adapaters to known identifiers)
						if ( -l $fe_f )
						{
							my $target = readlink $fe_f ;
							$target = realpath( File::Spec->rel2abs($target, $adap_d) ) ;
							if ($target =~ m%/dev/dvb/adapter(\d+)/frontend(\d+)%)
							{
								$info_href->{'symlink'} = {
							        'adapter_num'   => int($1),
							        'frontend_num'  => int($2),
								} ;
							}
							else
							{
								$fe_f = "" ;
							}
						}
						
						$devices_href->{$fe_f} = $info_href if $fe_f ;
					}
				}				
			}
		}		
	}
	
	# sort by adapter/frontend
	my $devices_aref = [] ;
	foreach my $key (sort { 
		$devices_href->{$a}{'adapter_num'} <=> $devices_href->{$b}{'adapter_num'}
		||
		$devices_href->{$a}{'frontend_num'} <=> $devices_href->{$b}{'frontend_num'}
	} keys %$devices_href)
	{
		push @$devices_aref, $devices_href->{$key} ;
	}

	prt_data("DEVICE LIST=", $devices_aref) if $DEBUG >= 10 ;

	return @$devices_aref ;
}

#----------------------------------------------------------------------------

=item B<is_error()>

If there was an error during one of the function calls, returns the error string; otherwise
returns "".

=cut

sub is_error
{
	my ($class) = @_ ;
	my $error_str = dvb_error_str() ;
	
	if ($error_str =~ /no error/i)
	{
		$error_str = "" ;
	}
	return $error_str ;
}


#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<set(%args)>

Set one or more settable parameter.

The %args are specified as a hash, for example

	set('frequency' => 578000)

The full list of possible arguments are as described in the L</FIELDS> section

=cut

sub set
{
	my $self = shift ;
	my (%args) = @_ ;

	# Args
	foreach my $field (@FIELD_LIST)
	{
		if (exists($args{$field})) 
		{
			$self->$field($args{$field}) ;
		}
	}

}

#-----------------------------------------------------------------------------
# Return the list of devices (kept for backward compatibility)
sub devices
{
	my $self = shift ;
	
	my @devices = $self->device_list() ;
	
	return \@devices ;
}



#----------------------------------------------------------------------------

=item B<handle_error($error_message)>

Add the error message to the error log and then handle the error depending on the setting of the 'errmode' field. 

Get the log as an ARRAY ref via the 'errors()' method.

=cut

sub handle_error
{
	my $self = shift ;
	my ($error_message) = @_ ;

	# Log message
	$self->log_error($error_message) ;

	# Handle error	
	my $mode = $self->errmode ;
	
	if ($mode =~ m/return/i)
	{
		# return number of errors logged so far
		return scalar(@{$self->errors()}) ;
	}	
	elsif ($mode =~ m/message/i)
	{
		# return this error message
		return $error_message ;
	}	
	elsif ($mode =~ m/die/i)
	{
		# Die showing all logged errors
		croak join ("\n", @{$self->errors()}) ;
	}	
}


#============================================================================================

=back

=head3 SCANNING

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<scan()>

Starts a channel scan using previously set tuning. On successful completion of a scan,
saves the results into the configuration files.

Returns the discovered channel information as a HASH:

    'pr' => 
    { 
        $channel_name => 
        { 
          'audio' => "407",
          'audio_details' => "eng:407 und:408",
          'ca' => "0",
          'name' => "301",
          'net' => "BBC",
          'pnr' => "19456",
          'running' => "4",
          'teletext' => "0",
          'tsid' => "16384",
          'type' => "1",
          'video' => "203",
          'lcn' => 301
        },
		....
    },
    
    'ts' =>
    {
      $tsid => 
        { 
          'bandwidth' => "8",
          'code_rate_high' => "23",
          'code_rate_low' => "12",
          'frequency' => "713833330",
          'guard_interval' => "32",
          'hierarchy' => "0",
          'modulation' => "64",
          'net' => "Oxford/Bexley",
          'transmission' => "2",
        },
    	...
    }

Normally this information is only used internally.

=cut

sub scan
{
	my $self = shift ;

	my $scan_info_href = $self->_scan_info() ;
prt_data("scan() : Scan info [$scan_info_href]=", $scan_info_href) if $DEBUG>=5 ;
	$scan_info_href->{'chans'} ||= {} ;
	$scan_info_href->{'tsids'} ||= {} ;
	$scan_info_href->{'tsid_order'} ||= [] ;

	my %scan_merge_options = (
		'duplicates'	=> $self->scan_allow_duplicates(),
		'num_chans'		=> $self->scan_prefer_more_chans(),
	) ;

	# Get any existing info
	my $tuning_href = $self->get_tuning_info() ;

prt_data("Current tuning info=", $tuning_href) if $DEBUG>=5 ;

	# hardware closed
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	# if not tuned by now then we have to raise an error
	if (!$self->frontend_params())
	{
		# Raise an error
		return $self->handle_error("Frontend must be tuned before running scan()") ;
	}

	## Initialise for scan
	dvb_scan_new($self->{dvb}, $VERBOSE) unless $self->_scan_freqs ;
	dvb_scan_init($self->{dvb}, $VERBOSE) ;


	## Do scan
	#
	#	Scan results are returned in arrays:
	#	
	#    freqs => 
	#    { # HASH(0x844d76c)
	#      482000000 => 
	#        { # HASH(0x8448da4)
	#          'seen' => 1,
	#          'strength' => 0,
	#          'tuned' => 0,
	#        },
	#
	#    '177500000' => {
	#		'guard_interval' => 2,
	#		'transmission' => 4,
	#		'code_rate_high' => 16,
	#		'tuned' => 1,
	#		'strength' => 49420,
	#		'modulation' => 2,
	#		'seen' => 1,
	#		'bandwidth' => 7,
	#		'code_rate_low' => 16,
	#		'hierarchy' => 0,
	#		'inversion' => 2
	#		}
#readback tuning:
#    __u32                   frequency=177500000
#    fe_spectral_inversion_t inversion=2 (auto)
#    fe_bandwidth_t          bandwidthy=1 (7 MHz)
#    fe_code_rate_t          code_rate_HPy=3 (3/4)
#    fe_code_rate_t          code_rate_LP=1 (1/2)
#    fe_modulation_t         constellation=3 (64)
#    fe_transmit_mode_t      transmission_mod=1 (8k)
#    fe_guard_interval_t     guard_interval=0 (1/32)
#    fe_hierarchy_t          hierarchy_information=0 (none)
	#	
	#    'pr' => 
	#    [ 
	#        { 
	#          'audio' => "407",
	#          'audio_details' => "eng:407 und:408",
	#          'ca' => "0",
	#          'name' => "301",
	#          'net' => "BBC",
	#          'pnr' => "19456",
	#          'running' => "4",
	#          'teletext' => "0",
	#          'tsid' => "16384",
	#          'type' => "1",
	#          'video' => "203",
	#          'lcn' => 301
	#          'freqs' => [
	#				57800000,
	#			],
	#        },
	#		....
	#    ],
	#    
	#    'ts' =>
	#    [
	#        { 
	#          'tsid' => 4107,
	#          'bandwidth' => "8",
	#          'code_rate_high' => "23",
	#          'code_rate_low' => "12",
	#          'frequency' => "713833330",	# reported centre freq
	#          'guard_interval' => "32",
	#          'hierarchy' => "0",
	#          'modulation' => "64",
	#          'net' => "Oxford/Bexley",
	#          'transmission' => "2",
	#		   'lcn' =>
	#		   {
	#		   		$pnr => {
	#		   			'lcn' => 305,
	#		   			'service_type' => 24,
	#		   			'visible' => 1,
	#		   		}
	#		   }
	#        },
	#    	...
	#    ]
	#
	# these results need to analysed and converted into the expected format:
	#
	#    'pr' => 
	#    { 
	#        $channel_name => 
	#        { 
	#          'audio' => "407",
	#			...
	#        },
	#		....
	#    },
	#    
	#    'ts' =>
	#    {
	#      $tsid => 
	#        { 
	#          'bandwidth' => "8",
	#			...
	#        },
	#    	...
	#    }
	#
	#  lcn =>
	#    { # HASH(0x83d2608)
	#      $tsid =>
	#        { # HASH(0x8442524)
	#          $pnr =>
	#            { # HASH(0x8442578)
	#              lcn => 20,
	#              service_type => 2,
	#              visible => 1,
	#            },
	#        },
	#      16384 =>
	#        { # HASH(0x8442af4)
	#          18496 =>
	#            { # HASH(0x8442b48)
	#              lcn => 700,
	#              service_type => 4,
	#              visible => 1,
	#            },
	#        },
	# 
	my $raw_scan_href = dvb_scan($self->{dvb}, $VERBOSE) ;

prt_data("Raw scan results=", $raw_scan_href) if $DEBUG>=5 ;
print STDERR "dvb_scan_end()...\n" if $DEBUG>=5 ;

	## Clear up after scan
	dvb_scan_end($self->{dvb}, $VERBOSE) ;
	dvb_scan_new($self->{dvb}, $VERBOSE) unless $self->_scan_freqs ;

print STDERR "process raw...\n" if $DEBUG>=5 ;

	## Process the raw results for programs
	my $scan_href = {
		'freqs' => $raw_scan_href->{'freqs'},
		'lcn' 	=> {},
	} ;

prt_data("initial scan results=", $scan_href) if $DEBUG>=5 ;

	## Collect together LCN info and map TSIDs to transponder settings
	my %tsids ;
	foreach my $ts_href (@{$raw_scan_href->{'ts'}})
	{
		my $tsid = $ts_href->{'tsid'} ;
		
		# handle LCN
		my $lcn_href = delete $ts_href->{'lcn'} ;
		foreach my $pnr (keys %$lcn_href)
		{
			$scan_href->{'lcn'}{$tsid}{$pnr} = $lcn_href->{$pnr} ;
		}

		# set TSID
		$tsids{$tsid} = $ts_href ;
		$tsids{$tsid}{'frequency'} = undef ;
	}	

if ($VERBOSE >= 3)
{
print STDERR "\n========================================================\n" ;
foreach my $ts_href (@{$raw_scan_href->{'ts'}})
{
	my $tsid = $ts_href->{'tsid'} ;
	print STDERR "--------------------------------------------------------\n" ;
	print STDERR "TSID $tsid\n" ;
	print STDERR "--------------------------------------------------------\n" ;
	
	foreach my $prog_href (@{$raw_scan_href->{'pr'}})
	{
		my $ptsid = $prog_href->{'tsid'} ;
		next unless $ptsid eq $tsid ;
		
		my $name = $prog_href->{'name'} ;
		my $pnr = $prog_href->{'pnr'} ;
		my $lcn = $scan_href->{'lcn'}{$tsid}{$pnr} ;
		$lcn = $lcn ? sprintf("%2d", $lcn) : "??" ;
		
		my $freqs_aref = $prog_href->{'freqs'} ;
		
		print STDERR "  $lcn : [$pnr] $name - " ;
		foreach my $freq (@$freqs_aref)
		{
			print STDERR "$freq Hz " ;
		}
		print STDERR "\n" ;

	}
}	
print STDERR "\n========================================================\n" ;
}

	## Use program info to map TSID to freq (choose strongest signal where necessary)
	foreach my $prog_href (@{$raw_scan_href->{'pr'}})
	{
		my $tsid = $prog_href->{'tsid'} ;
		my $name = $prog_href->{'name'} ;
		my $pnr = $prog_href->{'pnr'} ;
		
		$scan_info_href->{'chans'}{$name} ||= {
			'comments'	=> [],
		} ;
		$scan_info_href->{'tsids'}{$tsid} ||= {
			'comments'	=> [],
		} ;

print STDERR "scan info:: CHAN $name\n" if $DEBUG >= 10 ;
		
		my $freqs_aref = delete $prog_href->{'freqs'} ;
		unless (@$freqs_aref)
		{
			push @{$scan_info_href->{'chans'}{$name}{'comments'}}, "no freqs : TSID $tsid" ;
print STDERR "scan info::  + add comment 'no freqs : TSID $tsid' - CHAN $name\n" if $DEBUG >= 10 ;
		}
		next unless @$freqs_aref ;
		my $freq = @{$freqs_aref}[0] ;
		
		# handle multiple freqs
		if (@$freqs_aref >= 2)
		{
			push @{$scan_info_href->{'chans'}{$name}{'comments'}}, "multiple freqs : TSID $tsid" ;
			foreach my $new_freq (@$freqs_aref)
			{
				if ($new_freq != $freq)
				{
					# check strengths
					my $new_strength = $raw_scan_href->{'freqs'}{$freq}{'strength'} ;
					my $old_strength = $raw_scan_href->{'freqs'}{$new_freq}{'strength'} ;
					if ($new_strength > $old_strength)
					{
						print STDERR "  Program \"$name\" ($pnr) with multiple freqs : using new signal $new_strength (old $old_strength) change freq from $freq to $new_freq\n" if $VERBOSE ;
						$freq = $new_freq ;

						push @{$scan_info_href->{'chans'}{$name}{'comments'}}, "multiple freqs : TSID $tsid : using new signal $new_strength (old $old_strength) change freq from $freq to $new_freq" ;
						push @{$scan_info_href->{'tsids'}{$tsid}{'comments'}}, "multiple freqs : using new signal $new_strength (old $old_strength) change freq from $freq to $new_freq" ;
					}
				}
			}
		}
		
		# save program data
		my $hdtv = 0 ;
		$scan_href->{'pr'}{$name} = $prog_href ;
		if (exists($scan_href->{'lcn'}{$tsid}) && exists($scan_href->{'lcn'}{$tsid}{$pnr}))
		{
			$scan_href->{'pr'}{$name}{'lcn'} = $scan_href->{'lcn'}{$tsid}{$pnr}{'lcn'} ;

			if ($scan_href->{'pr'}{$name}{'type'}==$SERVICE_TYPE{'hd-tv'}) 
			{
				# set flag for this TSID
				$hdtv = 1 ;
			}
		}
		
		# Set transponder freq
		if ( (!defined($tsids{$tsid}{'frequency'})) || ($tsids{$tsid}{'frequency'} != $freq) )
		{
			push @{$scan_info_href->{'tsids'}{$tsid}{'comments'}}, "set freq $freq" ;
		}
		$tsids{$tsid}{'frequency'} = $freq ; 
		$scan_href->{'ts'}{$tsid} = $tsids{$tsid} ;
		
		# hd-tv flag (set if *any* program in it's multiplex is HD)
		$scan_href->{'ts'}{$tsid}{'hd-tv'} = $hdtv ;

		push @{$scan_info_href->{'chans'}{$name}{'comments'}}, "set freq $freq : TSID $tsid" ;

print STDERR "scan info::  + add comment 'set freq $freq : TSID $tsid' - CHAN $name\n" if $DEBUG >= 10 ;
	}
	

prt_data("Scan info=", $scan_info_href) if $DEBUG>=5 ;
prt_data("Scan results=", $scan_href) if $DEBUG>=5 ;
print STDERR "process rest...\n" if $DEBUG>=5 ;
	
	## Post-process to weed out undesirables!
	my %tsid_map ;
	my @del ;
	foreach my $chan (keys %{$scan_href->{'pr'}})
	{
		# strip out chans with no names (or just spaces)
		if ($chan !~ /\S+/)
		{
			push @del, $chan ;
			next ;
		}
		my $tsid = $scan_href->{'pr'}{$chan}{'tsid'} ;
		my $pnr = $scan_href->{'pr'}{$chan}{'pnr'} ;
		$tsid_map{"$tsid-$pnr"} = $chan ;
	}
	
	foreach my $chan (@del)
	{
print STDERR " + del chan \"$chan\"\n" if $DEBUG>=5 ;

		delete $scan_href->{'pr'}{$chan} ;
	}

prt_data("!!POST-PROCESS tsid_map=", \%tsid_map) if $DEBUG>=5 ;
	
	## Post-process based on logical channel number iff we have this data
	
	#  lcn =>
	#    { # HASH(0x83d2608)
	#      12290 =>
	#        { # HASH(0x8442524)
	#          12866 =>
	#            { # HASH(0x8442578)
	#              service_type => 2,
	#            },
	#        },
	#      16384 =>
	#        { # HASH(0x8442af4)
	#          18496 =>
	#            { # HASH(0x8442b48)
	#              lcn => 700,
	#              service_type => 4,
	#              visible => 1,
	#            },
	#        },
	if (keys %{$scan_href->{'lcn'}})
	{
		foreach my $tsid (keys %{$scan_href->{'lcn'}})
		{
			foreach my $pnr (keys %{$scan_href->{'lcn'}{$tsid}})
			{
				my $lcn_href = $scan_href->{'lcn'}{$tsid}{$pnr} ;
				my $chan = $tsid_map{"$tsid-$pnr"} ;
	
				next unless $chan ;
				next unless exists($scan_href->{'pr'}{$chan}) ;
	
	if ($DEBUG>=5)
	{
		my $lcn = defined($lcn_href->{'lcn'}) ? $lcn_href->{'lcn'} : 'undef' ;
		my $vis = defined($lcn_href->{'visible'}) ? $lcn_href->{'visible'} : 'undef' ;
		my $type = defined($lcn_href->{'service_type'}) ? $lcn_href->{'service_type'} : 'undef' ;
		 
	print STDERR " : $tsid-$pnr - $chan : lcn=$lcn, vis=$vis, service type=$type type=$scan_href->{'pr'}{$chan}{'type'}\n" ;
	}	
			
				## handle LCN if set
				my $delete = 0 ;
				if ($lcn_href && $lcn_href->{'lcn'} )
				{
					## Set entry channel number
					$scan_href->{'pr'}{$chan}{'lcn'} = $lcn_href->{'lcn'} ;
	
	print STDERR " : : set lcn for $chan : vid=$scan_href->{'pr'}{$chan}{'video'}  aud=$scan_href->{'pr'}{$chan}{'audio'}\n" if $DEBUG>=5 ;
	
					if (!$lcn_href->{'visible'})
					{
						push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, "LCN not visible - deleting chan" ;
						++$delete ;
					}			
				}	

				# skip delete if pruning not required
				$delete = 0 unless $self->prune_channels ;
			
				## See if need to delete	
				if ($delete)
				{
					## Remove this entry
					delete $scan_href->{'pr'}{$chan} if (exists($scan_href->{'pr'}{$chan})) ;
	
	print STDERR " : : REMOVE $chan\n" if $DEBUG>=5 ;
				}
				
			}
		}
		
	}

	## Fallback to standard checks
	@del = () ;
	foreach my $chan (keys %{$scan_href->{'pr'}})
	{
		## check for valid channel
		my $delete = 0 ;

		my ($service_video, $service_audio) = (0, 0) ;
		if (
			($scan_href->{'pr'}{$chan}{'type'}==$SERVICE_TYPE{'tv'}) || 
			($scan_href->{'pr'}{$chan}{'type'}==$SERVICE_TYPE{'hd-tv'}) 
		)
		{
			++$service_video ;
		}
		if (
			($scan_href->{'pr'}{$chan}{'type'}==$SERVICE_TYPE{'radio'}) 
		)
		{
			++$service_audio ;
		}
print STDERR " : : $chan : type=$scan_href->{'pr'}{$chan}{'type'}  service vid? $service_video, audio? $service_audio\n" if $DEBUG >=5;

		if ( $service_video || $service_audio )
		{

print STDERR " : : $chan : vid=$scan_href->{'pr'}{$chan}{'video'}  aud=$scan_href->{'pr'}{$chan}{'audio'}\n" if $DEBUG >=5;

			## check that this type has the required streams
			if ($service_video)
			{
				## video
				if (!$scan_href->{'pr'}{$chan}{'video'} || !$scan_href->{'pr'}{$chan}{'audio'})
				{
					push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, "no video/audio pids - deleting chan" ;
					++$delete ;
				}
			}
			else
			{
				## audio
				if (!$scan_href->{'pr'}{$chan}{'audio'})
				{
					push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, "no audio pids - deleting chan" ;
					++$delete ;
				}
			}

		}
		else
		{
			# remove none video/radio types
			++$delete ;
			push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, "non-video/radio - deleting chan" ;
		}

		# skip delete if pruning not required
		$delete = 0 unless $self->prune_channels ;

		push @del, $chan if $delete;
	}

	foreach my $chan (@del)
	{
print STDERR " + del chan \"$chan\"\n" if $DEBUG>=5 ;

		delete $scan_href->{'pr'}{$chan} ;
	}

prt_data("Scan before tsid fix=", $scan_href) if $DEBUG>=5 ;


	## Set transponder params 
	
	# sadly there are lies, damn lies, and broadcast information! You can't rely on the broadcast info and
	# have to fall back on either readback from the tuner device for it's settings (if it supports readback),
	# using the values specified in the frequency file (i.e. the tuning params), or defaulting params to 'AUTO'
	# where the tuner will permit it.
	
	# this is what we used to set the frontend with
	my $frontend_params_href = $self->frontend_params() ;
		
	# NOTE: Only really expect there to be at most 1 entry in the 'ts' record. It should be the single TSID at this frequency
	foreach my $tsid (keys %{$scan_href->{'ts'}})
	{
		my $freq = $tsids{$tsid}{'frequency'} ;
		
		if (exists($scan_href->{'freqs'}{$freq}))
		{
			# Use readback info for preference
			foreach (keys %{$scan_href->{'freqs'}{$freq}} )
			{
				$tsids{$tsid}{$_} = $scan_href->{'freqs'}{$freq}{$_} ;
			}
			
			push @{$scan_info_href->{'tsid_order'}}, " + Got TSID $tsid at $freq Hz" ;
		}
		elsif ($freq == $frontend_params_href->{'frequency'})
		{
			# Use specified settings
			foreach (keys %{$frontend_params_href} )
			{
				$tsids{$tsid}{$_} = $frontend_params_href->{$_} ;
			}

			push @{$scan_info_href->{'tsid_order'}}, " + Got TSID $tsid at $freq Hz" ;
		}
		else
		{
			# device info
			my $dev_info_href = $self->_device_info ;
			my $capabilities_href = $dev_info_href->{'capabilities'} ;

			# Use AUTO where possible
			foreach my $param (keys %{$frontend_params_href} )
			{
				next unless exists($FE_CAPABLE{$param}) ;

				## check to see if we are capable of using auto
				if ($capabilities_href->{$FE_CAPABLE{$param}})
				{
					# can use auto
					$tsids{$tsid}{$param} = $AUTO ;
				}
			}
		}
	}	
		
		
printf STDERR "Merge flag=%d\n", $self->merge  if $DEBUG>=5 ;
prt_data("FE params=", $frontend_params_href, "Scan before merge=", $scan_href) if $DEBUG>=5 ;
prt_data("before merge - Scan info [$scan_info_href]=", $scan_info_href) if $DEBUG>=5 ;


	## Merge results
	if ($self->merge)
	{
		if ($self->_scan_freqs)
		{
			## update the old information with the new iff new has better signal
			$scan_href = Linux::DVB::DVBT::Config::merge_scan_freqs($scan_href, $tuning_href, \%scan_merge_options, $VERBOSE, $scan_info_href) ;
		}
		else
		{
			## just update the old information with the new
			$scan_href = Linux::DVB::DVBT::Config::merge($scan_href, $tuning_href, $scan_info_href) ;
		}	
prt_data("Merged=", $scan_href) if $DEBUG>=5 ;
	}
	
	## Keep track of frequencies tuned to
#	$scan_href->{'freqfile'} = { map { $_->{'frequency'} => $_ } @{$scan_info_href->{'freqs'}}  } ;
	$scan_href->{'freqfile'} = {} ;
	foreach my $freq (keys %{$scan_href->{'freqs'}})
	{
		# only keep frequencies we could tune to
		next unless $scan_href->{'freqs'}{$freq}{'tuned'} ;
		$scan_href->{'freqfile'}{$freq} = { 
			%{$scan_href->{'freqs'}{$freq}},
			'frequency'	=> $freq,
		} ;
	}


prt_data("Scan with freqfile=", $scan_href) if $DEBUG>=5 ;
	
	# Save results
	$self->tuning($scan_href) ;
	Linux::DVB::DVBT::Config::write($self->config_path, $scan_href) ;

prt_data("scan() end - Scan info [$scan_info_href]=", $scan_info_href) if $DEBUG>=5 ;
print STDERR "DONE\n" if $DEBUG>=5 ;

	return $self->tuning() ;
}

#----------------------------------------------------------------------------

=item B<scan_from_file($freq_file)>

Reads the DVBT frequency file (usually stored in /usr/share/dvb/dvb-t) and uses the contents to
set the frontend to the initial frequency. Then starts a channel scan using that tuning.

$freq_file must be the full path to the file. The file contents should be something like:

   # Oxford
   # T freq bw fec_hi fec_lo mod transmission-mode guard-interval hierarchy
   T 578000000 8MHz 2/3 NONE QAM64 2k 1/32 NONE

NOTE: Frequency files are provided by the 'dvb' rpm package available for most distros

Returns the discovered channel information as a HASH (see L</scan()>)

=cut

sub scan_from_file
{
	my $self = shift ;
	my ($freq_file) = @_ ;

	## Need a file
	return $self->handle_error( "Error: No frequency file specified") unless $freq_file ;

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	print STDERR "scan_from_file() : Linux::DVB::DVBT version $VERSION\n\n" if $DEBUG ;

	my @tuning_list ;

	# device info
	my $dev_info_href = $self->_device_info ;
	my $capabilities_href = $dev_info_href->{'capabilities'} ;

prt_data("Capabilities=", $capabilities_href, "FE Cap=", \%FE_CAPABLE)  if $DEBUG>=2 ;


	#    $freqs_href = 
	#    { # HASH(0x844d76c)
	#      482000000 => 
	#        { # HASH(0x8448da4)
	#          'seen' => 1,
	#          'strength' => 0,
	#          'tuned' => 0,
	#        },
	#
	my $freqs_href = {} ;
	

	## parse file
	open my $fh, "<$freq_file" or return $self->handle_error( "Error: Unable to read frequency file $freq_file : $!") ;
	my $line ;
	while (defined($line=<$fh>))
	{
		chomp $line ;
		## # T freq      bw   fec_hi fec_lo mod   transmission-mode guard-interval hierarchy
		##   T 578000000 8MHz 2/3    NONE   QAM64 2k                1/32           NONE

		if ($line =~ m%^\s*T\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)%i)
		{
			my $freq = dvb_round_freq($1) ;
			
			if (exists($freqs_href->{$freq}))
			{
				print STDERR "Note: frequency $freq Hz already seen, skipping\n" ;
				next ;
			}
			$freqs_href->{$freq} = {
	          'seen' => 0,
	          'strength' => 0,
	          'tuned' => 0,
			} ;
			

			## setting all params doesn't necessarily work since the freq file is quite often out of date!				
			my %params = (
				bandwidth => $2,
				code_rate_high => $3,
				code_rate_low => $4,
				modulation => $5,
				transmission => $6,
				guard_interval => $7,
				hierarchy => $8,
				inversion => 0,
			) ;
			
			# convert file entry into a frontend param
			my %tuning_params ;
			foreach my $param (keys %params)
			{
				## convert freq file value into VDR format
				if (exists($FE_PARAMS{$param}{$params{$param}}))
				{
					$tuning_params{$param} = $FE_PARAMS{$param}{$params{$param}} ;
				}				
			}
			$tuning_params{'frequency'} = $freq ;

prt_data("Tuning params=", \%tuning_params) if $DEBUG>=2 ;

			## add to tuning list
			push @tuning_list, \%tuning_params ;
		}
	}
	close $fh ;
	
	# exit on failure
	return $self->handle_error( "Error: No tuning parameters found") unless @tuning_list ;

	## do scan
	$self->_scan_frequency_list($freqs_href, @tuning_list) ;

	## return tuning settings	
	return $self->tuning() ;
}


#----------------------------------------------------------------------------

=item B<scan_from_country($iso3166)>

Given a 2 letter country code (as defined by ISO 3166-1) attempts to scan those
frequencies to produce a scan list.

Note that this routine relies on the adapter supporting auto settings for most of the parameters. Older
adapters may not work properly.

Returns the discovered channel information as a HASH (see L</scan()>)

=cut

sub scan_from_country
{
	my $self = shift ;
	my ($iso3166) = @_ ;

	## Need a country name
	return $self->handle_error( "Error: No valid country code specified") unless Linux::DVB::DVBT::Freq::country_supported($iso3166) ;

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	print STDERR "scan_from_country($iso3166) : Linux::DVB::DVBT version $VERSION\n\n" if $DEBUG ;

	my @tuning_list ;

	# device info
	my $dev_info_href = $self->_device_info ;
	my $capabilities_href = $dev_info_href->{'capabilities'} ;

prt_data("Capabilities=", $capabilities_href, "FE Cap=", \%FE_CAPABLE)  if $DEBUG>=2 ;


	#    $freqs_href = 
	#    { # HASH(0x844d76c)
	#      482000000 => 
	#        { # HASH(0x8448da4)
	#          'seen' => 1,
	#          'strength' => 0,
	#          'tuned' => 0,
	#        },
	#
	my $freqs_href = {} ;
	
	
	## Get frequencies
	my @frequencies = Linux::DVB::DVBT::Freq::chan_freq_list($iso3166) ;

	## process list
	foreach my $href (@frequencies)
	{
		my $bw = $href->{'bw'} ;
		my $frequency = $href->{'freq'} ;
		
		my $freq = dvb_round_freq($frequency) ;
			
		if (exists($freqs_href->{$freq}))
		{
			print STDERR "Note: frequency $freq Hz already seen, skipping\n" ;
			next ;
		}
		$freqs_href->{$freq} = {
          'seen' => 0,
          'strength' => 0,
          'tuned' => 0,
		} ;
			

		my %tuning_params = (
			frequency => $freq,
			bandwidth => $bw,
			code_rate_high => $AUTO,
			code_rate_low => $AUTO,
			modulation => $AUTO,
			transmission => $AUTO,
			guard_interval => $AUTO,
			hierarchy => $AUTO,
			inversion => $AUTO,
		) ;
			
prt_data("Tuning params=", \%tuning_params) if $DEBUG>=2 ;

		## add to tuning list
		push @tuning_list, \%tuning_params ;

	}
	
	# exit on failure
	return $self->handle_error( "Error: No tuning parameters found") unless @tuning_list ;

	## do scan
	$self->_scan_frequency_list($freqs_href, @tuning_list) ;
	

	## return tuning settings	
	return $self->tuning() ;
}

#----------------------------------------------------------------------------

=item B<scan_from_previous()>

Uses the last scan frequencies to re-scan. This assumes that a scan was completed 
and saved to the configuration file (see L<Linux::DVB::DVBT::Config::read_dvb_ts_freqs($fname)>).

Note: this will only work for scans completed with version 2.11 (and later) of this module.

Returns the discovered channel information as a HASH (see L</scan()>)

=cut

sub scan_from_previous
{
	my $self = shift ;

	## Check to ensure we really have a list
	my $tuning_href = $self->get_tuning_info() ;
	if (!exists($tuning_href->{'freqfile'}) && keys %{$tuning_href->{'freqfile'}})
	{
		return $self->handle_error( "Error: No saved frequency list is found in configuration") ;
	}

prt_data("Tuning freqfile=", $tuning_href->{'freqfile'}) if $DEBUG>=2 ;


	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	print STDERR "scan_from_previous() : Linux::DVB::DVBT version $VERSION\n\n" if $DEBUG ;

	my @tuning_list ;

	# device info
	my $dev_info_href = $self->_device_info ;
	my $capabilities_href = $dev_info_href->{'capabilities'} ;

prt_data("Capabilities=", $capabilities_href, "FE Cap=", \%FE_CAPABLE)  if $DEBUG>=2 ;


	#    $freqs_href = 
	#    { # HASH(0x844d76c)
	#      482000000 => 
	#        { # HASH(0x8448da4)
	#          'seen' => 1,
	#          'strength' => 0,
	#          'tuned' => 0,
	#        },
	#
	my $freqs_href = {} ;
	
	## Get frequencies
	foreach my $frequency (keys %{$tuning_href->{'freqfile'}} )
	{
		my $freq = dvb_round_freq($frequency) ;
			
		if (exists($freqs_href->{$freq}))
		{
			print STDERR "Note: frequency $freq Hz already seen, skipping\n" ;
			next ;
		}
		$freqs_href->{$freq} = {
          'seen' => 0,
          'strength' => 0,
          'tuned' => 0,
		} ;
			
		my %tuning_params = (
			%{$tuning_href->{'freqfile'}{$frequency}},
			'frequency' => $freq,
		) ;
			
prt_data("Tuning params=", \%tuning_params) if $DEBUG>=2 ;

		## add to tuning list
		push @tuning_list, \%tuning_params ;

	}
	
	# exit on failure
	return $self->handle_error( "Error: No tuning parameters found") unless @tuning_list ;

	## do scan
	$self->_scan_frequency_list($freqs_href, @tuning_list) ;
	

	## return tuning settings	
	return $self->tuning() ;
}



#----------------------------------------------------------------------------
sub _scan_frequency_list
{
	my $self = shift ;
	my ($freqs_href, @tuning_list) = @_ ;

	# device info
	my $dev_info_href = $self->_device_info ;
	my $capabilities_href = $dev_info_href->{'capabilities'} ;

	# callback
	my %callback_info = (
		'tuning_list'			=> \@tuning_list,
		'estimated_percent'		=> 0,
		'total_freqs'			=> scalar(@tuning_list),
		'current_freq'			=> 0,
		'done_freqs'			=> 0,
		'scan_info'				=> {},
	) ;
	if ($self->scan_cb_start)
	{
		my $cb = $self->scan_cb_start() ;
		&$cb(\%callback_info) ;
	}

	## prep for scan
	dvb_scan_new($self->{dvb}, $VERBOSE) ;
	
	## Info
	my $scan_info_href = $self->_scan_info() ;
	$scan_info_href->{'file_freqs'} = [ @tuning_list ] ;	# save original tuning list 
	$scan_info_href->{'freqs'} = [ ] ;						# list of frequencies seen
	$scan_info_href->{'chans'} = { } ;						# channel info
	$scan_info_href->{'tsid_order'} ||= [] ;				# tsid info

	## tune into each frequency & perform the scan
	my %freq_list ;
	my $saved_merge = $self->merge ;
	while (@tuning_list)
	{
		my $tuned = 0 ;

print STDERR "Loop start: ".scalar(@tuning_list)." freqs\n" if $DEBUG>=2 ;

		# update frequencies
		@tuning_list = sort {$a->{'frequency'} <=> $b->{'frequency'}} @tuning_list ;
		foreach my $href (@tuning_list)
		{
			my $freq_round = dvb_round_freq($href->{'frequency'}) ;
			$freq_list{$freq_round} = 0 if !exists($freq_list{$freq_round}) ;
		}
prt_data("Loop start freq list=", \%freq_list) if $DEBUG>=3 ;

		# callback
		if ($self->scan_cb_loop_start)
		{
			my $total_freqs = scalar(keys %freq_list) ;
			my $done_freqs = 0 ;
			foreach my $f (keys  %freq_list)
			{
				++$done_freqs if $freq_list{$f} ;
			}
			$callback_info{'estimated_percent'} = int( $done_freqs * 100.0 / $total_freqs + 0.5)+1 ;
			$callback_info{'estimated_percent'} = 97 if $callback_info{'estimated_percent'}>97 ;
			$callback_info{'total_freqs'} = $total_freqs ;
			$callback_info{'done_freqs'} = $done_freqs ;
			$callback_info{'scan_info'} = $self->tuning() ;
			$callback_info{'tuning_list'} = \@tuning_list ;	 
	
			my $cb = $self->scan_cb_loop_start() ;
			&$cb(\%callback_info) ;
		}



		## keep trying to tune while we've got something to try	
		my $frequency = 0 ;
		while (!$tuned && @tuning_list)
		{
			my $rc = -1 ;
			my %tuning_params ;
			my $tuning_params_href = shift @tuning_list ;
			$frequency = dvb_round_freq($tuning_params_href->{'frequency'}) ;
			$freq_list{$frequency} = 1 ;
			
			# make sure frequency is valid
			if ($frequency >= $MIN_FREQ)
			{
				# convert file entry into a frontend param
				foreach my $param (keys %$tuning_params_href)
				{
					next unless exists($FE_CAPABLE{$param}) ;
	print STDERR " +check param $param\n" if $DEBUG>=2 ;
	
					## check to see if we are capable of using auto
					unless ($capabilities_href->{$FE_CAPABLE{$param}})
					{
						# can't use auto so we have to set it
						$tuning_params{$param} = $tuning_params_href->{$param} ;
					}
				}
				$tuning_params{'frequency'} = $frequency ;
				$tuning_params{'timeout'} = $self->timeout() ;
				
				# set tuning
				print STDERR "Setting frequency: $frequency Hz\n" if $self->verbose ;
				$rc = dvb_scan_tune($self->{dvb}, {%tuning_params}) ;
			}
			
			## If tuning went ok, then save params
			if ($rc == 0)
			{
				$self->frontend_params( {%tuning_params} ) ;
				$tuned = 1 ;
				$freq_list{$frequency} = 2 ;

				push @{$scan_info_href->{'freqs'}}, $tuning_params_href ;
				push @{$scan_info_href->{'tsid_order'}}, "Set freq to $frequency Hz" ;
			}
			else
			{
				my $freq = $frequency || "0" ;
				print STDERR "    Failed to set the DVB-T tuner to $freq Hz ... skipping\n" ;

				# try next frequency
				last unless @tuning_list ;			
			}

print STDERR "Attempt tune: ".scalar(@tuning_list)." freqs\n" if $DEBUG>=2 ;

		} # while !$tuned
		
		last if !$tuned ;


		# callback
		if ($self->scan_cb_loop_start)
		{
			my $total_freqs = scalar(keys %freq_list) ;
			my $done_freqs = 0 ;
			foreach my $f (keys  %freq_list)
			{
				++$done_freqs if $freq_list{$f} ;
			}
			$callback_info{'estimated_percent'}++ ;
			$callback_info{'estimated_percent'} = 98 if $callback_info{'estimated_percent'}>98 ;
			$callback_info{'total_freqs'} = $total_freqs ;
			$callback_info{'done_freqs'} = $done_freqs ;
			$callback_info{'scan_info'} = $self->tuning() ;
			$callback_info{'current_freq'} = $frequency ;
	
			my $cb = $self->scan_cb_loop_start() ;
			&$cb(\%callback_info) ;
		}


print STDERR "Scan merge : ", $self->merge(),"\n" if $DEBUG>=2 ;
			
		# Scan
		$self->_scan_freqs(1) ;
		$self->scan() ;
		$self->_scan_freqs(0) ;
		
		# ensure next results are merged in
		$self->merge(1) ;
		
		# update frequency list
		my $tuning_href = $self->tuning ;
		$freqs_href = $tuning_href->{'freqs'} if exists($tuning_href->{'freqs'}) ;

prt_data("Loop end freqs=", $freqs_href) if $DEBUG>=3 ;
		
		# update frequencies
		foreach my $freq (sort {$a <=> $b} keys %$freqs_href)
		{
			next if $freqs_href->{$freq}{'seen'} ;
			
			my $freq_round = dvb_round_freq($freq) ;
			if (!exists($freq_list{$freq_round}) )
			{
				push @tuning_list, {
					'frequency'		=> $freq_round,
					%{$freqs_href->{$freq}},
				} ;
print STDERR " + adding freq $freq_round\n" if $DEBUG>=2 ;
			}
		} 

prt_data("Loop end Tuning list=", \@tuning_list) if $DEBUG>=2 ;

		# callback
		if ($self->scan_cb_loop_end)
		{
			my $total_freqs = scalar(keys %freq_list) ;
			my $done_freqs = 0 ;
			foreach my $f (keys  %freq_list)
			{
				++$done_freqs if $freq_list{$f} ;
			}
			$callback_info{'estimated_percent'} = int( $done_freqs * 100.0 / $total_freqs + 0.5) ;
			$callback_info{'estimated_percent'} = 99 if $callback_info{'estimated_percent'}>99 ;
			$callback_info{'total_freqs'} = $total_freqs ;
			$callback_info{'done_freqs'} = $done_freqs ;
			$callback_info{'scan_info'} = $self->tuning() ;
	
			my $cb = $self->scan_cb_loop_end() ;
			&$cb(\%callback_info) ;
		}


print STDERR "Loop end: ".scalar(@tuning_list)." freqs\n" if $DEBUG>=2 ;

	} # while @tuning_list

###############################
if ($DEBUG)
{
# check to ensure each tsid has some programs. If not then we can delete that tsid

	my %tsids ;
	my $scan_href = $self->tuning() ;
	foreach my $prog (keys %{$scan_href->{'pr'}})
	{
		my $prog_href = $scan_href->{'pr'}{$prog} ;
		my $tsid = $prog_href->{'tsid'} ;
		$tsids{$tsid} = 1 ;
	}
	foreach my $tsid (keys %{$scan_href->{'ts'}})
	{
		if (!exists($tsids{$tsid}))
		{
			print STDERR " * TSID $tsid has no progs\n" ;
		}
	}
}
###############################


	## restore flag
	$self->merge($saved_merge) ;

	## clear ready for next scan
	dvb_scan_new($self->{dvb}, $VERBOSE) ;

prt_data("## Scan Info ##", $scan_info_href) if $DEBUG>=2 ;

	if ($VERBOSE)
	{
		print "\n\n" ;
		print "SCANNING INFORMATION\n" ;
		print "====================\n\n" ;
		
		print "Frequency Scan\n" ;
		print "--------------\n" ;
		my $set=0 ;
		foreach my $line (@{$scan_info_href->{'tsid_order'}})
		{
			my $this_set=0 ;
			if ($line =~ /Set freq/i)
			{
				$this_set=1 ;
			}
			if ($set && $this_set)
			{
				print "  ** No TSIDs **\n" ;		
			}	
			$set = $this_set ;
			print "\n" if $this_set ;
			print "  $line\n" ;		
		}
		print "\n" ;

		print "TSID Info\n";
		print "---------\n";
		foreach my $tsid (sort {int($a) <=> int($b)} keys %{$scan_info_href->{'tsids'}})
		{
			print "\n  TSID $tsid\n" ;		
			foreach my $line (@{$scan_info_href->{'tsids'}{$tsid}{'comments'}})
			{
				print "    $line\n" ;		
			}
		}
		print "\n";

		print "Channel Info\n";
		print "------------\n";
		foreach my $chan (sort keys %{$scan_info_href->{'chans'}})
		{
			print "\n  $chan\n" ;		
			foreach my $line (@{$scan_info_href->{'chans'}{$chan}{'comments'}})
			{
				print "    $line\n" ;		
			}
		}
		print "\n";
	}

	# callback
	if ($self->scan_cb_end)
	{
		$callback_info{'estimated_percent'} = 100 ;
		$callback_info{'total_freqs'} = scalar(keys %freq_list) ;
		$callback_info{'done_freqs'} = scalar(keys %freq_list) ;
		$callback_info{'scan_info'} = $self->tuning() ;
		$callback_info{'current_freq'} = 0 ;

		my $cb = $self->scan_cb_end() ;
		&$cb(\%callback_info) ;
	}

	## return tuning settings	
	return $self->tuning() ;
}






#============================================================================================

=back

=head3 TUNING

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<is_busy()>

Returns 0 is the currently selected adapter frontend is not busy; 1 if it is.

=cut

sub is_busy
{
	my $self = shift ;

	my $is_busy = dvb_is_busy($self->{dvb}) ;
	
	return $is_busy ;
}

#----------------------------------------------------------------------------

=item B<set_frontend(%params)>

Tune the frontend to the specified frequency etc. HASH %params contains:

    'frequency'
    'inversion'
    'bandwidth'
    'code_rate_high'
    'code_rate_low'
    'modulation'
    'transmission'
    'guard_interval'
    'hierarchy'
    'timeout'
    'tsid'

(If you don't know what these parameters should be set to, then I recommend you just use the L</select_channel($channel_name)> method)

Returns 0 if ok; error code otherwise

=cut

sub set_frontend
{
	my $self = shift ;
	my (%params) = @_ ;

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	# Set up the frontend
	my $rc = dvb_tune($self->{dvb}, {%params}) ;
	
	print STDERR "dvb_tune() returned $rc\n" if $DEBUG ;
	
	# If tuning went ok, then save params
	#
	# Currently:
	#   -11 = Device busy
	#	-15 / -16 = Failed to tune
	#
	if ($rc == 0)
	{
		$self->frontend_params( {%params} ) ;
	}
	
	return $rc ;
}

#----------------------------------------------------------------------------

=item B<set_demux($video_pid, $audio_pid, $subtitle_pid, $teletext_pid)>

Selects a particular video/audio stream (and optional subtitle and/or teletext streams) and sets the
demultiplexer to those streams (ready for recording).

(If you don't know what these parameters should be set to, then I recommend you just use the L</select_channel($channel_name)> method)

Returns 0 for success; error code otherwise.

=cut

sub set_demux
{
	my $self = shift ;
	my ($video_pid, $audio_pid, $subtitle_pid, $teletext_pid, $tsid, $demux_params_href) = @_ ;

print STDERR "set_demux( <$video_pid>, <$audio_pid>, <$teletext_pid> )\n" if $DEBUG ;

	my $error = 0 ;
	if ($video_pid && !$error)
	{
		$error = $self->add_demux_filter($video_pid, "video", $tsid, $demux_params_href) ;
	}
	if ($audio_pid && !$error)
	{
		$error = $self->add_demux_filter($audio_pid, "audio", $tsid, $demux_params_href) ;
	}
	if ($teletext_pid && !$error)
	{
		$error = $self->add_demux_filter($teletext_pid, "teletext", $tsid, $demux_params_href) ;
	}
	if ($subtitle_pid && !$error)
	{
		$error = $self->add_demux_filter($subtitle_pid, "subtitle", $tsid, $demux_params_href) ;
	}
	return $error ;
}

#----------------------------------------------------------------------------

=item B<select_channel($channel_name)>

Tune the frontend & the demux based on $channel_name. 

This method uses a "fuzzy" search to match the specified channel name with the name broadcast by the network.
The case of the name is not important, and neither is whitespace. The search also checks for both numeric and
name instances of a number (e.g. "1" and "one").

For example, the following are all equivalent and match with the broadcast channel name "BBC ONE":

    bbc1
    BbC One
    b b c    1  

Returns 0 if ok; error code otherwise

=cut

sub select_channel
{
	my $self = shift ;
	my ($channel_name) = @_ ;

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	# ensure we have the tuning info
	my $tuning_href = $self->get_tuning_info() ;
	if (! $tuning_href)
	{
		return $self->handle_error("Unable to get tuning information") ;
	}

	# get the channel info	
	my ($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel($channel_name, $tuning_href) ;
	if (! $frontend_params_href)
	{
		return $self->handle_error("Unable to find channel $channel_name") ;
	}

	# Tune frontend
	if ($self->set_frontend(%$frontend_params_href, 'timeout' => $self->timeout))
	{
		return $self->handle_error("Unable to tune frontend") ;
	}

	## start with clean slate
	$self->multiplex_close() ;	

	# Set demux (no teletext or subtitle)
	if ($self->set_demux(
		$demux_params_href->{'video'}, 
		$demux_params_href->{'audio'},
		0, 
		0, 
		$frontend_params_href->{'tsid'}, 
		$demux_params_href) 
	)
	{
		return $self->handle_error("Unable to set demux") ;
	}

	return 0 ;
}
	
#----------------------------------------------------------------------------

=item B<get_tuning_info()>

Check to see if 'tuning' information has been set. If not, attempts to read from the config
search path.

Returns a HASH ref of tuning information - i.e. it contains the complete information on all
transponders (under the 'ts' field), and all programs (under the 'pr' field). [see L</scan()> method for format].

Otherwise returns undef if no information is available.

=cut

sub get_tuning_info
{
	my $self = shift ;

	# Get any existing info
	my $tuning_href = $self->tuning() ;
	
	# If not found, try reading
	if (!$tuning_href)
	{
		$tuning_href = Linux::DVB::DVBT::Config::read($self->config_path) ;
		
		prt_data("get_tuning_info()", $tuning_href) if $DEBUG >= 20 ;
		
		# save if got something
		$self->tuning($tuning_href) if $tuning_href ;
	}

	return $tuning_href ;
}

#----------------------------------------------------------------------------

=item B<get_channel_list()>

Checks to see if 'channel_list' information has been set. If not, attempts to create a list based
on the scan information.

NOTE that the created list will be the best attempt at ordering the channels based on the TSID & PNR
which won't be pretty, but it'll be better than nothing!

Returns an ARRAY ref of channel_list information; otherwise returns undef. The array is sorted by logical channel number
and contains HASHes of the form:

	{
		'channel'		=> channel name (e.g. "BBC THREE") 
		'channel_num'	=> the logical channel number (e.g. 7)
		'type'			=> radio or tv channel ('radio', 'tv' or 'hd-tv')
	}

=cut

sub get_channel_list
{
	my $self = shift ;

	# Get any existing info
	my $channels_aref = $self->channel_list() ;
	
	# If not found, try creating
	if (!$channels_aref)
	{
#print STDERR "create chan list\n" ;

		# Get any existing info
		my $tuning_href = $self->get_tuning_info() ;
#prt_data("Tuning Info=",$tuning_href) ;
		
		# Use the scanning info to create an ordered list
		if ($tuning_href)
		{
			$channels_aref = [] ;
			$self->channel_list($channels_aref) ;

			my %tsid_pnr ;
			foreach my $channel_name (keys %{$tuning_href->{'pr'}})
			{
				my $tsid = $tuning_href->{'pr'}{$channel_name}{'tsid'} ;
				my $pnr = $tuning_href->{'pr'}{$channel_name}{'pnr'} ;
				$tsid_pnr{$channel_name} = "$tsid-$pnr" ;
			}
			
			my $channel_num=1 ;
			foreach my $channel_name (sort 
				{ 
					my $lcn_a = $tuning_href->{'pr'}{$a}{'lcn'}||0 ;
					my $lcn_b = $tuning_href->{'pr'}{$b}{'lcn'}||0 ;
					if (!$lcn_a || !$lcn_b)
					{
						$tuning_href->{'pr'}{$a}{'tsid'} <=> $tuning_href->{'pr'}{$b}{'tsid'}
						||
						$tuning_href->{'pr'}{$a}{'pnr'} <=> $tuning_href->{'pr'}{$b}{'pnr'} ;
					}
					else
					{
						$lcn_a <=> $lcn_b ;
					}
					
				} 
				keys %{$tuning_href->{'pr'}})
			{
				my $type = $tuning_href->{'pr'}{$channel_name}{'type'} || $SERVICE_TYPE{'tv'} ;
				my $type_str = 'special' ;
Linux::DVB::DVBT::prt_data("type=$type, NAMES=", \%SERVICE_NAME) if $DEBUG>=10 ;
				if (exists($SERVICE_NAME{$type}))
				{
					$type_str = $SERVICE_NAME{$type} ;
				}
				
				push @$channels_aref, { 
					'channel'		=> $channel_name, 
					'channel_num'	=> $tuning_href->{'pr'}{$channel_name}{'lcn'} || $channel_num,
					'type'			=> $type_str,
					'type_code'		=> $type,
				} ;
				
				++$channel_num ;
			}
		}

#prt_data("TSID-PNR=",\%tsid_pnr) ;
	}

	return $channels_aref ;
}

#----------------------------------------------------------------------------

=item B<signal_quality()>

Measures the signal quality of the currently tuned transponder. Returns a HASH ref containing:

	{
		'ber'					=> Bit error rate (32 bits)
		'snr'					=> Signal to noise ratio (maximum is 0xffff)
		'strength'				=> Signal strength (maximum is 0xffff)
		'uncorrected_blocks'	=> Number of uncorrected blocks (32 bits)
		'ok'					=> flag set if no errors occured during the measurements
	}

Note that some tuner hardware may not support some (or any) of the above measurements.

=cut

sub signal_quality
{
	my $self = shift ;
	

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	# if not tuned yet, tune to all station freqs (assumes scan has been performed)
	if (!$self->frontend_params())
	{
		return $self->handle_error("Frontend not tuned") ;
	}

	# get signal info
	my $signal_href = dvb_signal_quality($self->{dvb}) ;
	
	return $signal_href ;
}

#----------------------------------------------------------------------------

=item B<tsid_signal_quality([$tsid])>

Measures the signal quality of the specified transponder. Returns a HASH containing:

	{
		$tsid => {
			'ber'					=> Bit error rate (32 bits)
			'snr'					=> Signal to noise ratio (maximum is 0xffff)
			'strength'				=> Signal strength (maximum is 0xffff)
			'uncorrected_blocks'	=> Number of uncorrected blocks (32 bits)
			'ok'					=> flag set if no errors occured during the measurements
			'error'					=> Set to an error string on error; otherwise undef
		}
	}

If no TSID is specified, then scans all transponders and returns the complete HASH.

Note that some tuner hardware may not support some (or any) of the above measurements.

=cut

sub tsid_signal_quality
{
	my $self = shift ;
	my ($tsid) = @_ ;
	

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	# ensure we have the tuning info
	my $tuning_href = $self->get_tuning_info() ;
	if (! $tuning_href)
	{
		return $self->handle_error("Unable to get tuning information") ;
	}

	# check/create list of TSIDs
	my @tsids ;
	if ($tsid)
	{
		# check it
		if (!exists($tuning_href->{'ts'}{$tsid}))
		{
			# Raise an error
			return $self->handle_error("Unknown TSID $tsid") ;
		}
		
		push @tsids, $tsid ;
	}
	else
	{
		# create
		@tsids = keys %{$tuning_href->{'ts'}} ;
	}
	
	## handle errors
	my $errmode = $self->{errmode} ;
	$self->{errmode} = 'message' ;
	
	## get info
	my %info ;
	foreach my $tsid (@tsids)
	{
		## Tune frontend
		my $frontend_params_href = $tuning_href->{'ts'}{$tsid} ;
		my $error_code ;
		if ($error_code = $self->set_frontend(%$frontend_params_href, 'timeout' => $self->timeout))
		{
			print STDERR "set_frontend() returned $error_code\n" if $DEBUG ;
			
			$info{$tsid}{'error'} = "Unable to tune frontend. " . dvb_error_str() ;
			if ($info{$tsid}{'error'} =~ /busy/i)
			{
				## stop now since the device is in use
				last ;
			}
		}
		else
		{
			## get info
			$info{$tsid} = $self->signal_quality($tsid) ;
			$info{$tsid}{'error'} = undef ;
		}
	}
	
	## restore error handling
	$self->{errmode} = $errmode ;
	
	
	## return info
	return %info ;
}



#============================================================================================

=back

=head3 RECORDING

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<record($file, $duration)>

(New version that uses the underlying multiplex recording methods).

Streams the selected channel information (see L</select_channel($channel_name)>) into the file $file for $duration.

The duration may be specified either as an integer number of minutes, or in HH:MM format (for hours & minutes), or in
HH:MM:SS format (for hours, minutes, seconds).

Note that (if possible) the method creates the directory path to the file if it doersn't already exist.

=cut

sub record
{
	my $self = shift ;
	my ($file, $duration) = @_ ;

print STDERR "record($file, $duration)" if $DEBUG ;

	## need filename
	return $self->handle_error("No valid filename specified") unless ($file) ;

	## need valid duration
	my $seconds = Linux::DVB::DVBT::Utils::time2secs($duration) ;
	return $self->handle_error("No valid duration specified") unless ($seconds) ;

	## Set up the multiplex info for this single file

	# create entry for this file 
	my $href = $self->_multiplex_file_href($file) ;
	
	# set time
	$href->{'duration'} = $seconds ;
	
	# set total length
	$self->{_multiplex_info}{'duration'} = $seconds ;
			
	# set demux filter info
	push @{$href->{'demux'}}, @{$self->{_demux_filters}};

	# get tsid
	my $frontend_href = $self->frontend_params() ;
	my $tsid = $frontend_href->{'tsid'} ;
	
	## Add in SI tables (if required) to the multiplex info
	my $error = $self->_add_required_si($tsid) ;
	$self->handle_error($error) if ($error) ;
	
	## ensure pid lists match the demux list
	$self->_update_multiplex_info($tsid) ;


	## Now record
Linux::DVB::DVBT::prt_data("multiplex_info=", $self->{'_multiplex_info'}) if $DEBUG>=10 ;

	my $rc = $self->multiplex_record(%{$self->{'_multiplex_info'}}) ;

	## Clear multiplex info ready for next time
	$self->multiplex_close() ;

	return $rc ;
}

#----------------------------------------------------------------------------

=item B<record_v1($file, $duration)>

Old version 1.xxx style recording. Kept in case newer version does something that you weren't
expecting. Note that this version will be phased out and removed in future releases. 

Streams the selected channel information (see L</select_channel($channel_name)>) into the file $file for $duration.

The duration may be specified either as an integer number of minutes, or in HH:MM format (for hours & minutes), or in
HH:MM:SS format (for hours, minutes, seconds).

Note that (if possible) the method creates the directory path to the file if it doersn't already exist.

=cut

sub record_v1
{
	my $self = shift ;
	my ($file, $duration) = @_ ;

	## need filename
	return $self->handle_error("No valid filename specified") unless ($file) ;

	## need valid duration
	my $seconds = Linux::DVB::DVBT::Utils::time2secs($duration) ;
	return $self->handle_error("No valid duration specified") unless ($seconds) ;

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	## ensure directory is present
	my $dir = dirname($file) ;
	if (! -d $dir)
	{
		# create dir
		mkpath([$dir], $DEBUG, 0755) or return $self->handle_error("Unable to create record directory $dir : $!") ;
	}
	
	print STDERR "Recording to $file for $duration ($seconds secs)\n" if $DEBUG ;

	# save raw transport stream to file 
	my $rc = dvb_record($self->{dvb}, $file, $seconds) ;
	return $self->handle_error("Error during recording : $rc") if ($rc) ;
	
	return 0 ;
}



#============================================================================================

=back

=head3 EPG

=over 4

=cut

#============================================================================================


#----------------------------------------------------------------------------

=item B<epg()>

Gathers the EPG information into a HASH using the previously tuned frontend and 
returns the EPG info. If the frontend is not yet tuned then the method attempts
to use the tuning information (either from a previous scan or from reading the config
files) to set up the frontend.

Note that you can safely run this method while recording; the EPG scan does not affect
the demux or the frontend (once it has been set)

Returns an array:

	[0] = EPG HASH
	[1] = Dates HASH

EPG HASH format is:

    $channel_name =>
       $pid => {
		'pid'			=> program unique id (= $pid)
		'channel'		=> channel name
		
		'date'			=> date
		'start'			=> start time
		'end'			=> end time
		'duration'		=> duration
		
		'title'			=> title string (program/series/film title)
		'subtitle'		=> Usually the epsiode name
		'text'			=> synopsis string
		'etext'			=> extra text (not usually used)
		'genre'			=> genre string
		
		'episode'		=> episode number
		'num_episodes' => number of episodes

		'subtitle'		=> this is a short program name (useful for saving as a filename)
		
		'tva_prog'		=> TV Anytime program id
		'tva_series'	=> TV Anytime series id
		
		'flags'			=> HASH ref to flags (see below)
	}

i.e. The information is keyed on channel name and program id (pid)

The genre string is formatted as:

    "Major category|genre/genre..."

For example:

    "Film|movie/drama (general)"

This allows for a simple regexp to extract the information (e.g. in a TV listings application 
you may want to only use the major category in the main view, then show the extra genre information in
a more detailed view).

Note that the genre information is mostly correct (for films) but is not reliable. Most programs are tagged as 'show' 
(even some films!).

The flags HASH format is:

	# audio information
	'mono'			=> flag set if program is in mono
	'stereo'		=> flag set if program is in stereo
	'dual-mono'		=> flag set if program is in 2 channel mono
	'multi'			=> flag set if program is in multi-lingual, multi-channel audio
	'surround'		=> flag set if program is in surround sound
	'he-aac'		=> flag set if component descriptor indicates audio is in HE-ACC format
	
	# video information
	'4:3'			=> flag set if program is in 4:3 
	'16:9'			=> flag set if program is in 16:9 
	'hdtv'			=> flag set if program is in high definition 
	'h264'			=> flag set if component descriptor indicates video is in .H264 format
	
	'subtitles'		=> flag set if subtitles (for the hard of hearing) are available for this program
				
	'new'			=> flag set if description mentions that this is a new program/series

Note that (especially for DVB-T2 HD-TV channels) not all of the flags that should be set *are* set! It depends on the broadcaster.

Dates HASH format is:

    $channel_name => {
		'start_date'	=> date of first program for this channel 
		'start'			=> start time of first program for this channel
		
		'end_date'		=> date of last program for this channel 
		'end'			=> end time of last program for this channel
	}

i.e. The information is keyed on channel name

The dates HASH is created so that an existing EPG database can be updated by removing existing information for a channel between the indicated dates.

=cut


sub epg
{
	my $self = shift ;
	my ($section) = @_ ;		# debug only!
	
	$section ||= 0 ;

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	my %epg ;
	my %dates ;

	# Get tuning information
	my $tuning_href = $self->get_tuning_info() ;
prt_data("tuning hash=", $tuning_href) if $DEBUG >= 2 ;

	# Create a lookup table to convert [tsid-pnr] values into channel names & channel numbers 
	my $channel_lookup_href ;
	my $channels_aref = $self->get_channel_list() ;
	if ( $channels_aref && $tuning_href )
	{
#print STDERR "creating chan lookup\n" ;
#prt_data("Channels=", $channels_aref) ;
#prt_data("Tuning=", $tuning_href) ;
		$channel_lookup_href = {} ;
		foreach my $chan_href (@$channels_aref)
		{
			my $channel = $chan_href->{'channel'} ;

#print STDERR "CHAN: $channel\n" ;
			if (exists($tuning_href->{'pr'}{$channel}))
			{
#print STDERR "created CHAN: $channel for $tuning_href->{pr}{$channel}{tsid} -  for $tuning_href->{pr}{$channel}{pnr}\n" ;
				# create the lookup
				$channel_lookup_href->{"$tuning_href->{'pr'}{$channel}{tsid}-$tuning_href->{'pr'}{$channel}{pnr}"} = {
					'channel' => $channel,
					'channel_num' => $tuning_href->{'pr'}{$channel}{'lcn'} || $chan_href->{'channel_num'},
				} ;
			}
		}
	}	
prt_data("Lookup=", $channel_lookup_href) if $DEBUG >= 2 ;


	## check for frontend tuned
	
	# list of carrier frequencies to tune to
	my @next_freq ;
	
	# if not tuned yet, tune to all station freqs (assumes scan has been performed)
	if (!$self->frontend_params())
	{
		# Grab first channel settings & attempt to set frontend
		if ($tuning_href)
		{
			@next_freq = values %{$tuning_href->{'ts'}} ;
			
			if ($DEBUG)
			{
				print STDERR "FREQ LIST:\n" ;
				foreach (@next_freq)
				{
					print STDERR "  $_->{frequency} Hz\n" ;
				}
			}
			
			my $params_href = shift @next_freq ;
prt_data("Set frontend : params=", $params_href) if $DEBUG >= 2 ;
			my $rc = $self->set_frontend(%$params_href, 'timeout' => $self->timeout) ;
			return $self->handle_error("Unable to tune frontend. Is aerial connected?)") if ($rc != 0) ;
		}
	}

	# start with a cleared list
	dvb_clear_epg() ;
	
	# collect all the EPG data from all carriers
	my $params_href ;
	my $epg_data ;
	do
	{		
		# if not tuned by now then we have to raise an error
		if (!$self->frontend_params())
		{
			# Raise an error
			return $self->handle_error("Frontend must be tuned before gathering EPG data (have you run scan() yet?)") ;
		}
	
		# Gather EPG information into a list of HASH refs (collects all previous runs)
		$epg_data = dvb_epg($self->{dvb}, $VERBOSE, $DEBUG, $section) ;

		# tune to next carrier in the list (if any are left)
		$params_href = undef ;
		if (@next_freq)
		{
			$params_href = shift @next_freq ;
prt_data("Retune params=", $params_href)  if $DEBUG >= 2 ;
			$self->set_frontend(%$params_href, 'timeout' => $self->timeout) ;
		}
	}
	while ($params_href) ;

	printf("Found %d EPG entries\n", scalar(@$epg_data)) if $VERBOSE ;

prt_data("EPG data=", $epg_data) if $DEBUG>=2 ;

	## get epg statistics
	my $epg_stats = dvb_epg_stats($self->{dvb}) ;


	# ok to clear down the low-level list now
	dvb_clear_epg() ;
		
	# Analyse EPG info
	foreach my $epg_entry (@$epg_data)
	{
		my $tsid = $epg_entry->{'tsid'} ;
		my $pnr = $epg_entry->{'pnr'} ;

		my $chan = "$tsid-$pnr" ;		
		my $channel_num = $chan ;
		
		if ($channel_lookup_href)
		{
			# Replace channel name with the text name (rather than tsid/pnr numbers) 
			$channel_num = $channel_lookup_href->{$chan}{'channel_num'} || $chan ;
			$chan = $channel_lookup_href->{$chan}{'channel'} || $chan ;
		}
		
prt_data("EPG raw entry ($chan)=", $epg_entry) if $DEBUG>=2 ;
		
		# {chan}
		#	{pid}
		#              date => 18-09-2008,
		#              start => 23:15,
		#              end => 03:20,
		#              duration => 04:05,
		#
		#              title => Personal Services,
		#              text => This is a gently witty, if curiously coy, attempt by director
		#              genre => Film,
		#              
		#              episode => 1
		#			   num_episodes => 2
		#

		my @start_localtime =  localtime($epg_entry->{'start'}) ;
		my $start = strftime "%H:%M:%S", @start_localtime ;
		my $date  = strftime "%Y-%m-%d", @start_localtime ;

		my $pid_date = strftime "%Y%m%d", @start_localtime ;
		my $pid = "$epg_entry->{'id'}-$channel_num-$pid_date" ;	# id is reused on different channels 
		
		my @end_localtime =  localtime($epg_entry->{'stop'}) ;
		my $end = strftime "%H:%M:%S", @end_localtime ;
		my $end_date  = strftime "%Y-%m-%d", @end_localtime ;

prt_data("Start Time: start=$start, date=$date,  localtime=", \@start_localtime) if $DEBUG>=10 ;
prt_data("End Time:   end=$end,   date=$end_date,  localtime=", \@end_localtime) if $DEBUG>=10 ;


		# keep track of dates
		$dates{$chan} ||= {
			'start_min'	=> $epg_entry->{'start'},
			'end_max'	=> $epg_entry->{'stop'},
			
			'start_date'	=> $date,
			'start'			=> $start,
			'end_date'		=> $end_date,
			'end'			=> $end,
		} ;

		if ($epg_entry->{'start'} < $dates{$chan}{'start_min'})
		{
			$dates{$chan}{'start_min'} = $epg_entry->{'start'} ;
			$dates{$chan}{'start_date'} = $date ;
			$dates{$chan}{'start'} = $start ;
		}
		if ($epg_entry->{'stop'} > $dates{$chan}{'end_max'})
		{
			$dates{$chan}{'end_max'} = $epg_entry->{'stop'} ;
			$dates{$chan}{'end_date'} = $end_date ;
			$dates{$chan}{'end'} = $end ;
		}


		## Set the duration explicitly to allow for BST->GMT clock changes etc
		my $duration = Linux::DVB::DVBT::Utils::duration($start, $end) ;
#		my $duration ;
#		{	
#			my $secs = $epg_entry->{'duration_secs'} ;
#			my $mins = int($secs/60) ;
#			my $hours = int($mins/60) ;
#			$mins = $mins % 60 ;
#	
#			$duration = sprintf "%02d:%02d", $hours, $mins ;
#		}
		
		my $title = Linux::DVB::DVBT::Utils::text($epg_entry->{'name'}) ;
		my $synopsis = Linux::DVB::DVBT::Utils::text($epg_entry->{'stext'}) ;
		my $etext = Linux::DVB::DVBT::Utils::text($epg_entry->{'etext'}) ;
		my $subtitle = "" ;
		
		my $episode ;
		my $num_episodes ;
		my $new_program = 0 ;
		my %flags ;
		
		Linux::DVB::DVBT::Utils::fix_title(\$title, \$synopsis) ;
		Linux::DVB::DVBT::Utils::fix_synopsis(\$title, \$synopsis, \$new_program) ;	# need to call this before fix_episodes to remove "New series"
		Linux::DVB::DVBT::Utils::fix_episodes(\$title, \$synopsis, \$episode, \$num_episodes) ;
		Linux::DVB::DVBT::Utils::fix_audio(\$title, \$synopsis, \%flags) ;
		Linux::DVB::DVBT::Utils::subtitle(\$synopsis, \$subtitle) ;
			
		my $epg_flags = $epg_entry->{'flags'} ;
		
		$epg{$chan}{$pid} = {
			'pid'		=> $pid,
			'channel'	=> $chan,
			
			'date'		=> $date,
			'start'		=> $start,
			'end'		=> $end,
			'duration'	=> $duration,
			
			'title'		=> $title,
			'subtitle'	=> $subtitle,
			'text'		=> $synopsis,
			'etext'		=> $etext,
			'genre'		=> $epg_entry->{'genre'} || '',

			'episode'	=> $episode,
			'num_episodes' => $num_episodes,
			
			'tva_prog'	=> $epg_entry->{'tva_prog'} || '',
			'tva_series'=> $epg_entry->{'tva_series'} || '',

			'flags'		=> {
				'mono'			=> $epg_flags & $EPG_FLAGS{'AUDIO_MONO'} ? 1 : 0,
				'stereo'		=> $epg_flags & $EPG_FLAGS{'AUDIO_STEREO'} ? 1 : 0,
				'dual-mono'		=> $epg_flags & $EPG_FLAGS{'AUDIO_DUAL'} ? 1 : 0,
				'multi'			=> $epg_flags & $EPG_FLAGS{'AUDIO_MULTI'} ? 1 : 0,
				'surround'		=> $epg_flags & $EPG_FLAGS{'AUDIO_SURROUND'} ? 1 : 0,
				'he-aac'		=> $epg_flags & $EPG_FLAGS{'AUDIO_HEAAC'} ? 1 : 0,

				'4:3'			=> $epg_flags & $EPG_FLAGS{'VIDEO_4_3'} ? 1 : 0,
				'16:9'			=> $epg_flags & $EPG_FLAGS{'VIDEO_16_9'} ? 1 : 0,
				'hdtv'			=> $epg_flags & $EPG_FLAGS{'VIDEO_HDTV'} ? 1 : 0,
				'h264'			=> $epg_flags & $EPG_FLAGS{'VIDEO_H264'} ? 1 : 0,

				'subtitles'		=> $epg_flags & $EPG_FLAGS{'SUBTITLES'} ? 1 : 0,
				
				'new'			=> $new_program,
			},
		} ;
		
		## Process strings
		foreach my $field (qw/title subtitle text/)
		{
			# ensure filled with something
			if (!$epg{$chan}{$pid}{$field})
			{
				$epg{$chan}{$pid}{$field} = 'unknown' ;
			}
		}
		

prt_data("EPG final entry ($chan) $pid=", $epg{$chan}{$pid}) if $DEBUG>=2 ;

	}
	
	## analyse statistics
	my %epg_statistics ;
	$epg_statistics{'totals'} = $epg_stats->{'totals'} ;
	foreach my $part_href (@{$epg_stats->{'parts'}})
	{
		my ($tsid, $pnr, $parts, $parts_left) = @{$part_href}{qw/tsid pnr parts parts_left/} ;
		$epg_statistics{'parts'}{$tsid}{$pnr} = {
			'parts'			=> $parts,
			'parts_left'	=> $parts_left,
		} ;
	}
	foreach my $err_href (@{$epg_stats->{'errors'}})
	{
		my ($freq, $section, $errors) = @{$err_href}{qw/freq section errors/} ;
		$epg_statistics{'errors'}{$freq}{$section} = $errors ;
	}

prt_data("** EPG STATS ** =", \%epg_statistics) if $DEBUG ;
		
	return (\%epg, \%dates, \%epg_statistics) ;
}


#============================================================================================

=back

=head3 MULTIPLEX RECORDING

=over 4

=cut

#============================================================================================



#----------------------------------------------------------------------------

=item B<add_demux_filter($pid, $pid_type [, $tsid])>

Adds a demultiplexer filter for the specified PID to allow that stream to be recorded.

Internally keeps track of the list of filters created (see L</demux_filter_list()> for format of the
list entries)

$pid_type is a string and should be one of:

	"video"
	"audio"
	"teletext"
	"subtitle"
	"other"

Optionally a tsid may be specified. This will be used if to tune the frontend if it has not yet been tuned.

Returns 0 for success; error code otherwise.

=cut

sub add_demux_filter
{
	my $self = shift ;
	my ($pid, $pid_type, $tsid, $demux_params_href) = @_ ;

	$tsid ||= "0" ;
	
printf STDERR "add_demux_filter(pid=$pid, type=$pid_type, tsid=$tsid)\n", $pid if $DEBUG ;

	## valid pid?
	if ( ($pid < 0) || ($pid > $MAX_PID) )
	{
		return $self->handle_error("Invalid PID ($pid)") ;
	}

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	## start with current tuning params
	my $frontend_href = $self->frontend_params() ;
prt_data("frontend_href=", $frontend_href) if $DEBUG >= 5 ;

	# re-tune if not the same tsid
	if ($frontend_href)
	{
		my $current_tsid = $frontend_href->{'tsid'} || "" ;
		$frontend_href = undef if $current_tsid ne $tsid ;
	}
	
	# check tuning
	if (!$frontend_href)
	{
print STDERR " frontend not yet tuned...\n" if $DEBUG >= 5 ;
		## if we've got a tsid, then use that to get the parameters and tune the frontend
		if ($tsid)
		{
print STDERR " + got tsid=$tsid, attempting tune\n" if $DEBUG >= 5 ;
			# ensure we have the tuning info
			my $tuning_href = $self->get_tuning_info() ;
			if (! $tuning_href)
			{
				return $self->handle_error("Unable to get tuning information") ;
			}
			
			# get frontend params
			$frontend_href = Linux::DVB::DVBT::Config::tsid_params($tsid, $tuning_href) ;
			if (! $frontend_href)
			{
				return $self->handle_error("Unable to get frontend parameters for specified TSID ($tsid)") ;
			}
			
			# Tune frontend
			if ($self->set_frontend(%$frontend_href, 'timeout' => $self->timeout))
			{
				return $self->handle_error("Unable to tune frontend") ;
			}
print STDERR " + frontend tuned to tsid=$tsid\n" if $DEBUG >= 5 ;
		}
	}

	## final check
	if (!$frontend_href)
	{
		# Raise an error
		return $self->handle_error("Frontend must be tuned before setting demux filter (have you run scan() yet?)") ;
	}

	## next try setting the filter
	my $fd = dvb_add_demux($self->{dvb}, $pid) ;

	if ($fd <= 0)
	{
		# Raise an error
		return $self->handle_error("Unable to create demux filter for pid $pid") ;
	}

printf STDERR "added demux filter : PID = 0x%03x ( fd = $fd )\n", $pid if $DEBUG ;

	## Create filter information
	if (exists($frontend_href->{'tsid'}))
	{
		# frontend set during normal operation via internal routines
		$tsid = $frontend_href->{'tsid'} ;
	}
	else
	{
		# Someone has called the frontend setup routine directly, so update TSID to match!
		my $tuning_href = $self->get_tuning_info() ;
		$tsid = Linux::DVB::DVBT::Config::find_tsid($frontend_href->{'frequency'}, $tuning_href) ;

		# save tsid
		$frontend_href->{'tsid'} = $tsid ;
	}
	my $filter_href = {
		'fd'		=> $fd,
		'tsid'		=> $tsid,
		'pid'		=> $pid,
		'pidtype'	=> $pid_type,
		
		## keep track of the associated program's demux params  
		'demux_params'	=> $demux_params_href,
	} ;

	push @{$self->{_demux_filters}}, $filter_href ;

	return 0 ;
}


#----------------------------------------------------------------------------

=item B<demux_filter_list()>

Return the list of currently active demux filters.

Each filter entry in the list consists of a HASH ref of the form:

	'fd'		=> file handle for this filter
	'tsid'		=> Transponder ID
	'pid'		=> Stream PID
	'pidtype'	=> $pid_type,

=cut

sub demux_filter_list
{
	my $self = shift ;
	return $self->{_demux_filters} ;
}

#----------------------------------------------------------------------------

=item B<close_demux_filters()>

Closes any currently open demux filters (basically tidies up after finished recording)

=cut

sub close_demux_filters
{
	my $self = shift ;

#prt_data("close_demux_filters() dvb=", $self->{dvb}, "Demux filters=", $self->{_demux_filters}) ;

	# hardware closed?
	unless ($self->dvb_closed())
	{
		foreach my $filter_href (@{$self->{_demux_filters}} )
		{
			dvb_del_demux($self->{dvb}, $filter_href->{fd}) ;
		}
	}
	$self->{_demux_filters} = [] ;
}

#----------------------------------------------------------------------------

=item B<multiplex_close()>

Clears out the list of recordings for a multiplex. Also releases any demux filters.

=cut


# clear down any records
sub multiplex_close
{
	my $self = shift ;

	$self->close_demux_filters() ;
	$self->{_multiplex_info} = {
		'duration' 	=> 0,
		'tsid'	 	=> 0,
		'files'		=> {},
	} ;
}

#----------------------------------------------------------------------------

=item B<multiplex_parse($chan_spec_aref, @args)>

Helper function intended to be used to parse a program's arguments list (@ARGV). The arguments
are parsed into the provided ARRAY ref ($chan_spec_aref) that can then be passed to L</multiplex_select($chan_spec_aref, %options)>
(see that method for a description of the $chan_spec_aref ARRAY).

The arguments define the set of streams (all from the same multiplex, or transponder) that are to be recorded
at the same time into each file. 

Each stream definition must start with a filename, followed by either channel names or pid numbers. Also, 
you must specify the duration of the stream. Finally, an offset time can be specified that delays the start of 
the stream (for example, if the start time of the programs to be recorded are staggered).

The list of recognised arguments is:

=over 4

=item f|file

Filename

=item c|chan

Channel name

=item p|pid

PID number

=item lan|lang

L</Language Specification>

=item out

L</Output Specification>

=item len|duration

Recording duration (specified in HH:MM or HH:MM:SS format, or as minutes)

=item off|offset

Start offset (specified in HH:MM or HH:MM:SS format, or as minutes)

=item title

Title name (reserved for future use)

=item ev|event

Event id used for timeslipping (see L</Timeslip Specification>)

=item tslip|timeslip

Program start/end/both extended (see L</Timeslip Specification>)

=item max|max_timeslip

Maximum timeslip time (specified in HH:MM or HH:MM:SS format, or as minutes)  (see L</Timeslip Specification>)

=back

=back


=head3 Output Specification
 
A file defined by channel name(s) may optionally also contain a language spec and an output spec: 

The output spec determines which type of streams are included in the recording. By default, "video" and "audio" tracks are recorded. You can
override this by specifying the output spec. For example, if you also want the subtitle track to be recorded, then you need to
specify the output includes video, audio, and subtitles. This can be done either by specifying the types in full or by just their initials.

For example, any of the following specs define video, audio, and subtitles:

	"audio, video, subtitle"
	"a, v, s"
	"avs"

Note that, if the file format explicitly defines the type of streams required, then there is no need to specify an output spec. For example,
specifying that the file format is mp3 will ensure that only the audio is recorded.


=head3 Language Specification

In a similar fashion, the language spec determines the audio streams to be recorded in the program. Normally, the default audio stream is included 
in the recorded file. If you want either an alternative audio track, or additional audio tracks, then you use the language spec to 
define them. The spec consists of a space seperated list of language names. If the spec contains a '+' then the audio streams are 
added to the default; otherwise the default audio is B<excluded> and only those other audio tracks in the spec are recorded. Note that
the specification order is important, audio streams from the language spec are matched with the audio details in the specified order. Once a 
stream has been skipped there is no back tracking (see the examples below for clarification).

For example, if a channel has the audio details: eng:601 eng:602 fra:603 deu:604 (i.e. 2 English tracks, 1 French track, 1 German) then

=over 4

=item lang="+eng"

Results in the default audio (pid 601) and the next english track (pid 602) recorded

=item lang="fra"

Results in just the french track (pid 603) recorded

=item lang="eng fra"

Results in the B<second> english (pid 602) and the french track (pid 603) recorded

=item lang="fra eng"

Results in an error. The english tracks have already been skipped to match the french track, and so will not be matched again.

=back

Note that the output spec overrides the language spec. If the output does not include audio, then the language spec is ignored.


=head3 Timeslip Specification
 
Timeslip recording uses the now/next live EPG information to track the start and end of the program being recorded. This information
is transmit by the broadcaster and (hopefully) is a correct reflection of the broadcast of the program. Using this feature should then
allow recordings to be adjusted to account for late start of a program (for example, due to extended news or sports events).

To use the feature you MUST specify the event id of the program to be recorded. This information is the same event id that is gathered
by the L</epg()> function. By default, the timeslip will automatically extend the end of the recording by up to 1 hour (recording stops
automatically when the now/next information indicates the real end of the program).

=over 4

=item event=41140

Sets the event id to be 41140

=back

Optionally you can specify a different maximum timeslip time using the 'max_timeslip' argument. Specify the time in minutes (or HH:MM or HH:MM:SS).
Note that this has a different effect depending on the B<timeslip> setting (which specifies the program 'edge'):

=over 4

=item max_timeslip=2:00

Sets the maximum timslip time to be 2 hours (i.e. by default, the recording end can be extended by up to 2 hours)

=back


Also, you can set the 'edge' of the program that is to be timeslipped using the B<timeslip> parameter:

=over 4

=item timeslip=end

Timeslips only the end of the recording. This means that the recording will record for the normal duration, and then check to see if
the specified event (B<event_id>) has finished broadcasting. If not, the recording continues until the program finishes OR the maximum timeslip
duration has expired.

This is the default.

=item timeslip=start

Timeslips only the start of the recording. This means that the recording will not start until the event begins broadcasting. Once started, the 
specified duration will be recorded.

Note that this can mean that you miss a few seconds at the start of the program (which is why the default is to just extend the end of the recording).

=item timeslip=both

Performs both start and end recording timeslipping.

=back


=head3 Examples

Example valid sets of arguments are:

=over 4

=item file=f1.mpeg chan=bbc1 out=avs lang=+eng len=1:00 off=0:10

Record channel BBC1 into file f1.mpeg, include subtitles, add second English audio track, record for 1 hour, start recording 10 minutes from now

=item file=f2.mp3 chan=bbc2 len=0:30

Record channel BBC2 into file f2.mp3, audio only, record for 30 minutes

=item file=f3.ts pid=600 pid=601 len=0:30

Record pids 600 & 601 into file f3.ts, record for 30 minutes

=back

=over 4

=cut

my %multiplex_params = (
	'^f'				=> 'file',
	'^c'				=> 'chan',
	'^p'				=> 'pid',
	'^lan'				=> 'lang',
    '^sublang'			=> 'sublang',
	'^out'				=> 'out',
	'^(len|duration)'	=> 'duration',
	'^off'				=> 'offset',
	'^title'			=> 'title',
	
	'^ev'				=> 'event_id',
	'^(tslip|timeslip)'	=> 'timeslip',
	'^max'				=> 'max_timeslip',
	
) ;
sub multiplex_parse 
{ # modified by rainbowcrypt
	my $self = shift ;
	my ($chan_spec_aref, @args) = @_ ;

	## work through the args
	my $current_file_href ;
	my $current_chan_href ;
	foreach my $arg (@args)
	{
		## skip non-valid
		
		# strip off any extra quotes
		if ($arg =~ /(\S+)\s*=\s*([\'\"]{0,1})([^\2]*)\2/)
		{
			my ($var, $value, $valid) = (lc $1, $3, 0) ;

			# allow fuzzy input - convert to known variable names
			foreach my $regexp (keys %multiplex_params)
			{
				if ($var =~ /$regexp/)
				{
					$var = $multiplex_params{$regexp} ;
					++$valid ;
					last ;
				}
			}
			
			# check we know this var
			if (!$valid)
			{
				return $self->handle_error("Unexpected variable \"$var = $value\"") ;
			}
			
			# new file
			if ($var eq 'file')
			{
				$current_chan_href = undef ;
				$current_file_href = {
					'file'			=> $value,
					'chans'			=> [],
					'pids'			=> [],
					
					'event_id'		=> -1,
					'timeslip'		=> 'off',
					'max_timeslip'	=> 0,
				} ;
				push @$chan_spec_aref, $current_file_href ;
				next ;
			}
			else
			{
				# check file has been set before moving on
				return $self->handle_error("Variable \"$var = $value\" defined before specifying the filename") 
					unless defined($current_file_href) ;
			}

			# duration / offset
			my $handled ;
			foreach my $genvar (qw/duration offset/)
			{
				if ($var eq $genvar)
				{
					$current_file_href->{$genvar} = $value ;
					++$handled ;
					last ;
				}
			}
			next if $handled ;
			
			# new pid
			if ($var eq 'pid')
			{
				push @{$current_file_href->{'pids'}}, $value ;
				next ;
			}
			
			# event_id setting
			if ($var eq 'event_id')
			{
				$current_file_href->{'event_id'} = $value ;
				next ;
			}
			
			# timeslip setting
			if ($var eq 'timeslip')
			{
				$current_file_href->{'timeslip'} = 'end' ;
				if ($value =~ /both/i)
				{
					$current_file_href->{'timeslip'} = 'both' ;
				}
				if ($value =~ /start/i)
				{
					$current_file_href->{'timeslip'} = 'start' ;
				}
				next ;
			}
			
			# maximum slippage setting
			if ($var eq 'max_timeslip')
			{
				$current_file_href->{'max_timeslip'} = $value ;
				next ;
			}
			
			# new chan
			if ($var eq 'chan')
			{
				$current_chan_href = {
					'chan'	=> $value,
				} ;
				push @{$current_file_href->{'chans'}}, $current_chan_href ;
				next ;
			}
			else
			{
				# check chan has been set before moving on
				return $self->handle_error("Variable \"$var = $value\" defined before specifying the channel") 
					unless defined($current_chan_href) ;
			}
			
			# lang / out - requires chan
			foreach my $chvar (qw/lang out/)
			{
				if ($var eq $chvar)
				{
					$current_chan_href->{$chvar} = $value ;
					last ;
				}
			}
			
		    # sublang - requires chan #by rainbowcrypt
			if ($var eq 'sublang')
			{
				$current_chan_href->{'sublang'} = $value ;
                next ;
			}

		}
		else
		{
			return $self->handle_error("Unexpected arg \"$arg\"") ;
		}
	}	
	
	## Check entries for required information
	foreach my $spec_href (@$chan_spec_aref)
	{
		my $file = $spec_href->{'file'} ;
		if (!$spec_href->{'duration'})
		{
			return $self->handle_error("File \"$file\" has no duration specified") ;
		}
		if (! @{$spec_href->{'pids'}} && ! @{$spec_href->{'chans'}})
		{
			return $self->handle_error("File \"$file\" has no channels/pids specified") ;
		}
#		if (@{$spec_href->{'pids'}} && @{$spec_href->{'chans'}})
#		{
#			return $self->handle_error("File \"$file\" has both channels and pids specified at the same time") ;
#		}
	}
		
	return 0 ;
}

#----------------------------------------------------------------------------

=item B<multiplex_select($chan_spec_aref, %options)>

Selects a set of streams based on the definitions in the chan spec ARRAY ref. The array 
contains hashes of:

	{
		'file'		=> filename
		'chans'		=> [ 
			{ 'chan' => channel name, 'lang' => lang spec, 'out' => output },
			... 
		]
		'pids'		=> [ stream pid, ... ]
		'offset'	=> time
		'duration'	=> time
	}

Each entry must contain a target filename, a recording duration, and either channel definitions or pid definitions.
The channel definition list consists of HASHes containing a channel name, a language spec, and an output spec. 

The language and output specs are as described in L</multiplex_parse($chan_spec_aref, @args)>

The optional options hash consists of:

	{
		'tsid'			=> tsid
		'lang'			=> default lang spec
		'out'			=> default output spec
		'no-pid-check'	=> when set, allows specification of any pids
	}

The TSID definition defines the transponder (multiplex) to use. Use this when pids define the streams rather than 
channel names and the pid value(s) may occur in multiple TSIDs.

If you define default language or output specs, these will be used in all file definitions unless that file definition
has it's own output/language spec. For example, if you want all files to include subtitles you can specify it once as
the default rather than for every file.

The method sets up the DVB demux filters to record each of the required streams. It also sets up a HASH of the settings,
which may be read using L</multiplex_info()>. This hash being used in L</multiplex_record(%multiplex_info)>.

Setting the 'no-pid-check' allows the recording of pids that are not known to the module (i.e. not in the scan files). This is
for experimental use.

=cut


sub multiplex_select
{
	my $self = shift ;
	my ($chan_spec_aref, %options) = @_ ;
	
	my $error = 0 ;

print STDERR "multiplex_select()\n" if $DEBUG>=10 ;

	## ensure we have the tuning info
	my $tuning_href = $self->get_tuning_info() ;
	if (! $tuning_href)
	{
		return $self->handle_error("Unable to get tuning information from config file (have you run scan() yet?)") ;
	}

	# hardware closed?
	if ($self->dvb_closed())
	{
		# Raise an error
		return $self->handle_error("DVB tuner has been closed") ;
	}

	## start with clean slate
	$self->multiplex_close() ;	

	my %files ;

	## Defaults
	my $def_lang = $options{'lang'} || "" ;
	my $def_lang_sub = $options{'sublang'} || ""; #by rainbowcrypt
	my $def_out = $options{'out'} || "" ;

	## start with TSID option
	my $tsid = $options{'tsid'} ;
	
	## process each entry
	my $demux_count = 0 ;
	foreach my $spec_href (@$chan_spec_aref)
	{
		my $file = $spec_href->{'file'} ;
		if ($file)
		{
			my $need_eit = 0 ;
			
			## get entry for this file (or create it)
			my $href = $self->_multiplex_file_href($file) ;
			
			# keep track of file settings
			$files{$file} ||= {'chans'=>0, 'pids'=>0} ;

			# add error if already got pids for this file
			if ( $files{$file}{'pids'} )
			{
				return $self->handle_error("Cannot mix chan definitions with pid definitions for file \"$file\"") ;
			}

			# set time
			$href->{'offset'} ||= Linux::DVB::DVBT::Utils::time2secs($spec_href->{'offset'} || 0) ;
			$href->{'duration'} ||= Linux::DVB::DVBT::Utils::time2secs($spec_href->{'duration'} || 0) ;

			# title
			$href->{'title'} ||= $spec_href->{'title'} ;
			

			# types of streams present
			$href->{'audio'} = 0 ;
			$href->{'video'} = 0 ;
			$href->{'subtitle'} = 0 ;
			
			# list of channel names
			$href->{'channels'} = [] ;
			

			# event_id
			$href->{'event_id'} ||= $spec_href->{'event_id'} || -1 ;
			
			# timeslip
			$href->{'timeslip_start'} ||= 0 ;
			$href->{'timeslip_end'} ||= 0 ;
			if ($href->{'event_id'} >= 0)
			{
				## only enable timeslip if we've got an event id
				if ($spec_href->{'timeslip'} =~ /start|both/)
				{
					$href->{'timeslip_start'} = 1 ;
				}
				if ($spec_href->{'timeslip'} =~ /end|both/)
				{
					$href->{'timeslip_end'} = 1 ;
				}
				
				## default to slip end
				if (!$href->{'timeslip_start'} && !$href->{'timeslip_end'})
				{
					$href->{'timeslip_end'} = 1 ;
				}
				
				## need to add EIT to perform the timeslip
				++$need_eit ;
			}

			# slippage time (default = 1 hour)
			$href->{'max_timeslip'} = Linux::DVB::DVBT::Utils::time2secs($spec_href->{'max_timeslip'} || 3600) ;
			
			# calc total length
			my $period = $href->{'offset'} + $href->{'duration'} ;
			$self->{_multiplex_info}{'duration'}=$period if ($self->{_multiplex_info}{'duration'} < $period) ;
			
			# chans
			$spec_href->{'chans'} ||= [] ;
			foreach my $chan_href (@{$spec_href->{'chans'}})
			{
				my $channel_name = $chan_href->{'chan'} ;
				my $lang = $chan_href->{'lang'}  || $def_lang ;
				my $lang_sub = $chan_href->{'sublang'}  || $def_lang_sub ; #by rainbowcrypt
				my $out = $chan_href->{'out'} || $def_out ;
				
				push @{$href->{'channels'}}, $channel_name ;
				
				# find channel
				my ($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel($channel_name, $tuning_href) ;
				if (! $frontend_params_href)
				{
					return $self->handle_error("Unable to find channel $channel_name") ;
				}

				# check in same multiplex
				$tsid ||= $frontend_params_href->{'tsid'} ;
				if ($tsid ne $frontend_params_href->{'tsid'})
				{
					return $self->handle_error("Channel $channel_name (on TSID $frontend_params_href->{'tsid'}) is not in the same multiplex as other channels/pids (on TSID $tsid)") ;
				}
				
				# Ensure the combination of file format, output spec, and language spec are valid. They get adjusted as required
				my $dest_file = $file ;
				$error = Linux::DVB::DVBT::Ffmpeg::sanitise_options(\$dest_file, \$out, \$lang,
					$href->{'errors'}, $href->{'warnings'}) ;
				return $self->handle_error($error) if $error ;

				# save settings
				my $ext = (fileparse($dest_file, '\..*'))[2] ;
				
				$href->{'destfile'} = $dest_file ;
				$href->{'destext'} = $ext ;
				$href->{'out'} = $out ;
				$href->{'lang'} = $lang ;
				$href->{'sublang'} = $lang_sub; # by rainbowcrypt

				# Handle output specification to get a list of pids
				my @pids ;
				$error = Linux::DVB::DVBT::Config::out_pids($demux_params_href, $out, $lang, $lang_sub, \@pids) ; #by rainbowcrypt
				return $self->handle_error($error) if $error ;
				
				if ($need_eit)
				{
					push @pids, {
						'pid' => $SI_TABLES{'EIT'}, 
						'pidtype' => 'EIT', 
							
						'demux_params'	=> undef,
					} ;
					
					## clear flag otherwise we'll record it twice!
					$need_eit = 0 ;
				}

prt_data(" + Add pids for chan = ", \@pids) if $DEBUG >= 15 ;
				
				# add filters
				foreach my $pid_href (@pids)
				{
					# add filter
					$error = $self->add_demux_filter($pid_href->{'pid'}, $pid_href->{'pidtype'}, $tsid, $pid_href->{'demux_params'}) ;
					return $self->handle_error($error) if $error ;
					
					# keep demux filter info
					push @{$href->{'demux'}}, $self->{_demux_filters}[-1] ;
					
					# keep track of the stream types for this file
					$href->{'video'}=1 if ($pid_href->{'pidtype'} eq 'video') ;
					$href->{'audio'}=1 if ($pid_href->{'pidtype'} eq 'audio') ;
					$href->{'subtitle'}=1 if ($pid_href->{'pidtype'} eq 'subtitle') ;
					
					
					++$files{$file}{'chans'} ;
				}
			}
			

			# pids
			$spec_href->{'pids'} ||= [] ;
			if ($need_eit)
			{
				push @{$spec_href->{'pids'}}, $SI_TABLES{'EIT'} ;
			}

			
			foreach my $pid (@{$spec_href->{'pids'}})
			{
				# array of: { 'pidtype'=>$type, 'tsid' => $tsid, ... } for this pid value
				my $pid_href ;
				my @pid_info = Linux::DVB::DVBT::Config::pid_info($pid, $tuning_href) ;

				if (!@pid_info)
				{
					# can't find pid - see if it's a standard SI table
					my $new_pid_href = $self->_si_pid($pid, $tsid) ;
					push @pid_info, $new_pid_href if $new_pid_href ;
				}
				if (! @pid_info)
				{
					# can't find pid
					if ($options{'no-pid-check'})
					{
						# create a simple entry if we allow any pids
						$pid_href = {
							'pidtype' 	=> 'data',
							'tsid'	=> $tsid,
						} ;
					}
					else
					{
						return $self->handle_error("Unable to find PID $pid in the known list stored in your config file") ;
					}
				}
				elsif (@pid_info > 1)
				{
					# if we haven't already got a tsid, use the first
					if (!$tsid)
					{
						$pid_href = $pid_info[0] ;
					}
					else
					{
						# find entry with matching TSID
						foreach (@pid_info)
						{
							if ($_->{'tsid'} eq $tsid)
							{
								$pid_href = $_ ;
								last ;
							}
						}
					}

					# error if none match
					if (!$pid_href)
					{
						return $self->handle_error("Multiple multiplexes contain pid $pid, please specify the multiplex number (tsid)") ;
					}
				}
				else
				{
					# found a single one
					$pid_href = $pid_info[0] ;
				}
				
				# set filter
				if ($pid_href)
				{
prt_data(" + Add pid = ", $pid_href) if $DEBUG >= 15 ;

					# check multiplex
					$tsid ||= $pid_href->{'tsid'} ;
					if (!defined($tsid) || !defined($pid_href->{'tsid'}) || ($tsid ne $pid_href->{'tsid'}) )
					{
						return $self->handle_error("PID $pid (on TSID $pid_href->{'tsid'}) is not in the same multiplex as other channels/pids (on TSID $tsid)") ;
					}
					
					# add a filter
					$error = $self->add_demux_filter($pid, $pid_href->{'pidtype'}, $tsid, $pid_href->{'demux_params'}) ;
					return $self->handle_error($error) if $error ;
					
					# keep demux filter info
					push @{$href->{'demux'}}, $self->{_demux_filters}[-1] ;

					# keep track of the stream types for this file
					$href->{'video'}=1 if ($pid_href->{'pidtype'} eq 'video') ;
					$href->{'audio'}=1 if ($pid_href->{'pidtype'} eq 'audio') ;
					$href->{'subtitle'}=1 if ($pid_href->{'pidtype'} eq 'subtitle') ;
					
					
					$files{$file}{'pids'}++ ;
				}
			}
			
			# add up all of the demux filters 
			$demux_count += scalar(@{$href->{'demux'}}) ;
		}		
	}
	
	# check that at least one demux filter has been added
	if ( !$demux_count )
	{
		$error = "No demux filters added (are you trying to record a special channel?)" ;
		return $self->handle_error($error) ;
	}
	
	## Add in SI tables (if required) to the multiplex info
	$error = $self->_add_required_si($tsid) ;
	
	## ensure pid lists match the demux list
	$self->_update_multiplex_info($tsid) ;

	return $error ;
}	

#----------------------------------------------------------------------------

=item B<multiplex_record_duration()>

Returns the total recording duration (in seconds) of the currently spricied multiplex recordings.

Used for informational purposes.

=cut

sub multiplex_record_duration
{
	my $self = shift ;
	
	return $self->{_multiplex_info}{'duration'} ;
}

#----------------------------------------------------------------------------

=item B<multiplex_info()>

Returns HASH of the currently defined multiplex filters. HASH is of the form:

  files => {
	$file => {
		'pids'	=> [
			{
				'pid'	=> Stream PID
				'pidtype'	=> pid type (i.e. 'audio', 'video', 'subtitle')
			},
			...
		]
		'offset' => offset time for this file
		'duration' => duration for this file

		'destfile'	=> final written file name (set by L</multiplex_transcode(%multiplex_info)>)
		'warnings'	=> [
			ARRAY ref of list of warnings (set by L</multiplex_transcode(%multiplex_info)>)
		],
		'errors'	=> [
			ARRAY ref of list of errors (set by L</multiplex_transcode(%multiplex_info)>)
		],
		'lines'	=> [
			ARRAY ref of lines of output from the transcode/demux operation(s) (set by L</multiplex_transcode(%multiplex_info)>)
		],
	},
  },
  duration => maximum recording duration in seconds
  tsid => the multiplex id

where there is an entry for each file, each entry containing a recording duration (in seconds),
an offset time (in seconds), and an array of pids that define the streams required for the file.

After recording, the multiplex info HASH 'pids' information also contains:

		'pids'	=> [
			{
				'pid'	=> Stream PID
				'pidtype'	=> pid type (i.e. 'audio', 'video', 'subtitle')

				'pkts'    	=> Number of recorded packets
				'errors'  	=> Transport stream error count
				'overflows' => Count of DVBT buffer overflows during recording
				'timeslip_start_secs' => Number of seconds the recording start has been slipped by
				'timeslip_end_secs'   => Number of seconds the recording end has been slipped by
			},

=cut

sub multiplex_info
{
	my $self = shift ;
	
	return %{$self->{_multiplex_info}} ;
}

#----------------------------------------------------------------------------

=item B<multiplex_record(%multiplex_info)>

Records the selected streams into their files. Note that the recorded files will
be the specified name, but with the extension set to '.ts'. You can optionally then
call L</multiplex_transcode(%multiplex_info)> to transcode the files into the requested file format.

=cut

sub multiplex_record
{
	my $self = shift ;
	my (%multiplex_info) = @_ ;
	
	my $error = 0 ;

Linux::DVB::DVBT::prt_data("multiplex_record() : multiplex_info=", \%multiplex_info) if $DEBUG>=10 ;

	# process information ready for C code 
	my @stats_fields = qw/errors overflows pkts timeslip_start_secs timeslip_end_secs/ ;
	my @multiplex_info ;
	foreach my $file (keys %{$multiplex_info{'files'}} )
	{
		my $href = {
			'_file'				=> $file,
			'pids'				=> [],
		} ;
		
		foreach my $field (@stats_fields)
		{
			$href->{$field} = {} ;
		}

		# copy scalars
		#
		foreach (qw/offset duration destfile/)
		{
			$href->{$_} = $multiplex_info{'files'}{$file}{$_} || 0 ;
		}
		
		
		# copy service_id (i.e. pnr)
		foreach my $demux_href (@{$multiplex_info{'files'}{$file}{'demux'}})
		{
			if (exists($demux_href->{'demux_params'}) && $demux_href->{'demux_params'})
			{
				$href->{'pnr'} = $demux_href->{'demux_params'}{'pnr'} ;
			}
		}
		
		## Set event information
		##
		foreach (qw/event_id timeslip_start timeslip_end max_timeslip/)
		{
			$href->{$_} = $multiplex_info{'files'}{$file}{$_} || 0 ;
		}
		
		# placeholder in case we need to record to intermediate .ts file
		$multiplex_info{'files'}{$file}{'tsfile'} = "" ;
		
		# if file type is .ts, then leave everything; otherwise save the requested file name
		# and change source filename to .ts
		my ($name, $destdir, $suffix) = fileparse($multiplex_info{'files'}{$file}{'destfile'}, '\..*');
print STDERR " + dest=$multiplex_info{'files'}{$file}{'destfile'} : name=$name dir=$destdir ext=$suffix\n" if $DEBUG>=10 ;
		if (lc $suffix ne '.ts')
		{
			# modify destination so that we record to it
			$href->{'destfile'} = "$destdir$name.ts" ;
			
			# report intermediate file
			$multiplex_info{'files'}{$file}{'tsfile'} = "$destdir$name.ts" ;

print STDERR " + + mod extension\n" if $DEBUG>=10 ;
		}

		# fill in the pid info
		foreach my $pid_href (@{$multiplex_info{'files'}{$file}{'pids'}})
		{
			my $pid = $pid_href->{'pid'} ;
			push @{$href->{'pids'}}, $pid ;
			
			foreach my $field (@stats_fields)
			{
				$href->{$field}{$pid} = 0 ;
			}
		}
		push @multiplex_info, $href ;
		
		# check directory exists
		if (! -d $destdir) 
		{
			mkpath([$destdir], $DEBUG, 0755) or return $self->handle_error("Error: unable to create directory \"$destdir\" : $!") ;
		}
		
		# make sure we can write file
		my $destfile = $href->{'destfile'} ;
		open my $fh, ">$destfile" or return $self->handle_error("Error: unable to write to file \"$destfile\" : $!") ;
		close $fh ;
	}

Linux::DVB::DVBT::prt_data(" + info=", \@multiplex_info) if $DEBUG>=10 ;

	## @multiplex_info = (
	#		{
	#			destfile	=> recorded ts file
	#			pids		=> [
	#				pid,
	#				pid,
	#				...
	#			]
	#			
	#		}
	#	
	#	)

	## do the recordings
	my $options_href = {} ;
	if (exists($multiplex_info{'options'}))
	{
		$options_href = $multiplex_info{'options'} ;
	}
	$error = dvb_record_demux($self->{dvb}, \@multiplex_info, $options_href) ;
	return $self->handle_error(dvb_error_str()) if $error ;

Linux::DVB::DVBT::prt_data(" + returned info=", \@multiplex_info) if $DEBUG ;
	
	## Pass error counts back
	## @multiplex_info = (
	#		{
	#			destfile	=> recorded ts file
	#			pids		=> [
	#				pid1,
	#				pid2,
	#				...
	#			],
	#			errors		=> {
	#				pid1	=> error_count1,
	#				pid2	=> error_count2,
	#				...
	#			}
	#			overflows		=> {
	#				pid1	=> overflow_count1,
	#				pid2	=> overflow_count2,
	#				...
	#			}
	#			pkts		=> {
	#				pid1	=> packet_count1,
	#				pid2	=> packet_count2,
	#				...
	#			}
	#			
	#		}
	#	
	#	)
	foreach my $href (@multiplex_info)
	{
Linux::DVB::DVBT::prt_data(" + + href=", $href) if $DEBUG ;
		my $file = $href->{'_file'} ;
		#files => {
		#	$file => {
		#		'pids'	=> [
		#			{
		#				'pid'	=> Stream PID
		#				'pidtype'	=> pid type (i.e. 'audio', 'video', 'subtitle')
		#			},
		#			...
		#		]
		foreach my $pid_href (@{$multiplex_info{'files'}{$file}{'pids'}})
		{
			my $pid = $pid_href->{'pid'} ;
#print STDERR " - PID $pid (file=$file)\n" ;

			foreach my $field (@stats_fields)
			{
				$pid_href->{$field} = 0 ;
				if (exists($href->{$field}{$pid}))
				{
					$pid_href->{$field} = $href->{$field}{$pid} ;
				}
			}
		}
	}
	
	return $error ;
}


#----------------------------------------------------------------------------

=item B<multiplex_transcode(%multiplex_info)>

Transcodes the recorded files into the requested formats (uses ffmpeg helper module).

If the destination file format is the same as the recorded format (i.e. transport file)
then no transcoding is performed, but a check is made to ensure the file duration is correct. 

Sets the following fields in the %multiplex_info HASH:

	$file => {

		...

		'destfile'	=> final written file name
		'warnings'	=> [
			ARRAY ref of list of warnings
		],
		'errors'	=> [
			ARRAY ref of list of errors
		],
		'lines'	=> [
			ARRAY ref of lines of output from the transcode/demux operation(s)
		],
	}

See L<Linux::DVB::DVBT::Ffmpeg::ts_transcode()|Ffmpeg::ts_transcode($srcfile, $destfile, $multiplex_info_href, [$written_files_href])> for further details.

=cut

sub multiplex_transcode
{
	my $self = shift ;
	my (%multiplex_info) = @_ ;

Linux::DVB::DVBT::prt_data("multiplex_transcode() : multiplex_info=", \%multiplex_info) if $DEBUG>=10 ;
	
	my $error = 0 ;
	my @errors ;
	
	## keep track of each filename as it is written, so we don't overwrite anything
	my %written_files ;
	
	## process each file
	foreach my $file (keys %{$multiplex_info{'files'}})
	{
Linux::DVB::DVBT::prt_data("Call ts_transcode for file=$file with : info=", $multiplex_info{'files'}{$file}) if $DEBUG>=10 ;

		# run ffmpeg (or just do video duration check)
		$error = Linux::DVB::DVBT::Ffmpeg::ts_transcode(
#			$multiplex_info{'files'}{$file}{'destfile'}, 
#			$multiplex_info{'files'}{$file}{'_destfile'}, 
			$multiplex_info{'files'}{$file}{'tsfile'}, 
			$multiplex_info{'files'}{$file}{'destfile'}, 
			$multiplex_info{'files'}{$file}, 
			\%written_files) ;
		
		# collect all errors together
		if ($error)
		{
			push @errors, "FILE: $file" ;
			push @errors, @{$multiplex_info{'files'}{$file}{'errors'}} ;
		}
	}
	
	# handle all errors in one go
	if (@errors)
	{
		$error = join "\n", @errors ;
		return $self->handle_error($error) ;
	}
	return $error ;
}


#============================================================================================

=back

=head3 DEBUG UTILITIES

=over 4

=cut

#============================================================================================


=item B<prt_data(@list)>

Print out each item in the list, showing HASH hierarchies. Handles scalars, 
hashes (as an array), arrays, ref to scalar, ref to hash, ref to array, object.

Useful for debugging.

=cut


#=====================================================================
# MODULE USAGE
#=====================================================================
#


#---------------------------------------------------------------------
sub _setup_modules
{
	# Attempt to load Debug object
	if (_load_module('Debug::DumpObj'))
	{
		# Create local function
		*prt_data = sub {print STDERR Debug::DumpObj::prtstr_data(@_)} ;
	}
	else
	{
		# See if we've got Data Dummper
		if (_load_module('Data::Dumper'))
		{
			# Create local function
			*prt_data = sub {print STDERR Data::Dumper->Dump([@_])} ;
		}	
		else
		{
			# Create local function
			*prt_data = sub {print STDERR @_, "\n"} ;
		}
	}

}

#---------------------------------------------------------------------
sub _load_module
{
	my ($mod) = @_ ;
	
	my $ok = 1 ;

	# see if we can load up the package
	if (eval "require $mod") 
	{
		$mod->import() ;
	}
	else 
	{
		# Can't load package
		$ok = 0 ;
	}
	return $ok ;
}


# ============================================================================================
BEGIN {
	# Debug only
	_setup_modules() ;
}


#============================================================================================

=back

=head3 INTERNAL METHODS

=over 4

=cut

#============================================================================================


#-----------------------------------------------------------------------------

=item B<hwinit()>

I<Object internal method>

Initialise the hardware (create dvb structure). Called once and sets the adpater &
frontend number for this object.

If no adapter number has been specified yet then use the first device in the list.

=cut

sub hwinit
{
	my $self = shift ;

	my $info_aref = $self->devices() ;

	## Check for special adapter:frontend specification
	if (defined($self->adapter))
	{
		my ($adap, $fe) = split(/:/, $self->adapter) ;
		$self->adapter_num($adap) if defined($adap) ;
		$self->frontend_num($fe) if defined($fe) ;
	}


	# If no adapter set, use first in list
	if (!defined($self->adapter_num))
	{
		# use first device found
		if (scalar(@$info_aref))
		{
			$self->set(
				'adapter_num' => $info_aref->[0]{'adapter_num'},
				'frontend_num' => $info_aref->[0]{'frontend_num'},
			) ;
			$self->_device_index(0) ;
		}
		else
		{
			return $self->handle_error("Error: No adapters found to initialise") ;
		}
	}
	
	# If no frontend set, use first in list
	if (!defined($self->frontend_num))
	{
		# use first frontend found
		if (scalar(@$info_aref))
		{
			my $adapter = $self->adapter_num ;
			my $dev_idx=0;
			foreach my $device_href (@$info_aref)
			{
				if ($device_href->{'adapter_num'} == $adapter)
				{
					$self->frontend_num($device_href->{'frontend_num'}) ;				
					$self->_device_index($dev_idx) ;
					last ;
				}
				++$dev_idx ;
			}
		}
		else
		{
			return $self->handle_error("Error: No adapters found to initialise") ;
		}
	}
	
	## ensure device exists
	if (!defined($self->_device_index))
	{
		my $adapter = $self->adapter_num ;
		my $fe = $self->frontend_num ;
		my $dev_idx=0;
		foreach my $device_href (@$info_aref)
		{
			if ( ($device_href->{'adapter_num'} == $adapter) && ($device_href->{'frontend_num'} == $fe) )
			{
				$self->_device_index($dev_idx) ;
				last ;
			}
			++$dev_idx ;
		}
		if (!defined($self->_device_index))
		{
			return $self->handle_error("Error: Specified adapter ($adapter) and frontend ($fe) does not exist") ;
		}
	}
	
	## set info ref
	my $dev_idx = $self->_device_index() ;
	$self->_device_info($info_aref->[$dev_idx]) ;
	
	# Create DVB 
	my $dvb = dvb_init_nr($self->adapter_num, $self->frontend_num) ;
	$self->dvb($dvb) ;

	# get & set the device names
	my $names_href = dvb_device_names($dvb) ;
	$self->set(%$names_href) ;
	
	# Set adapter
	$self->adapter( sprintf("%d:%d", $self->adapter_num, $self->frontend_num) ) ;
	
}

#----------------------------------------------------------------------------

=item B<log_error($error_message)>

I<Object internal method>

Add the error message to the error log. Get the log as an ARRAY ref via the 'errors()' method

=cut

sub log_error
{
	my $self = shift ;
	my ($error_message) = @_ ;
	
	push @{$self->errors()}, $error_message ;
	
}

#-----------------------------------------------------------------------------

=item B<dvb_closed()>

Returns true if the DVB tuner has been closed (or failed to open).

=cut

sub dvb_closed
{
	my $self = shift ;

	return !$self->{dvb} ;
}


#-----------------------------------------------------------------------------
# return current (or create new) file entry in multiplex_info
sub _multiplex_file_href
{
	my $self = shift ;
	my ($file) = @_ ;
	
	$self->{_multiplex_info}{'files'}{$file} ||= {

		# start with this being the same as the requested filename
		'destfile'	=> $file,
		
		# init
		'offset' 	=> 0,
		'duration' 	=> 0,
		'title' 	=> '',
		'warnings'	=> [],
		'errors'	=> [],
		'lines'		=> [],
		'demux'		=> [],

		# beta: title
		'title' 	=> '',
	} ;
	my $href = $self->{_multiplex_info}{'files'}{$file} ;

	return $href ;
}

#-----------------------------------------------------------------------------
# Add in the required SI tables to any recording that requires it OR if the 'add_si'
# option is set
sub _add_required_si
{
	my $self = shift ;
	my ($tsid) = @_ ;
	my $error ;

	# get flag
	my $force_si = $self->{'add_si'} ;

	# set tsid if not already set
	$self->{_multiplex_info}{'tsid'} ||= $tsid ;

print STDERR "_add_required_si(tsid=$tsid, force=$force_si)\n" if $DEBUG>=10 ;
prt_data("current mux info=", $self->{_multiplex_info}) if $DEBUG>=15 ;
	
	foreach my $file (keys %{$self->{_multiplex_info}{'files'}})
	{
		my $add_si = $force_si ;

		## get entry for this file (or create it)
		my $href = $self->_multiplex_file_href($file) ;
		
		## check pids looking for non-audio/video (get pnr for later)
		my $demux_params_href ;
		my %pids ;
		foreach my $demux_href (@{$self->{_multiplex_info}{'files'}{$file}{'demux'}})
		{
			# keep track of the pids scheduled
			++$pids{ $demux_href->{'pid'} } ;
			
			# get HASH ref to program's demux params
			$demux_params_href = $demux_href->{'demux_params'} if ($demux_href->{'demux_params'}) ;

			# see if non-av
			if ( ($demux_href->{'pidtype'} ne 'audio') && ($demux_href->{'pidtype'} ne 'video') )
			{
				++$add_si ;
			}
		}

		my $pmt = $demux_params_href->{'pmt'} ;
		my $pcr = $demux_params_href->{'pcr'} ;
print STDERR " + file=$file : add=$add_si  pmt=$pmt  pcr=$pcr\n" if $DEBUG>=10 ;
prt_data("demux_params_href=", $demux_params_href) if $DEBUG>=10 ;
prt_data("scheduled PIDS==", \%pids) if $DEBUG>=10 ;

		## Add tables if necessary (and possible!)
		if ($add_si)
		{
			if (!$pmt)
			{
				$error = "Unable to determine PMT pid (have you re-scanned with this latest version?)" ;
				return $self->handle_error($error) ;
			}
			else
			{
				foreach my $pid_href (
					{ 'pidtype' => 'PAT',	'pid' => $SI_TABLES{'PAT'}, },
#					{ 'pidtype' => 'SDT',	'pid' => $SI_TABLES{'SDT'}, },
#					{ 'pidtype' => 'TDT',	'pid' => $SI_TABLES{'TDT'}, },
					{ 'pidtype' => 'PMT',	'pid' => $pmt, },
					{ 'pidtype' => 'PCR',	'pid' => $pcr, },
				)
				{
print STDERR " + pid=$pid_href->{'pid'} pidtype=$pid_href->{'pidtype'}\n" if $DEBUG>=10 ;

					# skip any already scheduled
					next unless defined($pid_href->{'pid'}) ;
					next if exists($pids{ $pid_href->{'pid'} }) ;
					
print STDERR " + check defined..\n" if $DEBUG>=10 ;
					next unless defined($pid_href->{'pid'}) ;

print STDERR " + add filter..\n" if $DEBUG>=10 ;
					
					# add filter
					$error = $self->add_demux_filter($pid_href->{'pid'}, $pid_href->{'pidtype'}, $tsid, $demux_params_href) ;
					return $self->handle_error($error) if $error ;
					
					# keep demux filter info
					push @{$href->{'demux'}}, $self->{_demux_filters}[-1] ;
				}
			}
		}
	}

prt_data("final mux info=", $self->{_multiplex_info}) if $DEBUG>=15 ;
	
	return $error ;
}


#-----------------------------------------------------------------------------
# Ensure that the multiplex_info HASH is up to date (pids match the demux list)
sub _update_multiplex_info
{
	my $self = shift ;
	my ($tsid) = @_ ;

	$self->{_multiplex_info}{'tsid'} ||= $tsid ;
	
	foreach my $file (keys %{$self->{_multiplex_info}{'files'}})
	{
		$self->{_multiplex_info}{'files'}{$file}{'pids'} = [] ;
		
		# fill in the pid info
		foreach my $demux_href (@{$self->{_multiplex_info}{'files'}{$file}{'demux'}})
		{
			push @{$self->{_multiplex_info}{'files'}{$file}{'pids'}}, {
				'pid'	=> $demux_href->{'pid'},
				'pidtype'	=> $demux_href->{'pidtype'},
			} ;
		}
	}
}

#-----------------------------------------------------------------------------
# Check to see if pid is an SI table
sub _si_pid
{
	my $self = shift ;
	my ($pid, $tsid, $pmt) = @_ ;
	my $pid_href ;

	# check for SI
	if (exists($SI_LOOKUP{$pid}))
	{
		$pid_href = {
			'tsid'	=> $tsid,
			'pidtype'	=> $SI_LOOKUP{$pid},
			'pmt'	=> 1,
		} ;
	}

	
	# if not found & pnr specified, see if it's PMT
	if (!$pid_href && $pmt)
	{
		$pid_href = {
			'tsid'	=> $tsid,
			'pidtype'	=> 'PMT',
			'pmt'	=> $pmt,
		} ;
	}

	return $pid_href ;
}

#-----------------------------------------------------------------------------
sub _no_once_warning
{
	return \%Linux::DVB::DVBT::Constants::CONSTANTS ;
}

# ============================================================================================

sub AUTOLOAD 
{
    my $this = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    my $class = $AUTOLOAD;
    $class =~ s/::[^:]+$//;  # get class

    my $type = ref($this) ;
    
	# possibly going to set a new value
	my $set=0;
	my $new_value = shift;
	$set = 1 if defined($new_value) ;
	
	# 1st see if this is of the form undef_<name>
	if ($name =~ m/^undef_(\w+)$/)
	{
		$set = 1 ;
		$name = $1 ;
		$new_value = undef ;
	}

	# check for valid field
	unless (exists($FIELDS{$name})) 
	{
		croak "Error: Attempting to access invalid field $name on $class";
	}

	# ok to get/set
	my $value = $this->{$name};

	if ($set)
	{
		$this->{$name} = $new_value ;
	}

	# Return previous value
	return $value ;
}



# ============================================================================================
# END OF PACKAGE
1;

__END__

=back

=head1 ACKNOWLEDGEMENTS

=head3 Debugging

Special thanks to Thomas Rehn, not only for providing feedback on a number of latent bugs but also for his
patience in re-running numerous test versions to gather the debug data I needed. Thanks Thomas.

Also, thanks to Arthur Gidlow for running various tests to debug a scanning issue.


=head3 Gerd Knorr for writing xawtv (see L<http://linux.bytesex.org/xawtv/>)

Some of the C code used in this module is used directly from Gerd's libng. All other files
are entirely written by me, or drastically modified from Gerd's original to (a) make the code
more 'Perl friendly', (b) to reduce the amount of code compiled into the library to just those
functions required by this module.  

=head3 w_scan (see L<http://wirbel.htpc-forum.de/w_scan/index_en.html>)

The country codes and frequency information used by L</scan_from_country($iso3166)> are based on the information
found in the w_scan program. I've used some of this information (only the DVB-T info) but I haven't copied (or used) 
any of the C code itself.


=head1 AUTHOR

Steve Price

Please report bugs using L<http://rt.cpan.org>.

=head1 CONTRIBUTORS

Jean-Michel Masereel - Thanks for adding support for multi-language subtitles

=head1 BUGS

None that I know of!

=head1 FEATURES

The current release supports:

=over 4

=item *

DVB-T2 support (i.e. HD TV). I've modified the libraries so that they correctly understand the DVB-T2 types used
to transport the MPEG4 video. This has been tested using a PCTV 290e DVB-T/T2 usb stick (using the experimental drivers
available at http://git.linuxtv.org/media_build.git). So now scanning and recording will work with HD channels.

(For more information on using the PCTV 290e see http://stevekerrison.com/290e/). 

=item *

Scan using country code (i.e. scanning through supported frequencies) as well as using a frequency file.

=item *

The module now stores the previous scan setting in the configuration files so that subsequent scans can be performed
without needing to refer to a frequency file.

=item *

Timeslip recording so that the end (and/or start) of the recording is extended if the program broadcast is delayed.

=item *

Tuning to a channel based on "fuzzy" channel name (i.e. you can specify a channel with/without spaces, in any case, and with
numerals or number names)  

=item *

Transport stream recording (i.e. program record) with large file support

=item *

Electronic program guide. Builds the TV/radio listings as a HASH structure (which you can then store into a database, file etc and use
to schedule your recordings)

=item *

Option to record all/any of the audio streams for a program (e.g. allows for descriptive audio for visually impaired)

=item *

Recording of any streams within a multiplex at the same time (i.e. multi-channel recording using a single DVB device)

=item *

Additional module providing wrappers to ffmpeg as "helper" programs to transcode recorded files (either during "normal" or "multiplex" recording). 

=back


=head1 FUTURE

Subsequent releases will include:

=over 4

=item *

I'm looking into the option of writing the files directly as mpeg. Assuming I can work my way through the mpeg2 specification! 

=item *

Support for event-driven applications (e.g. POE). I need to re-write some of the C to allow for event-driven hooks (and special select calls)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steve Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

