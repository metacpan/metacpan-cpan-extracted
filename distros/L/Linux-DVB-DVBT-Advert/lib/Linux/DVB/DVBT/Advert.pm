package Linux::DVB::DVBT::Advert ;

=head1 NAME

Linux::DVB::DVBT::Advert - Advert (commercials) detection and removal

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Advert ;
  
	# Read advert config info
	my $ad_config_href = ad_config() ; 

	# skip advert detection
	if (!ok_to_detect($results_settings_href))
	{
		print "Skipping advert detection...\n" ;
		exit 0 ;
	}

	# detect
	my $settings_href = {
		'debug' => $DEBUG,
		'progress_callback' => \&progress,
	} ;
	$results_href = detect($file, $settings_href, $channel, $ad_config_href, $det) ;

	# .. or re-use saved deetction
	$results_href = detect_from_file($detect_file) ;
	
	# analyse
	my @cut_list = analyse($file, $results_href, $ad_config_href, $channel, $csv, $expected_aref, $settings_href) ;
	
	# remove adverts
	ad_cut($file, $cutfile, \@cut_list) ;
	
	# ..or split file at advert boundaries
	ad_split($file, $cutfile, \@cut_list) ;
	
	

=head1 DESCRIPTION

Module provides the interface into the advert (commercials) detection and removal utilities. 
As well as an underlying transport stream parsing framework, this module also incorporates 
MPEG2 video decoding and AAC audio decoding (see L<Linux::DVB::DVBT::TS> module for full details).

=head2 Basic Operation

Advert removal is split into 2 phases: detection and analysis. The detection phase processes the
video and audio data, producing raw statistics for each video frame (I effectively sunchronise the
audio frames and group their results into video frames). These raw statistics are then post-processed
in the analysis phase to determine the (hopefully!) actual location of the commercial breaks.

The detection phase is completely run in C code under XS; the analysis phase is completely run in Perl.


=head2 Settings

Settings are passed into the routines via a HASH ref. Settings also come from the default set, and
from any config file parameters. Please see L<Linux::DVB::DVBT::Advert::Config/Settings> for full details.

In general, you will probably only be interested in changing the analysis settings to tweak the results for
a particular channel (or to completely disable advert detection for a channel). The detection parameters
seem to be pretty good for all channels.

=head2 Results Files

The output from each phase can be stored into files for later re-use or analysis. The detection phase
output file can be reloaded and passed to the analyse phase multiple times to try out different analysis
settings. The analyse phase output can be plotted to show the effectiveness of the algorithms used.


=cut

#============================================================================================
# USES
#============================================================================================
use strict ;
use Env ;
use Carp ;
use File::Basename ;
use File::Path ;

use Linux::DVB::DVBT::Advert::Config ;
use Linux::DVB::DVBT::Advert::Constants ;

use Linux::DVB::DVBT::Advert::Mem ;

use Data::Dumper ;

#============================================================================================
# EXPORTER
#============================================================================================
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw/
	ad_config
	ad_debug
	detect
	detect_from_file
	analyse
	ad_cut
	ad_split
	ok_to_detect
/ ;

our @CHECK_OK = qw/
	read_adv
	adv_to_cutlist
/ ;

our @OK = qw/
	ad_config_search
	channel_settings
	read_expected
	write_default_config
/ ;

our @EXPORT_OK = (@OK, @CHECK_OK) ;

our %EXPORT_TAGS = (
	'all'		=> [ @EXPORT, @EXPORT_OK ],
	'check'		=> [ @EXPORT, @CHECK_OK  ],
) ;

#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '0.04' ;
our $DEBUG = 0 ;

our $USE_XS_MEM = 3 ;


#our $CONFIG_DIR = $Linux::DVB::DVBT::Advert::Config::DEFAULT_CONFIG_PATH ;
our $CONFIG_DIR ;

#============================================================================================
# XS
#============================================================================================
require XSLoader;

if (!$ENV{'ADVERT_NO_XS'})
{
	XSLoader::load('Linux::DVB::DVBT::Advert', $VERSION);
}
else
{
	print STDERR "WARNING: Running Linux::DVB::DVBT::Advert without XS\n" ;
}

#============================================================================================
BEGIN {
	
	$CONFIG_DIR = $Linux::DVB::DVBT::Advert::Config::DEFAULT_CONFIG_PATH ;
	
}

#============================================================================================
my $FPS = $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'FRAMES_PER_SEC'} ;
my $FRAME_FIELD	= 'frame' ;
my $FRAME_END_FIELD	= 'frame_end' ;
my $PROG_FIELD	= 'program' ;
my $PACKET_FIELD	= 'start_pkt' ;
my $PACKET_END_FIELD	= 'end_pkt' ;
my $PACKET_GOP_FIELD	= 'gop_pkt' ;
my $EXPECTED_FIELD	= 'expected' ;
my $LOGO_PROCESSED_FIELD = 'logo_proc' ;
my $LOGO_COALESCED_FIELD = 'logo_coal' ;
my $REDUCED_LOGO_COALESCED_FIELD = 'reduced_logo_coal' ;
my $BLACK_COALESCED_FIELD = 'black_coal' ;
my $SILENT_COALESCED_FIELD = 'silent_coal' ;
my $SILENT_BLACK_FIELD = 'silent_black' ;
my $REDUCED_SILENT_BLACK_FIELD = 'reduced_silent_black' ;

my $_FRAMENUMS_KEY = '_framenums' ;

#============================================================================================

=head2 Functions

=over 4

=cut


#----------------------------------------------------------------------

=item B<ad_config( [$search] )>

Get advert configuration information from a config file. Optionally sets the
search path - which is an ARRAY ref containing the list of directories to search.

Returns the HASH ref of advert settings.

=cut

sub ad_config
{
	my ($search) = @_ ;
	
	$search ||= $CONFIG_DIR ;
	$CONFIG_DIR = $search ;
	
	my $ad_config_href = Linux::DVB::DVBT::Advert::Config::read_dvb_adv($CONFIG_DIR) ;
	return $ad_config_href ;
}


#----------------------------------------------------------------------

=item B<ad_debug($level)>

Set debug level.

=cut

sub ad_debug
{
	my ($level) = @_ ;
	$DEBUG = $level if defined($level) ;
}


#----------------------------------------------------------------------

=item B<ad_config_search( [$new] )>

Get/set search path for advert config file.

Returns the current setting.

=cut

sub ad_config_search
{
	my ($new_path) = @_ ;
	
	if ($new_path)
	{
		$CONFIG_DIR = $new_path ;
	}
	return $CONFIG_DIR ;
}


#----------------------------------------------------------------------
#
#=item B<_advert_settings($ad_config_href [, $channel])>
#
#Using the reference to the tuning info HASH (normally read in by B<read()>), 
#returns a HASH containing just the advert settings information.
#
#If no channel name is specified then this just returns the global settings.
#If a channel name is specified (and that channel can be found in the settings HASH),
#then merges any global settings with the channel-sepcific settings.
#
#If I<$ad_config_href> is undef, then this function first reads the config files (NOTE: this will
#only use the default search path).
#
#Returns the HASH ref of settings.
#
#=cut

sub _advert_settings
{
	my ($ad_config_href, $channel) = @_ ;

print "_advert_settings($ad_config_href, $channel)\n"  if $DEBUG>=10 ;
	
	if (!$ad_config_href)
	{
		$ad_config_href = ad_config() ;
	}

print Data::Dumper->Dump(["_advert_settings($channel) advert settings:", $ad_config_href]) if $DEBUG>=10 ;

	my $settings_href = Linux::DVB::DVBT::Advert::Config::channel_settings($ad_config_href, $channel) ;

print Data::Dumper->Dump(["_advert_settings($channel) OUT:", $settings_href]) if $DEBUG>=10 ;
	
	return $settings_href ;
}


#-----------------------------------------------------------------------------

=item B<channel_settings($settings_href, $channel, $ad_config_href)>

Returns a HASH ref containing advert settings from the config file
(if available).

The B<$settings_href> settings HASH ref contains any new settings that the user wishes to 
use, overriding global values or config file values.

The B<$ad_config_href> parameter is expected to be the tuning info HASH ref read in using 
L<Linux::DVB::DVBT::Advert::Config::read_dvb_adv($dir)>. It is used to set any settings read in 
from the default config file. 

=cut

sub channel_settings
{
	my ($settings_href, $channel, $ad_config_href) = @_ ;

	$channel ||= "" ;

	## if channel specified, get channel-specific config
	my $config_settings_href = _advert_settings($ad_config_href, $channel) ;

	## Get defaults
	my $default_settings_href = Linux::DVB::DVBT::Advert::dvb_advert_def_settings() ;

	if ($DEBUG)
	{
		print Data::Dumper->Dump(["config settings:", $config_settings_href]) ;
		print Data::Dumper->Dump(["default settings:", $default_settings_href]) ;
	}
	
	## Merge them all together
	my $chan_settings_href = Linux::DVB::DVBT::Advert::Config::merge_settings(
								$default_settings_href,
								$config_settings_href,
								$settings_href,
							) ;

	return $chan_settings_href ;					
}


#-----------------------------------------------------------------------------

=item B<detect($src, $settings_href, $channel, $ad_config_href, $detect)>

Read the source TS file I<$src> and return a HASH containing the detection statistics
for each frame.

The B<$ad_config_href> parameter is expected to be the tuning info HASH ref read in using 
L<Linux::DVB::DVBT::Advert::Config::read($dir)>. It is used to set any settings read in 
from the default config file. If it is undef then a default search path is used.

The B<$settings_href> settings HASH ref contains any new settings that the user wishes to 
use, overriding global values or config file values.

The optional I<$channel> parameter is used to specify the TV channel that the video was recorded
from. This then allows the config fiel to contain channel-specific settings which are used in the
detection. If no channel is specified (or the channel name is not found in the config file) then just
default settings are used.

If the optional I<$detect> parameter is specified then the results are saved into the text file
named by the parameter

=cut

sub detect
{
	my ($src, $settings_href, $channel, $ad_config_href, $detect) = @_ ;

	if ($DEBUG)
	{
		print Data::Dumper->Dump(["===detect====", "settings:", $settings_href, "AD ($channel) config", $ad_config_href]) ;
	}
	
	$channel ||= "" ;
	my $results_href = {} ;

	## Get combined settings for this channel
	$settings_href = channel_settings($settings_href, $channel, $ad_config_href) ;

	if ($DEBUG)
	{
		print Data::Dumper->Dump(["channel settings:", $settings_href]) ;
	}
							
	## Skip if disabled
	if (ok_to_detect($settings_href))
	{					
		my $adata_ref ;

$settings_href->{'debug'} =0;
		
		## Do detection
		my $det_aref = Linux::DVB::DVBT::Advert::dvb_advert_detect($src, $settings_href) ;

		($results_href, $adata_ref) = @$det_aref ;

	if ($DEBUG)
	{
		print Data::Dumper->Dump(["after detect - results settings:", $results_href->{'settings'}]) ;
	}
		
		# tie an array to the internal data - this is *much* more effecient than letting Perl gobble up
		# 10x the memory
		my @frames ;
		tie @frames, 'Linux::DVB::DVBT::Advert', 'ADATA', [$$adata_ref] ;
		$results_href->{'frames'} = \@frames ;
		
		if ($DEBUG)
		{
			print "Read $results_href->{settings}{num_frames} frames\n" ;
			print Data::Dumper->Dump(["Results", $results_href]) ;
		}
	}
	
	## Optionally save results
	if ($detect)
	{
		open my $fh, ">$detect" or die "Error: unable to write to detect file $detect : $!" ;
		
		## Save settings
		my $save_settings_href = $results_href->{'settings'} ;
		foreach my $var (sort keys %$save_settings_href)
		{
			if (ref($save_settings_href->{$var}) eq 'HASH')
			{
				foreach my $subvar (sort keys %{$save_settings_href->{$var}})
				{
					print $fh "# $var.$subvar = $save_settings_href->{$var}{$subvar}\n" ;
				}
			}
			else
			{
				print $fh "# $var = $save_settings_href->{$var}\n" ;
			}
		}
		
		## Save frames
		my $frame_href = $results_href->{'frames'}[0] ;
		my $line = $FRAME_FIELD ;
		foreach my $field (sort keys %$frame_href)
		{
			next unless !ref($frame_href->{$field}) ;
			next if $field eq $FRAME_FIELD ;
			$line .= ",$field" ;
		}
		print $fh "$line\n" ;
		for (my $idx=0; $idx < $results_href->{'settings'}{'num_frames'}; ++$idx)
		{
			$frame_href = $results_href->{'frames'}[$idx] ;
			next unless scalar(keys %$frame_href) ;
			my $frame = $frame_href->{$FRAME_FIELD} ;
			$line = "$frame" ;
			foreach my $field (sort keys %$frame_href)
			{
				next unless !ref($frame_href->{$field}) ;
				next if $field eq $FRAME_FIELD ;
				$line .= ",$frame_href->{$field}" ;
			}
			print $fh "$line\n" ;
		}
		
		close $fh ;
	}
	
	return $results_href ;
}


#-----------------------------------------------------------------------------

=item B<detect_from_file($detect)>

Read the text file named by the I<$detect> parameter and return a HASH containing the detection statistics
for each frame. All settings are read in from the detection file (but any settings may be overridden in the 
L</analyse($src, $results_href, $ad_config_href, $csv, $expected_aref, $settings_href)> function).

=cut

sub detect_from_file
{
	my ($detect, $settings_href) = @_ ;
	
	$settings_href ||= {} ;

	# check file
	open my $fh, "<$detect" or die "Error: unable to read to detect file $detect : $!" ;
	close $fh ;
						
	## Do detection
	my $det_aref = Linux::DVB::DVBT::Advert::dvb_advert_detect_from_file($detect, $settings_href) ;

	my ($results_href, $adata_ref) = @$det_aref ;
	
	# tie an array to the internal data - this is *much* more effecient than letting Perl gobble up
	# 10x the memory
	my @frames ;
	tie @frames, 'Linux::DVB::DVBT::Advert', 'ADATA', [$$adata_ref] ;
	$results_href->{'frames'} = \@frames ;
#	$results_href->{'__adata'} = $adata_ref ;
	
	if ($DEBUG >= 10)
	{
		print "Read $results_href->{settings}{num_frames} frames\n" ;
		print Data::Dumper->Dump(["Results", $results_href]) ;
	}

	return $results_href ;
}



#-----------------------------------------------------------------------------

=item B<read_expected($src)>

Read in expected results file. Used more for debug / display purposes.

=cut

sub read_expected
{
	my ($expected_file) = @_ ;
	
	## check for expected results
	my @expected ;
#print "expected results: $expected_file\n" ;
	if (open my $fh, "<$expected_file")
	{
		my $line ;
		while (defined($line=<$fh>))
		{
			chomp $line ;

			# expected:
			#	 0)      1	  1387	0:00:55.43
			#	 1)  22208	 25186	0:01:59.12
			#	 2)  40451	 42151	0:01:08.00
			#	 3)  46763	 48741	0:01:19.12
			#
			if ($line =~ /^\s*(\d+)\)\s+(\d+)\s+(\d+)\s+(\d+):(\d+):(\d+)\.(\d+)/)
			{
				my ($idx, $start, $end, $hh, $mm, $ss, $ms) = ($1, $2, $3, $4, $5, $6, $7) ;
				push @expected, {
					'start'		=> $start,
					'end'		=> $end,
				} ;
				#print "$idx) $start .. $end\n" ;
			}
		}
		close $fh ;
	}

	return @expected ;
}


#-----------------------------------------------------------------------------

=item B<analyse($src, $results_href, $ad_config_href, $channel, $csv, $expected_aref, $settings_href)>

Process the results to create a cut list for the video using the results gathered by 
L</detect($src, $settings_href, $ad_config_href, $detect)> or L</detect_from_file($detect)>. 
Results from detection are stored in the B<$results_href> HASH ref.

The B<$ad_config_href> parameter is expected to be the tuning info HASH ref read in using 
L<Linux::DVB::DVBT::Advert::Config::read($dir)>. It is used to set any settings read in 
from the default config file. If it is undef then a default search path is used.

The optional I<$channel> parameter is used to specify the TV channel that the video was recorded
from. This then allows the config fiel to contain channel-specific settings which are used in the
detection. If no channel is specified (or the channel name is not found in the config file) then just
default settings are used.

Optionally specify a filename using B<$csv> to save the analysis results in a comma-separated
output file (from use in GUI viewing tool).

Optionally specify an ARRAY ref of expected results (read in using L</read_expected($src)>) to
allow the GUI viewing tool to mark the positions of the expected program breaks.

Optionally specify extra settings in order to override the defaults and those used during detection.


=cut


sub analyse
{
	my ($src, $results_href, $ad_config_href, $channel, $csv, $expected_aref, $extra_settings_href) = @_ ;

	my @cut_list = () ;

	Linux::DVB::DVBT::Advert::Mem::print_used("Start of analyse") ;
	
	## Frame results
	my $frames_adata_aref = $results_href->{'frames'} ;
	
	## Should contain all the settings used during detection
	my $results_settings_href = $results_href->{'settings'} || {} ;
	
	# if no channel specified try using value stored in results
	$channel ||= $results_settings_href->{'channel'} ; 

	if ($DEBUG)
	{
		print Data::Dumper->Dump(["===analyse====", "det file settings:", $results_settings_href]) ;
	}
	
	# get defaults used by C routines
	my $default_settings_href = Linux::DVB::DVBT::Advert::dvb_advert_def_settings() ;
	if ($DEBUG)
	{
		print Data::Dumper->Dump(["defaults:", $default_settings_href]) ;
	}
	
	# merge together all defaults with the settings used during detection to create a complete set of settings
	$results_settings_href = Linux::DVB::DVBT::Advert::Config::merge_settings(
									$default_settings_href,
									$results_settings_href,
								) ;
	
	## if channel specified, get channel-specific config
	my $config_settings_href = _advert_settings($ad_config_href, $channel) ;
	
	if ($DEBUG)
	{
		print Data::Dumper->Dump(["config file settings [chan=$channel]:", $config_settings_href]) ;
	}
	
	## Merge together the default 
	$extra_settings_href = Linux::DVB::DVBT::Advert::Config::merge_settings(
									$config_settings_href,
									$extra_settings_href,
								) ;

	## Add expected results
	# actually a list of adverts (i.e. and advert is between start & end)
	if ($expected_aref && (ref($expected_aref) eq 'ARRAY') )
	{
		my $expect_href = shift @$expected_aref ;
		foreach my $frame_href (@$frames_adata_aref)
		{
			my $framenum = $frame_href->{'frame'} ;
			$frame_href->{$EXPECTED_FIELD} = 1 ;
			if ($expect_href)
			{
				if ( ($framenum >= $expect_href->{'start'}) && ($framenum <= $expect_href->{'end'}) )
				{
					$frame_href->{$EXPECTED_FIELD} = 0 ;
				}
				elsif ($framenum > $expect_href->{'end'})
				{
					$expect_href = shift @$expected_aref ;
				}
			}
		}
	}
	
prt_frames($frames_adata_aref) if $DEBUG >= 3 ;
	
	# total number of frames
	my $last_frame = -1 ;
	if (scalar(@$frames_adata_aref))
	{
		$last_frame = $frames_adata_aref->[-1]{'frame'} ;
	}
	my $total_frames = $last_frame + 1 ;
	$results_settings_href->{'num_frames'} = $total_frames ;
	
	return @cut_list unless $total_frames ;
	
	
	# total packets
	my $total_pkts = $frames_adata_aref->[$last_frame]{'end_pkt'} ;

print "== analyse() == : total frames:$total_frames, pkts:$total_pkts\n" if $DEBUG ;

	## Split frame results out into arrays (containing the HASH refs stored in results) where the specified
	## field flag is true
	my $black_frames_ada_ref = frames_list($results_href, 'black_frame') ;
#	my $scene_frames_ada_aref = frames_list($results_href, 'scene_frame') ;
#	my $size_frames_ada_aref = frames_list($results_href, 'size_change') ;
	my $logo_frames_ada_aref = frames_list($results_href, 'logo_frame') ;
	my $silent_frames_ada_aref = frames_list($results_href, 'silent_frame') ;
#	my $all_frames_ada_aref = frames_list($results_href, '') ;

	my $csv_frames_aref = new_csv_frames($results_href) ;

	Linux::DVB::DVBT::Advert::Mem::print_used(" + created ADA arrays") ;


#	if ($DEBUG)
#	{
##		dump_frames(\@size_frames, "All SIZE frames") if (@size_frames) ;
#		dump_frames(\@scene_frames, "All SCENE frames") if (@scene_frames) ;
#		dump_frames(\@black_frames, "All BLACK frames") if (@black_frames) ;
#		dump_frames(\@logo_frames, "All LOGO frames") if (@logo_frames) ;
#		dump_frames(\@silent_frames, "All SILENT frames") if (@silent_frames) ;
#		#dump_frames(\@banner_frames, "All BANNER frames") if (@banner_frames) ;
#		#dump_frames(\@audio_frames, "All AUDIO frames") if (@audio_frames) ;
#	}

	## Analysis results
	my @black_cut_list ;
	my @silent_cut_list ;
	my @logo_cut_list ;

	## Settings
	my $global_settings_href = Linux::DVB::DVBT::Advert::Config::cascade_settings($extra_settings_href, '', $results_settings_href) ;
	my $black_settings_href = Linux::DVB::DVBT::Advert::Config::cascade_settings($extra_settings_href, 'frame', $results_settings_href) ;
	my $logo_settings_href = Linux::DVB::DVBT::Advert::Config::cascade_settings($extra_settings_href, 'logo', $results_settings_href) ;
	my $silent_settings_href = Linux::DVB::DVBT::Advert::Config::cascade_settings($extra_settings_href, 'audio', $results_settings_href) ;

	# return cascaded settings
	$results_href->{'settings'} = {
		$global_settings_href,
		'frame' => $black_settings_href,
		'logo' => $logo_settings_href,
		'audio' => $silent_settings_href,
	} ;

	my $rise_thresh = $logo_settings_href->{'logo_rise_threshold'} || 1 ;
	my $fall_thresh = $logo_settings_href->{'logo_fall_threshold'} || 1 ;

	Linux::DVB::DVBT::Advert::Mem::print_used(" + got settings") ;


	## Skip if disabled
	if (!ok_to_detect($global_settings_href))
	{
		return @cut_list ;					
	}


	## Saved CSV file for post-detection analysis
	my @csv_settings ;
	csv_add_setting(\@csv_settings, "frame", "0::") ;
	csv_add_setting(\@csv_settings, $PACKET_FIELD, "0::") ;
	csv_add_setting(\@csv_settings, $PACKET_END_FIELD, "0::") ;
	csv_add_setting(\@csv_settings, $PACKET_GOP_FIELD, "0::") ;
	csv_add_setting(\@csv_settings, "black_frame", "0:1:1") ;
	csv_add_setting(\@csv_settings, "scene_frame", "0:1:1") ;
	csv_add_setting(\@csv_settings, "size_change", "0:1:1") ;
	csv_add_setting(\@csv_settings, "match_percent", "0:$rise_thresh:100") ;
	csv_add_setting(\@csv_settings, "ave_percent", "0:$rise_thresh/$fall_thresh:100") ;
	csv_add_setting(\@csv_settings, "volume_dB", "-96:-60:0") ;
	csv_add_setting(\@csv_settings, "silent_frame", "0:1:1") ;
	csv_add_setting(\@csv_settings, $PROG_FIELD, "0:1:100") ;
	
	if ($expected_aref)
	{
		csv_add_setting(\@csv_settings, $EXPECTED_FIELD, "0:1:1") ;
	}
	
	## Check that this channel doesn't splat logos across the adverts too!
	my $logo_frames_percent = (100.0 * $results_settings_href->{'total_logo_frames'}) / (1.0 * $results_settings_href->{'num_frames'}) ;
print "CUTS: Logo % = $logo_frames_percent\n" if $DEBUG ;

	if ($logo_frames_percent > 90.0)
	{
print "CUTS: Skipping ALL-LOGOS frames...\n" if $DEBUG ;
##TODO: fix....
		@$logo_frames_ada_aref = () ;
	}

	##--[ Black detect ]----------------------------------------------------
	Linux::DVB::DVBT::Advert::Mem::print_used("Black detect") ;
	my $new_black_frames_aref = [] ;
	if (@$black_frames_ada_ref)
	{
#print STDERR "black detect\n" ;
		## process
		@black_cut_list = process_black_frames($black_frames_ada_ref, $new_black_frames_aref,
								$total_pkts, $total_frames, $black_settings_href,
								$frames_adata_aref, $csv_frames_aref, \@csv_settings) ;
								
		$black_frames_ada_ref = undef ;
		
		## validate cuts
		validate_cutlist(\@black_cut_list, $black_settings_href) ;
								
		# default to using the black cut list
		@cut_list = @black_cut_list ;

print "BLACK CUTS: " . scalar(@black_cut_list) . "\n" if $DEBUG ;

#print STDERR "black detect - done\n" ;
	}	
	
	##--[ Logo detect ]----------------------------------------------------
	if (@$logo_frames_ada_aref)
	{
#print STDERR "logo detect\n" ;
		Linux::DVB::DVBT::Advert::Mem::print_used("Logo detect") ;

		my $scene_frames_ada_aref = frames_list($results_href, 'scene_frame') ;
		my $all_frames_ada_aref = frames_list($results_href, '') ;

		## process
		@logo_cut_list = process_logo_frames($all_frames_ada_aref, $new_black_frames_aref, $scene_frames_ada_aref, 
								$total_pkts, $total_frames, $logo_settings_href,
								$frames_adata_aref, $csv_frames_aref, \@csv_settings) ;

		$scene_frames_ada_aref = undef ;
		$all_frames_ada_aref = undef ;
		$logo_frames_ada_aref = undef ;

		## validate cuts
		validate_cutlist(\@logo_cut_list, $logo_settings_href) ;

print "LOGO CUTS: " . scalar(@logo_cut_list) . "\n" if $DEBUG ;
								
		# use this logo list
		if (@logo_cut_list >= @cut_list)
		{
			@cut_list = @logo_cut_list ;
		}
		else
		{
			@logo_cut_list = () ;
print " + Cleared LOGO CUTS\n" if $DEBUG ;
		}
#print STDERR "logo detect - done\n" ;
	}


	##--[ Silence detect ]----------------------------------------------------
	if (!@logo_cut_list && @$new_black_frames_aref && $silent_frames_ada_aref)
	{
#print STDERR "silence detect\n" ;
		Linux::DVB::DVBT::Advert::Mem::print_used("Silence detect") ;
		
		## process
		@silent_cut_list = process_silent_frames($new_black_frames_aref, $silent_frames_ada_aref,
								$total_pkts, $total_frames, $silent_settings_href,
								$frames_adata_aref, $csv_frames_aref, \@csv_settings) ;
								
		$silent_frames_ada_aref = undef ;

		## validate cuts
		validate_cutlist(\@silent_cut_list, $silent_settings_href) ;

print "SILENT CUTS: " . scalar(@silent_cut_list) . "\n" if $DEBUG ;
								
		# default to using the black cut list
		if (@silent_cut_list)
		{
			@cut_list = @silent_cut_list ;
		}
#print STDERR "silence detect - done\n" ;
	}

#print STDERR "Detect - end\n" ;
	
	##--[ Final ]----------------------------------------------------
	Linux::DVB::DVBT::Advert::Mem::print_used("Detect end") ;

	if ($DEBUG)
	{
#print STDERR "printing cut lists...\n" ;
		if (@black_cut_list)
		{
			dump_cutlist("BLACK CUT LIST", \@black_cut_list, "#") ;
		}
		if (@logo_cut_list)
		{
			dump_cutlist("LOGO CUT LIST", \@logo_cut_list, "#") ;
		}
		if (@silent_cut_list)
		{
			dump_cutlist("SILENT CUT LIST", \@silent_cut_list, "#") ;
		}
	
		dump_cutlist("FINAL CUT LIST", \@cut_list, "") ;
#print STDERR "done printing cut lists...\n" ;
	}
	
	## Save CSV info
	if ($csv)
	{
#print STDERR "write csv\n" ;
		Linux::DVB::DVBT::Advert::Mem::print_used("Writing CSV") ;
		
		## Add cut list as program boundaries
		csv_add_prog($results_href, $csv_frames_aref, $PROG_FIELD, \@cut_list) ;
		
		## write out csv
		write_csv($csv, $results_href, $csv_frames_aref, @csv_settings) ;

#print STDERR "write csv - done\n" ;
	}

	## Tidy up
	$results_href = undef ;

	Linux::DVB::DVBT::Advert::Mem::print_used("End of analyse") ;

#print STDERR "Analyse - done\n" ;

	## return results
	return @cut_list ;
}


#-----------------------------------------------------------------------------

=item B<ad_cut($src_file, $cut_file, $cut_list_aref)>

Cut the $src_file at the points specified in the ARRAY ref $cut_list_aref, writing the output
to $cut_file

=cut

sub ad_cut
{
	my ($src_file, $cut_file, $cut_list_aref) = @_ ;
	
	croak "Unable to read \"$src_file\"" unless -f $src_file ;
	croak "Zero-length file \"$src_file\"" unless -s $src_file ;
	croak "Must specify a destination filename" unless $cut_file ;

	# ensure dest directory exists
	my $dir = dirname($cut_file) ;
	if (! -d $dir)
	{
		# create dir
		mkpath([$dir], $DEBUG, 0755) or return "Unable to create directory $dir : $!" ;
	}
	
	# run cut
	my $rc = dvb_ad_cut($src_file, $cut_file, $cut_list_aref) ;
	
	return $rc ;
}

#-----------------------------------------------------------------------------

=item B<ad_split($src_file, $cut_file, $cut_list_aref)>

Split the $src_file at the points specified in the ARRAY ref $cut_list_aref, writing the output files
to $cut_file with suffix XXXX where XXXX is in incrementing count starting at 0001

=cut

sub ad_split
{
	my ($src_file, $cut_file, $cut_list_aref) = @_ ;
	
	croak "Unable to read \"$src_file\"" unless -f $src_file ;
	croak "Zero-length file \"$src_file\"" unless -s $src_file ;
	croak "Must specify a destination filename" unless $cut_file ;
	
	# ensure dest directory exists
	my $dir = dirname($cut_file) ;
	if (! -d $dir)
	{
		# create dir
		mkpath([$dir], $DEBUG, 0755) or return "Unable to create directory $dir : $!" ;
	}
	
	# run cut
	my $rc = dvb_ad_split($src_file, $cut_file, $cut_list_aref) ;
	
	return $rc ;
}


#-----------------------------------------------------------------------------

=item B<ok_to_detect($settings_href)>

Looks at the settings and returns TRUE if the settings are such that advert detection
will be preformed (i.e. detection_method is not 'disabled' or 0)

=cut

sub ok_to_detect
{
	my ($settings_href) = @_ ;
	
	my $ok = 0 ;
	if (exists($settings_href->{'detection_method'}) && $settings_href->{'detection_method'})
	{
		$ok = 1 ;
	}

	return $ok ;
}


#-----------------------------------------------------------------------------

=item B<write_default_config( [$force], [$search_path]  )>

Writes a default Advert config file. If the optional B<$force> parameter is set, then
writes a new file even if one already exists. Uses the optional search path to find
a writeable directory (other than the default search path).

=cut

sub write_default_config
{
	my ($force, $search_path) = @_ ;
	
	$search_path ||= $CONFIG_DIR ;
	$CONFIG_DIR = $search_path ;
	
	my $fname = Linux::DVB::DVBT::Advert::Config::write_filename($search_path) ;
	if ($fname)
	{
		## only write if it doesn't exist OR we're forced to overwrite
		if ($force || (!$force && ! -f $fname))
		{
			# get defaults used by C routines
			my $default_settings_href = Linux::DVB::DVBT::Advert::dvb_advert_def_settings() ;
			my %settings = (
				$Linux::DVB::DVBT::Advert::Config::ADVERT_GLOBAL_SECTION => $default_settings_href,
			) ;
			
			# write config
			Linux::DVB::DVBT::Advert::Config::write_default_dvb_adv(\%settings, $search_path) ;
		}
	}
}


#============================================================================================
# PRIVATE
#============================================================================================

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# FRAMES LISTS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#-----------------------------------------------------------------------------
# Split frame results out into arrays (containing the HASH refs stored in results) where the specified
# field flag is true. If flag_field is empty then return the list of all frames
#
# XS
#
sub frames_list
{
	my ($results_href, $flag_field) = @_ ;

	my @list_ada ;
	
	my $thing = tied @{$results_href->{'frames'}} ;

	tie @list_ada, 'Linux::DVB::DVBT::Advert', 'FILTER', 
		[$thing, $flag_field, 1] ;

	my $ada = tied @list_ada ;
	$ada->update_gaps() ;
	
	return \@list_ada ;	
}

#-----------------------------------------------------------------------------
# Pull out any entries where the specified field >= threshold
#
sub frames_matching
{
	my ($frames_adata_aref, $flag_field, $threshold) = @_ ;

	my @list ;

	my $thing = tied @$frames_adata_aref ;

	my @list_ada ;
	tie @list_ada, 'Linux::DVB::DVBT::Advert', 'FILTER', 
		[$thing, $flag_field, $threshold] ;

#dump_frames(\@list_ada, "frames_matching() - raw") ;

	my $ada = tied @list_ada ;
	$ada->update_gaps() ;

#dump_frames(\@list_ada, "frames_matching() - updated gap") ;

	# turn into a list of frame HASH entries
	@list = frames_array_to_hashlist(\@list_ada) ;	

#dump_frames(\@list, "frames_matching() - frames_array_to_hashlist") ;

	return \@list ;	
}




#---------------------------------------------------------------------------------
# Convert a list of all frames into a list of frame HASH entries
sub frames_array_to_hashlist
{
    my ($frames_aref) = @_ ;
    
    ## coalesce (also updates the gap settings)
    my @frames = coalesce_frames($frames_aref,
    	{
    		'frame_window'	=> 1,
    		'min_frames'	=> 1,
    	}
    ) ;
    
    return @frames ;
}



#---------------------------------------------------------------------------------
sub frames_subtract
{
	my ($src_frames_aref, $sub_frames_aref, $fuzziness) = @_ ;
	
	## add
	my @frames = frames_subtract_array($src_frames_aref, $sub_frames_aref, $fuzziness) ;
	
	## convert to list of frame hashs
	@frames = frames_array_to_hashlist(\@frames) ;
	
	return @frames
}

#---------------------------------------------------------------------------------
# Add frames list - return the array of all frames
sub frames_add_array
{
	my ($src_frames_aref, $add_frames_aref, $fuzziness) = @_ ;
	
	## get first entry from source to use to replicate into newly added entries
	my $new_href = $add_frames_aref->[0] ;
	
	## pre-process subtracting array
	my $first_frame = $add_frames_aref->[0]{'frame'} - $fuzziness ;
	my $last_frame = $add_frames_aref->[-1]{'frame_end'} + $fuzziness ;
	foreach my $href (@$add_frames_aref)
	{
		my $frame_start = $href->{'frame'} - $fuzziness ;
		my $frame_end = $href->{'frame_end'} + $fuzziness ;
	}

	## pre-process source array
	my @frames ;
	$first_frame = $add_frames_aref->[0]{'frame'} if $first_frame > $add_frames_aref->[0]{'frame'} ;
	$last_frame = $add_frames_aref->[-1]{'frame_end'} if $last_frame < $add_frames_aref->[-1]{'frame_end'} ;
	my %add_frames ;
	foreach my $href (@$add_frames_aref)
	{
		my $frame_start = $href->{'frame'} ;
		my $frame_end = $href->{'frame_end'} ;
		foreach my $fnum ($frame_start..$frame_end)
		{
			$add_frames{$fnum} = $href ;
		}
	}

	## Merge the two arrays
	foreach my $fnum ($first_frame..$last_frame)
	{
		if (exists($add_frames{$fnum}))
		{
			push @frames, $add_frames{$fnum} ;
		}	
		elsif (exists($add_frames{$fnum}))
		{
			push @frames, {
				%$new_href,
				%{$add_frames{$fnum}},
			} ;
		}
	}
	update_gap(\@frames) ;
	
	return @frames
}


	
#---------------------------------------------------------------------------------
# Subtract frames list - return the array of all frames
sub frames_subtract_array
{
	my ($src_frames_aref, $sub_frames_aref, $fuzziness) = @_ ;
	
	## Make subtracting frames "fuzzy"
	my %fuzzy_frames ;
	foreach my $href (@$sub_frames_aref)
	{
		my $frame_start = $href->{'frame'} - $fuzziness ;
		my $frame_end = $href->{'frame_end'} + $fuzziness ;
		$frame_start=0 if ($frame_start<0) ;
		foreach my $fnum ($frame_start..$frame_end)
		{
			$fuzzy_frames{$fnum} = $href ;
		}
	}

	## Remove source frames that do not coincide with subtracted
	my @frames ;
	foreach my $href (@$src_frames_aref)
	{
		my $framenum = $href->{'frame'} ;
		my $framenum_end = $href->{'frame_end'} ;

		my $ok = 0 ;		
		foreach my $fnum ($href->{'frame'}..$href->{'frame_end'})
		{
			if (exists($fuzzy_frames{$fnum}))
			{
				$ok=1 ;
			}	
		}
		if ($ok)
		{
			push @frames, $href ;
		}
	}

	update_gap(\@frames) ;

	return @frames
}

#---------------------------------------------------------------------------------
# Add frames list - return a list of frame HASH refs
sub frames_add
{
	my ($src_frames_aref, $add_frames_aref, $fuzziness) = @_ ;
	
	## add
	my @frames = frames_add_array($src_frames_aref, $add_frames_aref, $fuzziness) ;
	
	## convert to list of frame hashs
	@frames = frames_array_to_hashlist(\@frames) ;
	
	return @frames
}

#---------------------------------------------------------------------------------
# Reduce the program length of the specified frame HASH entry to the nearest gap start
# in the given list
#
# HASH entry:
#
#                                                  numframes=n
#              |----------------------------------------------->|
#              |
#               _...............................................
#              | |                                              :
#   ___________| |______________________________________________:____
#              ^                                                ^
#              frame=f                                          frame_end
#                         |<----------window--------------------:
#
# Closest entry in list:
#
#                            |<---min_gap--------->|
#
#                            |                     |              
#                            |<--------------------|
#                                          gap      _...........
#                            :                     | |          :
#   _________________________:_____________________| |__________:____
#                                                  ^            ^
#                                                  frame=f      frame_end
#
#
# HASH entry after reduction:
#
#                  numframes
#              |------------>|
#              |
#               _............
#              | |           :
#   ___________| |___________:_______________________________________
#              ^             ^
#              frame=f       frame_end
#
#
sub frames_reduce_end
{
	my ($frame_href, $frames_aref, $window, $min_gap) = @_ ;
	
	my $gap_href ;

if ($DEBUG) {print "frames_reduce_end(win=$window, gap=$min_gap) -START : "; dump_frame($frame_href) ;}	
	
	## Find any gaps that are within the specified window AND gap >= min_gap
	## (If window=0, allow any gaps)
	## $gap_href will be set to the PREVIOUS entry so that the 'frame_end' and 'end_pkt' 
	## values can be used
	##
	my $min_framenum = $frame_href->{'frame_end'} - $window ;
	my $max_framenum = $frame_href->{'frame_end'} ;
	$min_framenum = 0 if !$window ;
	my $prev_href = {'frame_end'=>0, 'end_pkt'=>0} ;
	foreach my $this_href (@$frames_aref)
	{
if ($DEBUG) {print " + evaluating gap : "; dump_frame($this_href) ;}
	
		## Stop at first valid match
		if (($this_href->{'frame'} >= $min_framenum) && ($this_href->{'frame'} >= $min_framenum) && ($this_href->{'gap'} >= $min_gap))
		{
			$gap_href = $prev_href ;
if ($DEBUG) {print " + + found gap : using "; dump_frame($gap_href) ;}
			last ;
		}
		$prev_href = $this_href ;
	}
	
	
	## Reduce end point to beginning of gap
	if ($gap_href)
	{
		$frame_href->{'frame_end'} = $gap_href->{'frame_end'} ;
		$frame_href->{'end_pkt'} = $gap_href->{'end_pkt'} ;
		
if ($DEBUG) {print " ++ Reduced "; dump_frame($frame_href) ;}		
	}
	
if ($DEBUG) {print "frames_reduce_end(win=$window, gap=$min_gap) -END : "; dump_frame($frame_href) ;}		
	
	return $frame_href
}

#---------------------------------------------------------------------------------
# !!!TBD!!!
#
# TODO: Work out what to do here!
#
# Reduce the program length of the specified frame HASH entry to the nearest gap start
# in the given list
#
# HASH entry:
#
#                                                  numframes=n
#              |----------------------------------------------->|
#              |
#               _...............................................
#              | |                                              :
#   ___________| |______________________________________________:____
#              ^                                                ^
#              frame=f                                          frame_end
#                         |<----------window--------------------:
#
# Closest entry in list:
#
#                            |<---min_gap--------->|
#
#                            |                     |              
#                            |<--------------------|
#                                          gap      _...........
#                            :                     | |          :
#   _________________________:_____________________| |__________:____
#                                                  ^            ^
#                                                  frame=f      frame_end
#
#
# HASH entry after reduction:
#
#                  numframes
#              |------------>|
#              |
#               _............
#              | |           :
#   ___________| |___________:_______________________________________
#              ^             ^
#              frame=f       frame_end
#
#
sub frames_increase_start
{
	my ($frame_href, $frames_aref, $window, $min_gap) = @_ ;
	
#	my $gap_href ;
#
#if ($DEBUG) {print "frames_reduce_end(win=$window, gap=$min_gap) -START : "; dump_frame($frame_href) ;}	
#	
#	## Find any gaps that are within the specified window AND gap >= min_gap
#	## (If window=0, allow any gaps)
#	## $gap_href will be set to the PREVIOUS entry so that the 'frame_end' and 'end_pkt' 
#	## values can be used
#	##
#	my $min_framenum = $frame_href->{'frame_end'} - $window ;
#	my $max_framenum = $frame_href->{'frame_end'} ;
#	$min_framenum = 0 if !$window ;
#	my $prev_href = {'frame_end'=>0, 'end_pkt'=>0} ;
#	foreach my $this_href (@$frames_aref)
#	{
#if ($DEBUG) {print " + evaluating gap : "; dump_frame($this_href) ;}
#	
#		## Stop at first valid match
#		if (($this_href->{'frame'} >= $min_framenum) && ($this_href->{'frame'} >= $min_framenum) && ($this_href->{'gap'} >= $min_gap))
#		{
#			$gap_href = $prev_href ;
#if ($DEBUG) {print " + + found gap : using "; dump_frame($gap_href) ;}
#			last ;
#		}
#		$prev_href = $this_href ;
#	}
#	
#	
#	## Reduce end point to beginning of gap
#	if ($gap_href)
#	{
#		$frame_href->{'frame_end'} = $gap_href->{'frame_end'} ;
#		$frame_href->{'end_pkt'} = $gap_href->{'end_pkt'} ;
#		
#if ($DEBUG) {print " ++ Reduced "; dump_frame($frame_href) ;}		
#	}
#	
#if ($DEBUG) {print "frames_reduce_end(win=$window, gap=$min_gap) -END : "; dump_frame($frame_href) ;}		
	
	return $frame_href
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# CSV
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#-----------------------------------------------------------------------------
#
sub new_csv_frames
{
	my ($results_href) = @_ ;

#print STDERR "new_csv_frames()\n";

	# Create
	my @list ;

	my $thing = tied @{$results_href->{'frames'}} ;

	tie @list, 'Linux::DVB::DVBT::Advert', 'ADV', [$thing] ;
	
	return \@list ;	
}


#---------------------------------------------------------------------------------
sub csv_add_setting
{
	my ($settings_aref, $key, $threshold) = @_ ;
	
	push @{$settings_aref->[0]}, $key ;
	push @{$settings_aref->[1]}, $threshold ;
}

#---------------------------------------------------------------------------------
sub csv_add_prog
{
	my ($results_href, $csv_frames_aref, $prog_field, $cutlist_aref) = @_ ;

print "csv_add_prog()\n" if $DEBUG;

	my @cuts = @$cutlist_aref ;
	my $cut_href = shift @cuts ;
	
	my $adv = tied @$csv_frames_aref ;
	$adv->add_key($prog_field) ;

	for(my $i=0; $i < scalar(@$csv_frames_aref); ++$i) 
	{
		#my $href = $csv_frames_aref->[$i] ;
		my $href = {} ;
		my $framenum = $csv_frames_aref->[$i]->{'frame'} ;

print " + frame $framenum : cut_href s=$cut_href->{'frame'} .. e=$cut_href->{'frame_end'}\n" if $DEBUG;

		$href->{$prog_field} = 100 ;
		my $done = 0 ;
		while ($cut_href && !$done)
		{
			if ($framenum < $cut_href->{'frame'})
			{
				$href->{$prog_field} = 100 ;
				++$done ;
			}
			elsif ( ($framenum >= $cut_href->{'frame'}) && ($framenum <= $cut_href->{'frame_end'}))
			{
				$href->{$prog_field} = 0 ;
				++$done ;
			}
			elsif ( ($framenum > $cut_href->{'frame_end'}))
			{
				# get next in the list
				if (@cuts)
				{
					$cut_href = shift @cuts ;
				}
				else
				{
					$href->{$prog_field} = 100 ;
					++$done ;
				}
			}
		}
		
		$csv_frames_aref->[$i] = $href ;
	}

print "csv_add_prog() - END\n" if $DEBUG;

}

#-----------------------------------------------------------------------------
sub csv_add_frames
{
	my ($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, $new_frames_aref, $field, $threshold, $new_field) = @_ ;

#print STDERR "csv_add_frames()\n";
	
	push @{$csv_settings_aref->[0]}, $field ;
	push @{$csv_settings_aref->[1]}, $threshold ;

	# start by clearing
	my $adv = tied @$csv_frames_aref ;
	$adv->add_key($field) ;

	# next add frames
	foreach my $buff_href (@$new_frames_aref)
	{
		my $fnum_start = $buff_href->{'frame'} ;
		my $fnum_end = $buff_href->{'frame_end'} || $fnum_start ;

		if ( defined($fnum_end) && ($fnum_end > $fnum_start))
		{
			foreach my $fnum ($fnum_start..$fnum_end)
			{
				$csv_frames_aref->[$fnum] = { $field => $buff_href->{$new_field} };
			}
		}
		else
		{
			$csv_frames_aref->[$fnum_start] = { $field => $buff_href->{$new_field} };
		}
	}

#print STDERR "csv_add_frames() - END\n";

}

#-----------------------------------------------------------------------------
# Write CSV
sub write_csv
{
    my ($fname, $results_href, $csv_frames_aref, $headings_aref, $levels_aref) = @_;

print "Writing CSV $fname ... \n" if $DEBUG ;

	open my $fh, ">$fname" or die "Unable to write CSV $fname : $!" ;
	print $fh "$headings_aref->[0]" ;
	for (my $i=1; $i < scalar(@$headings_aref); ++$i)
	{
		print $fh ",$headings_aref->[$i] [$levels_aref->[$i]]" ;
	}
	print $fh "\n" ;
	
	my $frames_adata_aref = $results_href->{'frames'} ;
	foreach my $frame_href (@$frames_adata_aref)
	{
		my $frame = $frame_href->{'frame'} ;
		my $href = $csv_frames_aref->[$frame] ;
		
		my $head = $headings_aref->[0] ;
		print $fh "$href->{$head}" ;
		for (my $i=1; $i < scalar(@$headings_aref); ++$i)
		{
			$head = $headings_aref->[$i] ;
			my $val = exists($href->{$head}) ? $href->{$head} : $frame_href->{$head} ;
			print $fh ",$val" ;
		}
		print $fh "\n" ;
	}
	
	close $fh ;
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# FRAME HASH
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Each frame HASH entry, along with specific information, stores the relationship with it's
# previous entry
#
#                                                  numframes=n
#                            |                     |----------->|
#                            |<--------------------|
#               _............              gap      _...........
#              | |           :                     | |          :
#   ___________| |___________:_____________________| |__________:____
#                                                  ^            ^
#                                                  frame=f      frame_end
#
#




#-----------------------------------------------------------------------------
# Set the gap counts - the distance each frame is from it's previous frame
#
#              numframes=n'                        numframes=n
#              |------------>|                     |----------->|
#                            |<--------------------|
#               _............              gap      _...........
#              | |           :                     | |          :
#   ___________| |___________:_____________________| |__________:____
#              ^             ^                     ^ 
#            frame=f'     frame_end=e'             frame=f
#
#
#              | f' ..... e' | e'+1  ......... f-1 |
#              |------------>|
#                 n'=e'-f'+1 |
#                            |<--------------------|
#                                gap = (f-1) - (e'+1) + 1
#
#
#
# For frame f:
#    
#    gap = f - e' - 1
#
sub calc_gap
{
	my ($frame, $prev_frame_end) = @_ ;

	return $frame - $prev_frame_end - 1 ;
}

#-----------------------------------------------------------------------------
#
sub update_gap
{
	my ($frames_aref) = @_ ;

	my $prev_frame_end = -1 ;
	foreach my $href (@$frames_aref)
	{
		my $frame = $href->{'frame'} ;
		$href->{'gap'} = calc_gap($frame, $prev_frame_end) ;

		$prev_frame_end = $href->{'frame_end'} ;
	}	
}


#-----------------------------------------------------------------------------
# Return the number of frames for this frame entry
#
#              numframes=n'                        numframes=n
#              |------------>|                     |----------->|
#               _............                       _...........
#              | |           :                     | |          :
#   ___________| |___________:_____________________| |__________:____
#            frame=f'     frame_end=e'             frame=f     frame_end=e
#
# For frame f:
#    
#    numframes: n = e - f + 1 
#

sub numframes
{
	my ($frame_href) = @_ ;
	
	return $frame_href->{frame_end} - $frame_href->{frame} + 1 ;
}

#-----------------------------------------------------------------------------
# Set the type based on section length
sub _prog_type
{
    my ($duration, $settings_href) = @_;
    
    # could be either
    my $type = "advert/prog" ;
    if ($duration <= $settings_href->{'max_advert'})
    {
    	$type = "advert" ;
print "_prog_type=$type : $duration <= $settings_href->{'max_advert'}\n" if $DEBUG >= 2 ;    	
    }
    elsif ($duration >= $settings_href->{'min_program'})
    {
    	$type = "program" ;
print "_prog_type=$type : $duration >= $settings_href->{'min_program'}\n" if $DEBUG >= 2 ;    	
    }
	return $type ;
}

#---------------------------------------------------------------------------------
# Ensure each cut is of a valid length
sub validate_cutlist
{
    my ($cutlist_aref, $settings_href) = @_ ;

print "validate_cutlist:\n" if $DEBUG ;

	## Throw away rubbish (e.g. at start of video when there is actually nothing to cut)
	my $prev_end = 0 ;
	my @list ;
	my $num_entries = scalar(@$cutlist_aref) ;
	for (my $i=0; $i < $num_entries; ++$i)
	{
		my $cut_href = shift @$cutlist_aref ;
		my $period = ($cut_href->{'frame_end'}-$cut_href->{'frame'}+1) ;
		if ($period > 0)
		{

			# see if gap (i.e. program) long enough
			my $ok=1 ;
			my $prog_period =($cut_href->{'frame'}-$prev_end+1) ;
if ($DEBUG) { print " + checking (prog=$prog_period min=$settings_href->{'min_program'}) : "; dump_frame($cut_href) ; }
			if ($prog_period < $settings_href->{'min_program'})
			{
print " !! Program period too small (prog=$prog_period min=$settings_href->{'min_program'})" if $DEBUG ;
				if (scalar(@list))
				{
if ($DEBUG) { print " , appending new to end of previous" ; dump_frame($list[-1]) ; }
					$ok=0 ;
					$list[-1]{'frame_end'} = $cut_href->{'frame_end'} ;		
					$list[-1]{'end_pkt'} = $cut_href->{'end_pkt'} ;		
				}
				else
				{
print ", setting start to 0\n" if $DEBUG ;
					# start of list, amend first frame
					$cut_href = { %$cut_href } ;
					$cut_href->{'frame'} = 0 ;
					$cut_href->{'start_pkt'} = 0 ;
					$cut_href->{'gap'} = 0 ;
				}
			}
			
			if ($ok)
			{
if ($DEBUG) { print " + + saved : " ;	dump_frame($cut_href) ;	}	
				push @list, $cut_href ;
				$prev_end = $cut_href->{'frame_end'} ;
			}
		}		
	}
	
	## Build new list
	$prev_end = 0 ;
	$num_entries = scalar(@list) ;
	for (my $i=0; $i < $num_entries; ++$i)
	{
		my $cut_href = $list[$i] ;

		if (defined($prev_end))
		{
			my $prog_period = ($cut_href->{'frame'}-$prev_end+1) ;
printf("(PROG $prev_end .. $cut_href->{'frame'} period=$prog_period (min=$settings_href->{'min_program'})") if $DEBUG ;
			if ($prog_period >= $settings_href->{'min_program'})
			{
print " - OK" if $DEBUG ;
			}
print " )\n" if $DEBUG ;

		}
		
		# don't check start/end
		my $period = ($cut_href->{'frame_end'}-$cut_href->{'frame'}+1) ;

printf("%2d: $cut_href->{'frame'}..$cut_href->{'frame_end'} period=$period (min=$settings_href->{'min_advert'})", $i) if $DEBUG ;
		if ( ($i==0) || ($period >= $settings_href->{'min_advert'}) || ($i==$num_entries-1) )
		{
			push @$cutlist_aref, $cut_href ;
print " - OK" if $DEBUG ;
		}
print "\n" if $DEBUG ;

		$prev_end = $cut_href->{'frame_end'} ;
	}
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ANALYSIS UTILS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#---------------------------------------------------------------------------------
#
sub coalesce_frames
{
    my ($frames_aref, $settings_href, $start_framenum, $title) = @_ ;
    
    $title ||= "" ;
print "coalesce_frames($title)\n" if $DEBUG ;

	$start_framenum ||= 0 ;
    
    my @frames ;
	my $curr_href ;
	for (my $idx=0; $idx < scalar(@$frames_aref); $idx++)
	{
if ($DEBUG >= 2) { print " -> frame "; dump_frame($frames_aref->[$idx]) ; }

		# start of new "block"
		if ($frames_aref->[$idx]{'gap'} > $settings_href->{'frame_window'})
		{
if ($DEBUG) { print "new block : "; dump_frame($curr_href) ; }

			## check existing
			
			#              curr   idx
			#     ||||     |||    |
			#              curr
			#         <----gap    idx
			#                 <---gap
			#
			# Can now check to see if previous block (the "current" HASH) is a spurious block
			# 
			if ($curr_href && 
			(numframes($curr_href) < $settings_href->{'min_frames'})  
			)
			{
if ($DEBUG) { print " - (curr gap = $frames_aref->[$idx]{'gap'}, curr numframes = $curr_href->{'numframes'}) removed spurious : "; dump_frame($curr_href) ; }

				# remove spurious
				pop @frames ;
			}

			# start new
			$curr_href = {
				'frame_start'	=> $frames_aref->[$idx]{'frame'},
				'frame_end'		=> $frames_aref->[$idx]{'frame'},
				%{$frames_aref->[$idx]},	
			} ;
			push @frames, $curr_href ;
			
			my $prev_frame_end = $start_framenum ;
			if (scalar(@frames) >= 2)
			{
				$prev_frame_end = $frames[-2]{'frame_end'} ;
if ($DEBUG) { print " - calc prev : "; dump_frame($frames[-2]) ; }
			}
			$curr_href->{'gap'} = calc_gap($curr_href->{'frame_start'}, $prev_frame_end ) ;
		}
		else
		{
			if (!$curr_href)
			{
				# start new
				$curr_href = {
					'frame_start'	=> $frames_aref->[$idx]{'frame'},
					'frame_end'		=> $frames_aref->[$idx]{'frame_end'},
					%{$frames_aref->[$idx]},	
				} ;
				push @frames, $curr_href ;
			}	
			else
			{
				# expand end time
				$curr_href->{'end_pkt'} = $frames_aref->[$idx]{'end_pkt'} ;
				$curr_href->{'frame_end'} = $frames_aref->[$idx]{'frame_end'} ;
			}		
		}		
	}

	if ($curr_href && (numframes($curr_href) < $settings_href->{'min_frames'})) 
	{
if ($DEBUG) { print " - removed spurious : "; dump_frame($curr_href) ; }
		# remove spurious
		pop @frames ;
	}

print "coalesce_frames($title) - DONE\n" if $DEBUG ;

	update_gap(\@frames) ;

	return @frames ;
}

#============================================================================================
# DEBUG
#============================================================================================

#-----------------------------------------------------------------------------
# format fps into time
sub fps_time
{
    my ($fps_duration) = @_;
    my $str ;

	my $fsecs = $fps_duration * 1.0 / $FPS ;
	my $secs = int($fps_duration / $FPS) ;
	my ($mins, $hours) ;
	
	if ($secs > 60)
	{
		if ($secs > 60*60)
		{
			$hours = int($secs / (60*60)) ;
			$secs -= $hours * 60*60 ;	
		}
		
		$mins = int($secs / (60)) ;
		$secs -= $mins * 60 ;	
	}
	
	if ($hours)
	{
		$str .= sprintf "%d hours ", $hours ;
	}
	if ($mins)
	{
		$str .= sprintf "%d mins ", $mins ;
	}
	$str .= sprintf "%d secs", $secs ;
	
	return $str ;
}


#-----------------------------------------------------------------------------
# format fps into time
sub fps_timestamp
{
    my ($fps_duration) = @_;
    my $str ;

	my $fsecs = $fps_duration * 1.0 / $FPS ;
	my $secs = int($fps_duration / $FPS) ;
	my ($mins, $hours, $msec) = (0, 0, 0);
	
	$msec = int($fsecs*1000 - $secs*1000) ;
	
	if ($secs > 60)
	{
		if ($secs > 60*60)
		{
			$hours = int($secs / (60*60)) ;
			$secs -= $hours * 60*60 ;	
		}
		
		$mins = int($secs / (60)) ;
		$secs -= $mins * 60 ;	
	}
	
	$str = sprintf "%0d:%02d:%02d.%03d", $hours, $mins, $secs, $msec ;
	
	return $str ;
}

#---------------------------------------------------------------------------------
#
sub dump_cutlist
{
    my ($title, $cutlist_aref, $prefix) = @_ ;

	print "\n\n# $title\n" ;
	foreach my $cut_href (@$cutlist_aref)
	{
		printf "${prefix}# frame=%d:%d  %s\n", $cut_href->{'frame'}, $cut_href->{'frame_end'}, fps_time($cut_href->{'frame_end'}-$cut_href->{'frame'}+1) ;
	}
	foreach my $cut_href (@$cutlist_aref)
	{
		printf "${prefix}p=%d:%d\n", $cut_href->{'start_pkt'}, $cut_href->{'end_pkt'} ;
	}
}




#-----------------------------------------------------------------------------
# Display this black frame entry
sub dump_frame
{
    my ($frame_href) = @_;

	printf("frame=%d [%s] gap=%d (%s) numframes=%d : ", 
		$frame_href->{'frame'},
		fps_timestamp($frame_href->{'frame'}),
		$frame_href->{'gap'},
		fps_time($frame_href->{'gap'}),
		numframes($frame_href),
		) ;
	if (exists($frame_href->{'match_percent'}))
	{
		printf "Qual=%d%% : ", $frame_href->{'match_percent'} ;
	}
	if (exists($frame_href->{'weight'}))
	{
		printf "Weight=%d%% : ", $frame_href->{'weight'} ;
	}
	if (exists($frame_href->{'ave_percent'}))
	{
		printf "Ave. Qual=%d%% : ", $frame_href->{'ave_percent'} ;
	}
	printf("%d .. %d", 
		$frame_href->{'start_pkt'}, $frame_href->{'end_pkt'},
		) ;
	
	if (exists($frame_href->{'type'}))
	{
		print " : Type=$frame_href->{'type'}" ;
	}
	
	if (exists($frame_href->{'adverts'}))
	{
		print " : Ads=$frame_href->{'adverts'}" ;
	}
	if (exists($frame_href->{'frame_start'}))
	{
		print " : Frames $frame_href->{'frame_start'} .. $frame_href->{'frame_end'} duration (" . 
			fps_time(numframes($frame_href))
			. ")" ;
	}
	print "\n" ;
}

#-----------------------------------------------------------------------------
# Show the current black frames list
sub dump_frames
{
    my ($frames_aref, $msg) = @_;

    my @edges ;
    my $edge_href ;

	print "\n----[ $msg (", scalar(@$frames_aref)," frames) ]------------------------------\n" ;
	foreach my $href (@$frames_aref)
	{
		while ( $edge_href && ($href->{'frame'} > $edge_href->{'frame'}) )
		{
			print "*** $edge_href->{'frame'} ** " . ($edge_href->{'type'} eq 'start_pkt' ? "vvvvvvvvvv" : "^^^^^^^^^^") . "******\n" ;
	    	$edge_href = shift @edges ;
		}

		print "---------\n" if ($href->{'gap'}>1);

		if ( $edge_href && ($href->{'frame'} == $edge_href->{'frame'}) && ($edge_href->{'type'} eq 'start_pkt'))
		{
			print "*** $edge_href->{'frame'} ** " . ($edge_href->{'type'} eq 'start_pkt' ? "vvvvvvvvvv" : "^^^^^^^^^^") . "******\n" ;
	    	$edge_href = shift @edges ;
		}
		print "???BAD??? " if ($href->{'gap'}<0);
		
		dump_frame($href) ;

		if ( $edge_href && ($href->{'frame'} == $edge_href->{'frame'}) && ($edge_href->{'type'} eq 'end_pkt'))
		{
			print "*** $edge_href->{'frame'} ** " . ($edge_href->{'type'} eq 'start_pkt' ? "vvvvvvvvvv" : "^^^^^^^^^^") . "******\n" ;
	    	$edge_href = shift @edges ;
		}
	}
	print "\n----------------------------------\n" ;
}

sub prt_frame
{
    my ($frames_aref, $framenum) = @_;

	print "$framenum : " ;
	foreach my $key (sort keys %{$frames_aref->[$framenum]})
	{
		print " $key=$frames_aref->[$framenum]{$key}" ;
	}
	print "\n" ;
}
sub prt_frames
{
    my ($frames_aref) = @_;

	foreach my $frame_href (@$frames_aref)
	{
		prt_frame($frames_aref, $frame_href->{'frame'}) ;
	}
}

#=================================================================================
# BLACK FRAMES
#=================================================================================

#---------------------------------------------------------------------------------
#
sub black_frame_cutlist
{
    my ($frames_aref, $total_pkts, $total_frames, $settings_href) = @_ ;
	my @cut_list  ;

print "--- black_frame_cutlist() ---\n" if $DEBUG ;

	#        : start :                        : end :
	#        : pad   :                        : pad :
	#   _________|||____________|||___________|||______
	#        :                                      :
	#

	#
	#   _____|||____________|||___________|||__________
	#        :                                      :
	#

	#
	#   __|||____________|||___________|||_____________
	#        :                                      :
	#

	my $curr_href=undef ;
	foreach my $href (@$frames_aref)
	{
		my $type = _prog_type($href->{'gap'}, $settings_href) ;

		if ($DEBUG)
		{
			print "Cutlist len = " . scalar(@cut_list)."\n" ;
			print "[$type] " ; dump_frame($href) ;
		}
		
		# start of new "block"
		if ($type eq 'program')
		{
print " + New prog\n" if $DEBUG ;

			# start new
			$curr_href = {
				'adverts'	=> 0,
				'type'		=> $type,
				%$href,	
			} ;
			push @cut_list, $curr_href ;

print " + new prog added\n" if $DEBUG ;
		}
		else
		{
			if (!$curr_href)
			{
				# start new
				$curr_href = {
					'adverts'	=> 0,
					'type'		=> $type,
					%$href,	
				} ;
				push @cut_list, $curr_href ;
print " + new advert\n" if $DEBUG ;
			}	
			else
			{
				# inc advert count
				$curr_href->{'adverts'}++ ;
				
				# expand end time
				$curr_href->{'end_pkt'} = $href->{'end_pkt'} ;
				$curr_href->{'frame_end'} = $href->{'frame_end'} ;
print " + extend\n" if $DEBUG ;
			}		
		}		
	}
	
	## process start and end
	if (@cut_list)
	{
		## start
		my $start_href = $cut_list[0] ;
		if ($start_href->{'type'} ne 'program')
		{
			$start_href->{'start_pkt'} = 0 ;
			$start_href->{'frame_start'} = 0 ;	# for debug
		}
		
		## end
		my $end_href = $cut_list[-1] ;
		my $end_gap = $total_frames - $end_href->{'frame_end'} - 1 ;
		my $end_type = _prog_type($end_gap, $settings_href) ;
		if ($end_type ne 'program')
		{
			$end_href->{'end_pkt'} = $total_pkts-1 ;
			$end_href->{'frame_end'} = $total_frames-1 ;	# for debug
		}
	}
	
	
	return @cut_list ;
}

#---------------------------------------------------------------------------------
#
sub process_black_frames
{
    my ($black_frames_ada_ref, $new_black_frames_aref, $total_pkts, $total_frames, $settings_href, $frames_adata_aref, $csv_frames_aref, $csv_settings_aref) = @_ ;

if ($DEBUG)
{
print "\n=================================================\n" ;
print "process_black_frames()\n" ;
print Data::Dumper->Dump(["Settings:", $settings_href]) ;
}

	## strip out any spurious frames
	
	# start by coalescing the contiguous black frames
	my @frames = coalesce_frames($black_frames_ada_ref, $settings_href, 0) ;

dump_frames(\@frames, "BLACK coalesced") if $DEBUG >= 2 ;

	csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, \@frames, 
		$BLACK_COALESCED_FIELD, "0:1:1", 'black_frame') ;

	## update input array with coalesced version
	my $num_black =  scalar(@$black_frames_ada_ref) ;
	foreach my $href (@frames)
	{
		push @$new_black_frames_aref, $href ;
	}

	## Create black frame cutlist
	my @cut_list = black_frame_cutlist(\@frames, $total_pkts, $total_frames, $settings_href) ;

dump_frames(\@cut_list, "Final BLACK Cut List") if $DEBUG >= 2 ;
	
	return @cut_list ;
}

#---------------------------------------------------------------------------------
#
sub process_silent_frames
{
    my ($black_frames_aref, $silent_frames_ada_aref, $total_pkts, $total_frames, $settings_href, $frames_adata_aref, $csv_frames_aref, $csv_settings_aref) = @_ ;

if ($DEBUG)
{
print "\n=================================================\n" ;
print "process_silent_frames()\n" ;
print Data::Dumper->Dump(["Settings:", $settings_href]) ;
}

	## strip out any spurious frames
	
	# start by coalescing the contiguous black frames
	my @silent_frames = coalesce_frames($silent_frames_ada_aref, $settings_href, 0) ;

	csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, \@silent_frames, 
		$SILENT_COALESCED_FIELD, "0:1:1", 'silent_frame') ;

#my $SILENCE_WINDOW = 100 ;

	## Remove black frames that do not coincide with silence (with silence "fuzzy")
	my @frames = frames_subtract($black_frames_aref, \@silent_frames, $settings_href->{'silence_window'}) ;

if ($DEBUG >= 2)
{
dump_frames(\@silent_frames, "SILENT") ;
dump_frames(\@frames, "SILENT BLACK") ;
}
	
	# Now have blocks of silence (in @silence_frames) along with spikes of black frames that are "silent".
	# Overlay the silent blocks with the black blocks, coalesce (again!) and we should have the answer
	my @combined_frames ;
	my %silent_frames = map { $_->{'frame'} => $_ } @silent_frames ;
	my %silent_black_frames = map { $_->{'frame'} => $_ } @frames ;
	my $last_framenum = $silent_frames[-1]{'frame'} ;
	$last_framenum = $frames[-1]{'frame'} if $last_framenum < $frames[-1]{'frame'} ;
print "Process frames 0..$last_framenum\n" if $DEBUG ;
	for (my $framenum=0; $framenum <= $last_framenum; ++$framenum)
	{
		my $href ;
		if (exists($silent_frames{$framenum}))
		{
			$href = $silent_frames{$framenum} ;
if ($DEBUG) {print " + silent @ $framenum : " ; dump_frame($href) ;}
		}
		elsif (exists($silent_black_frames{$framenum}))
		{
			$href = $silent_black_frames{$framenum} ;
if ($DEBUG) {print " + silent_black @ $framenum : " ; dump_frame($href) ;}
		}
		
		if ($href)
		{
			push @combined_frames, { %$href, 'black_frame'=>1 } ;
			$framenum = $href->{'frame_end'} ;
		}
	}
	update_gap(\@combined_frames) ;
	
	@combined_frames = coalesce_frames(\@combined_frames, $settings_href, 0) ;
dump_frames(\@combined_frames, "COMBINED COAL") if $DEBUG >= 2 ;

	csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, \@combined_frames, 
		$SILENT_BLACK_FIELD, "0:1:1", 'black_frame') ;

##NEW###################################################
#my $reduce_end = 15 * $FPS ;	# 15 sec window
#my $reduce_min_gap = 2 * $FPS ;	# need at least 2 sec gap

	if ($settings_href->{'reduce_end'})
	{
		## reduce the program end to the nearest silent region within
		## the window of the end
		foreach my $frame_href (@combined_frames)
		{
			frames_reduce_end($frame_href, \@silent_frames, $settings_href->{'reduce_end'}, $settings_href->{'reduce_min_gap'}) ;
		}		

		csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, \@combined_frames, 
			$REDUCED_SILENT_BLACK_FIELD, "0:1:1", 'black_frame') ;

	}


##NEW###################################################



	

	## Create black frame cutlist
	my @cut_list = black_frame_cutlist(\@combined_frames, $total_pkts, $total_frames, $settings_href) ;

dump_frames(\@cut_list, "Final SILENT Cut List") if $DEBUG >= 2 ;
	
	return @cut_list ;
}


#=================================================================================
# LOGO FRAMES
#=================================================================================

# TODO: Handle all start cases - record after start of prog (i.e. logo = 100%), record during adverts, record during end of previous
# TODO: Handle all end cases - record end before end of prog, record end during adverts, record end at start of next prog

#-----------------------------------------------------------------------------
# Given a frame number and a list of frames, find the frames from the list that 
# are immediately adjacent to this one.
#
sub bounding_frames
{
	my ($framenum, $frames_aref) = @_ ;

	my ($before, $after) ;
	foreach my $href (@$frames_aref)
	{
		my $frame_end = $href->{'frame_end'} ;
		if ($frame_end <= $framenum)
		{
			$before = $href->{'frame_end'} ;
		}
		elsif ($href->{'frame'} > $framenum)
		{
			$after = $href->{'frame'} ;
			last ;
		}
	}
	return ($before, $after) ;
}


#---------------------------------------------------------------------------------
sub logo_add_frames
{
	my ($msg_str, $frames_adata_aref, $logo_frames_aref, $start_frame, $end_frame, $settings_href, $edge_ref) = @_ ;
	
#	my @add_frames ;
	foreach my $fnum ($start_frame..$end_frame)
	{
			# save first edge
			if ($edge_ref)
			{
				$$edge_ref = $fnum unless defined($$edge_ref) ;
			}
			
			# spoof an entry that looks like a valid logo detection
			my $buff_href = { %{$frames_adata_aref->[$fnum]} } ;
			$buff_href->{'match_percent'} = $settings_href->{'logo_rise_threshold'} ;
			$buff_href->{'ave_percent'} = $settings_href->{'logo_rise_threshold'} ;
							
if ($DEBUG) {print " + + $msg_str extended by : " ; dump_frame($buff_href) ;}

#			push @add_frames, $buff_href ;
			push @$logo_frames_aref, $buff_href ;
	}
#	push @$logo_frames_aref, @add_frames ;

}

#---------------------------------------------------------------------------------
#
sub process_logo_frames
{
    my ($logo_all_frames_ada_aref, $black_frames_aref, $scene_frames_ada_aref, $total_pkts, $total_frames, $settings_href, 
    	$frames_adata_aref, $csv_frames_aref, $csv_settings_aref) = @_ ;
    	
	my @cut_list ;

if ($DEBUG)
{
print "\n=================================================\n" ;
print "process_logo_frames()\n" ;
print Data::Dumper->Dump(["Settings:", $settings_href]) ;
}

	my $logo_frames_adl_aref ;
	$logo_frames_adl_aref = [] ;
	
	my @lf ;
	my $thing = tied @$frames_adata_aref ;

	tie @lf, 'Linux::DVB::DVBT::Advert', 'LOGO', 
		[$thing] ;
		
	$logo_frames_adl_aref = \@lf ;
	
	my $adl = tied @$logo_frames_adl_aref ;
	

	## Threshold the frames based on average quality
	my $prev = 0 ;
	my $detect_mode = 'rise' ;
	foreach my $href (@$logo_all_frames_ada_aref)
	{
		my $framenum = $href->{'frame'} ;

if ($DEBUG)
{
		$adl->logo_frames_sanity($framenum) ;
}
		
		## threshold detection with hysteresis
		my $above = 0 ;
		if ($detect_mode eq 'rise')
		{
			# rising detect
			if ($href->{'ave_percent'} >= $settings_href->{'logo_rise_threshold'})
			{
				$above = 1 ;
				$detect_mode = 'fall' ;
			}
		}
		else
		{
			# falling detect
			$above = 1 ;
			if ($href->{'ave_percent'} < $settings_href->{'logo_fall_threshold'})
			{
				$above = 0 ;
				$detect_mode = 'rise' ;
			}
		}

		## use detected threshold
		if ($above)
		{
			if (!$prev)
			{
if ($DEBUG) {print " + rising edge : " ; dump_frame($href) ;}

				## rising edge - prefix by previous points to previous scene change

			
				# See if any scene changes are within (yet another) window of the new start edge
				#
				#   Scene Change:          |     |                     |              |
				#   Logo ave quality:                        ||||||||||||||||||||||||||||||
				#   Extended (scene):            ::::::::::::||||||||||||||||||||||||||||||...
				#
				my $start_framenum = $framenum ;
				
				## extend back while "raw" quality > threshold
				my $extend_start = $start_framenum - $settings_href->{'logo_ave_points'} ;
				$extend_start = 0 if ($extend_start < 0) ;
				for (my $fnum = $start_framenum-1; $fnum >= $extend_start; --$fnum)
				{
					if (($frames_adata_aref->[$fnum]{'match_percent'} >= $settings_href->{'logo_rise_threshold'}))
					{
						$start_framenum = $fnum ;
if ($DEBUG) {print " + + match extended by : " ; dump_frame($frames_adata_aref->[$fnum]) ;}
					}
					else
					{
						# stop
						last ;
					}
				}
				
				my $found_edge = 0 ;
				my $edge = undef ;

				# find any black frames around new start frame
print "rising black bounding..\n" if $DEBUG ;
				my ($black_before, $black_after) = bounding_frames($start_framenum, $black_frames_aref) ;

print " - black : rising frame $start_framenum, black before $black_before, black after $black_after\n" if $DEBUG ; 

				# find any scene changes around new start frame
print "rising scene bounding..\n" if $DEBUG ;
				my ($scene_before, $scene_after) = bounding_frames($start_framenum, $scene_frames_ada_aref) ;

print " - scene : rising frame $start_framenum, scene before $scene_before, scene after $scene_after\n" if $DEBUG ; 
				
				# if change occurs before the start frame AND it's not too far away, then extend to this point
				if (($black_before < $start_framenum) && ( ($start_framenum-$black_before) < $settings_href->{'logo_ave_points'}))
				{
					++$found_edge ;
					logo_add_frames("black", $frames_adata_aref, $logo_frames_adl_aref, $black_before, $framenum-1, $settings_href, \$edge) ;
				}
				
				
				# if scene change occurs before the start frame AND it's not too far away, then extend to this point
				if (!$found_edge && ($scene_before < $start_framenum) && ( ($start_framenum-$scene_before) < $settings_href->{'logo_ave_points'}))
				{
					++$found_edge ;
					logo_add_frames("scene", $frames_adata_aref, $logo_frames_adl_aref, $scene_before, $framenum-1, $settings_href, \$edge) ;
				}

print " - found? $found_edge : edge=$edge\n" if $DEBUG ; 

				## if this is the start of the video, see if we can extend to the start (use the lower threshold)
				if ($found_edge && ($edge) && ($edge <= $settings_href->{'logo_ave_points'}) )
				{
print " + + start extending...\n" if $DEBUG ;
					my $fnum = $edge-1 ;
					my $window_count = 0 ;
					while ( ($fnum >= 0) && ($window_count < $settings_href->{'frame_window'}) )
					{
						if ($frames_adata_aref->[$fnum]{'match_percent'} >= $settings_href->{'logo_fall_threshold'})
						{
							$window_count = 0 ;
						}
						else
						{
							++$window_count ;
						}
						--$fnum ;
					}

					# if we're nearly at the start, then just start at 0
					++$fnum ;
					$fnum = 0 if ($fnum <= $settings_href->{frame_window}) ;
					
					# add frames (skip any < threshold)
					my @start_frames ;
					while ($fnum < $edge)
					{
						if ($frames_adata_aref->[$fnum]{'match_percent'} >= $settings_href->{'logo_rise_threshold'})
						{
if ($DEBUG) {print " + + start-extended by : " ; dump_frame($frames_adata_aref->[$fnum]) ;}
#							push @start_frames, $frames_adata_aref->[$fnum] ;
							unshift @$logo_frames_adl_aref, $frames_adata_aref->[$fnum] ;
						}
						++$fnum ;
					}
					
					# insert these at the start
#					unshift @$logo_frames_adl_aref, @start_frames ;
				}

				## fall back on extending as much as possible
				if (!$found_edge)
				{
					# failed to use scene change - fall back on using raw quality

					## rising edge - prefix by previous points > threshold

					# calc where to start from (allow a window where quality can be < threshold)
					# (need to use frame buffer)
					my $end_index = $framenum-1 ;
					my $start_index = $end_index ;
					my $window_count = 0 ;
					while ( ($start_index > 0) && ($end_index-$start_index < $settings_href->{'logo_ave_points'}) && ($window_count < $settings_href->{'frame_window'}) )
					{
						if ($frames_adata_aref->[$start_index]{'match_percent'} >= $settings_href->{'logo_rise_threshold'})
						{
							$window_count = 0 ;
						}
						else
						{
							++$window_count ;
						}
						--$start_index ;
					}
					
if ($DEBUG) {print " + start..end : $start_index .. $end_index\n" ; }
					
					# add frames (skip any < threshold)
					++$start_index ;
					foreach my $buff_href (@$frames_adata_aref[$start_index..$end_index])
					{
						if ($buff_href->{'match_percent'} > $settings_href->{'logo_rise_threshold'})
						{
if ($DEBUG) {print " + + extended by : " ; dump_frame($buff_href) ;}
							push @$logo_frames_adl_aref, $buff_href ;
						}
					}
				}

				$adl->update_gaps() ;

dump_frames($logo_frames_adl_aref, "LOGO after extending due to rising edge") if $DEBUG >= 2;

			}
			
			## add this frame
			push @$logo_frames_adl_aref, $href ;

			$prev = 1 ;
		}
		else
		{
			if ($prev)
			{
if ($DEBUG) {print " + falling edge : " ; dump_frame($href) ;}

				$adl->update_gaps() ;

dump_frames($logo_frames_adl_aref, "LOGO before reducing due to falling edge") if $DEBUG >= 2;

				## trailing edge - remove any raw points < threshold
				# use logo array we're building

				# remove ALL frames for the length of the buffer, then start adding them back iff > threshold AND not too far away
				my $end_index = scalar(@$logo_frames_adl_aref)-1 ;
				my $start_index = $end_index-$settings_href->{'logo_ave_points'} ;
				$start_index = 0 if $start_index < 0 ;
				my $num_end_frames = $end_index - $start_index + 1 ;
if ($DEBUG) {print " + + reduced by $num_end_frames frames (start idx=$start_index, end idx=$end_index) to : " ; dump_frame($logo_frames_adl_aref->[$start_index]) ;}
				
				splice @$logo_frames_adl_aref, $start_index ;
				
				## check we have some points left?
				if (scalar(@$logo_frames_adl_aref))
				{

					# create a list of these removed frames that are > threshold
					my @end_frames = () ;
	print STDERR "logo_frames_adl_aref size = ",scalar(@$logo_frames_adl_aref),"\n"	 if $DEBUG >= 2;			
	print STDERR "About to read from logo_frames_adl_aref[-1] ...\n"  if $DEBUG >= 2;			
					my $new_framenum = $logo_frames_adl_aref->[-1]{'frame'}+1 ;
					foreach (1..$num_end_frames)
					{
						if ($frames_adata_aref->[$new_framenum]{'match_percent'} >= $settings_href->{'logo_rise_threshold'})
						{
	if ($DEBUG) {print " >> end_frames + $new_framenum " ; dump_frame($frames_adata_aref->[$new_framenum]) ;}
							push @end_frames, $frames_adata_aref->[$new_framenum] ;
						}
						++$new_framenum ;
					}
	
					# coalesce valid frames together
					update_gap(\@end_frames) ;
					@end_frames = coalesce_frames(\@end_frames, $settings_href, $logo_frames_adl_aref->[-1]{'frame'}, "logo end frames") ;
	
	dump_frames(\@end_frames, "coalesced end logo frames") if $DEBUG >= 2;
					
					# Just use the first block - the end *should* be the real end of the program
					if (@end_frames)
					{
						my $f_href = $end_frames[0] ;
						foreach my $new_framenum ($f_href->{'frame'}..$f_href->{'frame_end'})
						{
							push @$logo_frames_adl_aref, $frames_adata_aref->[$new_framenum] ;
	if ($DEBUG) {print " + + re-extend by : " ; dump_frame($frames_adata_aref->[$new_framenum]) ;}
						}
					}
					
					@end_frames = () ;
	
					$adl->update_gaps() ;
					
	dump_frames($logo_frames_adl_aref, "LOGO after reducing") if $DEBUG >= 2 ;
	
					
					## see if we can expand out to a scene change
					my $end_framenum = $logo_frames_adl_aref->[-1]{'frame'} ;
	print " end frame=$end_framenum\n" if $DEBUG ; 
	
					# find any black frames around new end frame
	print "falling black bounding..\n" if $DEBUG ;
					my ($black_before, $black_after) = bounding_frames($end_framenum, $black_frames_aref) ;
	
	print " - black : falling frame $end_framenum, black before $black_before, black after $black_after\n" if $DEBUG ; 
	
					# find any scene changes around new end frame
	print "falling scene bounding..\n" if $DEBUG ;
					my ($scene_before, $scene_after) = bounding_frames($end_framenum, $scene_frames_ada_aref) ;
	
	print " - scene : falling frame $end_framenum, scene before $scene_before, scene after $scene_after\n" if $DEBUG ; 
	
					my $found_edge = 0 ;
	
					# if black frame occurs after the end frame AND it's not too far away, then extend to this point
					if (($black_after > $end_framenum) && ( ($black_after-$end_framenum) < $settings_href->{'logo_ave_points'}))
					{
						++$found_edge ;
						logo_add_frames("black", $frames_adata_aref, $logo_frames_adl_aref, $end_framenum+1, $black_after, $settings_href) ;
					}
	
					# if scene change occurs after the end frame AND it's not too far away, then extend to this point
					if (!$found_edge && ($scene_after > $end_framenum) && ( ($scene_after-$end_framenum) < $settings_href->{'logo_ave_points'}))
					{
						++$found_edge ;
						logo_add_frames("scene", $frames_adata_aref, $logo_frames_adl_aref, $end_framenum+1, $scene_after, $settings_href) ;
					}
	
	if (!$found_edge && $DEBUG)
	{
		print "Bugger - failed to find edge!\n" ;
	}
	
					$adl->update_gaps() ;
					
	dump_frames($logo_frames_adl_aref, "LOGO after re-extending") if $DEBUG >= 2 ;

				} # if got some logo frames left after splice?
			}

			$prev = 0 ;
		}
	}
	
	
	## update gap's
	$adl->update_gaps() ;

	
	## Add processed information
	my $rise_thresh = $settings_href->{'logo_rise_threshold'} || 1 ;
	my $fall_thresh = $settings_href->{'logo_fall_threshold'} || 1 ;

dump_frames($logo_frames_adl_aref, "LOGO processed") if $DEBUG >= 2 ;

	csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, $logo_frames_adl_aref, 
		$LOGO_PROCESSED_FIELD, "0:$rise_thresh/$fall_thresh:100", 'match_percent') ;
	
	## start by coalescing the contiguous frames
	my @frames = coalesce_frames($logo_frames_adl_aref, $settings_href, 0, "logo frames") ;
	
dump_frames(\@frames, "LOGO coalesced") if $DEBUG >= 2 ;

	csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, \@frames, 
		$LOGO_COALESCED_FIELD, "0:$rise_thresh/$fall_thresh:100", 'match_percent') ;
		
		
##NEW###################################################
#my $reduce_end = 15 * $FPS ;	# 15 sec window
#my $reduce_min_gap = 2 * $FPS ;	# need at least 2 sec gap

	## calc logo match frames - used for frame end reduction
	my $logo_match_frames_aref = frames_matching($logo_all_frames_ada_aref, 'match_percent', $settings_href->{'logo_rise_threshold'});
	csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, $logo_match_frames_aref, 
		'logo_match', "0:$rise_thresh/$rise_thresh:100", 'match_percent') ;


#dump_frames($logo_match_frames_aref, "LOGO match frames") ;
	
	## process end reduction
	if ($settings_href->{'reduce_end'})
	{
		## reduce the program end to the nearest silent region within
		## the window of the end
		foreach my $frame_href (@frames)
		{
			frames_reduce_end($frame_href, $logo_match_frames_aref, $settings_href->{'reduce_end'}, $settings_href->{'reduce_min_gap'}) ;
		}		

		csv_add_frames($csv_settings_aref, $frames_adata_aref, $csv_frames_aref, \@frames, 
			$REDUCED_LOGO_COALESCED_FIELD, "0:$rise_thresh/$fall_thresh:100", 'match_percent') ;

	}


##NEW###################################################



	## Now glue together blocks 
	my @blocks ;
	my $curr_href=undef ;
	foreach my $href (@frames)
	{
		printf("frame=%d gap=%d (%8.3f) numframes=%d : %d .. %d\n", 
			$href->{'frame'},
			$href->{'gap'},
			$href->{'gap'}*1.0 / $FPS,
			numframes($href),
			$href->{'start_pkt'}, $href->{'end_pkt'},
			) if $DEBUG ;

		# start of new "block"
		if ($href->{'gap'} >= $settings_href->{'max_gap'})
		{
print " + New\n" if $DEBUG ;
			# start new
			$curr_href = {
				%$href,	
			} ;
			push @blocks, $curr_href ;
		}
		else
		{
print " - extend : new numframes=",numframes($href),", new gap=$href->{'gap'}\n" if $DEBUG ;
			if (!$curr_href)
			{
print " - + extend NEW\n" if $DEBUG ;
				# start new
				$curr_href = {
					%$href,	
				} ;
				push @blocks, $curr_href ;
			}	
			else
			{
print " - + extend curr numframes=",numframes($href),"\n" if $DEBUG ;
				# expand end time
				###$curr_href->{'numframes'} += $href->{'numframes'} ;
				$curr_href->{'end_pkt'} = $href->{'end_pkt'} ;
				$curr_href->{'frame_end'} = $href->{'frame_end'} ;
			}		
		}		
	}
dump_frames(\@blocks, "Logo Blocks") if $DEBUG ;
	

	## Create cut list
	if (@blocks)
	{
		my $cut_href = {'start_pkt'=>0, 'frame'=>0} ;
		push @cut_list, $cut_href ;
		foreach my $href (@blocks)
		{
			$cut_href->{'end_pkt'} = $href->{'start_pkt'}-1 ;
			$cut_href->{'frame_end'} = $href->{'frame'}-1 ;
			
			$cut_href = {
				'start_pkt'	=>	$href->{'end_pkt'}+1,
				'frame'	=>	$href->{'frame_end'}+1,
			} ;
			push @cut_list, $cut_href ;
		}
		$cut_href->{'end_pkt'} = $total_pkts-1 ;
		$cut_href->{'frame_end'} = $total_frames-1 ;
		
		# check last (first?) entry has a valid length
		if ($cut_href->{'frame'} >= $cut_href->{'frame_end'})
		{
			pop @cut_list ;
		}
		
	}
	
	return @cut_list ;
}


#-----------------------------------------------------------------------------
sub _no_once_warning
{
	return \%Linux::DVB::DVBT::Advert::Constants::CONSTANTS ;
}


#-----------------------------------------------------------------------------
sub read_adv
{
	my ($advfile) = @_ ;	
	
	my %adv ;
	open my $fh, "<$advfile" or die "Error: unable to read to adv file $advfile : $!" ;
	my $line = "" ;
	my @head ;
	my $file_settings_href = {} ;
		
	while (defined($line=<$fh>))
	{
		chomp $line ;
		$line =~ s/#.*$// ;
		$line =~ s/\s+$// ;
		$line =~ s/^\s+// ;
		next unless $line ;
		
		my @fields = split(/,/, $line) ;
		
		## Save frames
		# first line is fields definition
		if (@head)
		{
			# got head, so save data
			my $href = {} ;
			my $framenum ;
			for(my $i=0; $i < scalar(@head); ++$i)
			{
				$href->{$head[$i]} = $fields[$i] ;
										
				$framenum = $fields[$i] if $head[$i] eq $FRAME_FIELD ;
					
			}
			$adv{$framenum} = $href if defined($framenum) ;
		}
		else
		{
			# get head
			@head = @fields ;
			
			foreach my $head (@head)
			{
				$head =~ s/\s*\[.*$// ;
			}
		}
	}
	close $fh ;

	return \%adv ;
}


#-----------------------------------------------------------------------------
sub adv_to_cutlist
{
	my ($adv_href) = @_ ;	
	
	my @cutlist ;
	my $prog ;
	my $cut_href ;
	foreach my $framenum (sort {$a <=> $b} keys %$adv_href)
	{
		#			          ____________
		#	prog	_________|            |_______________
		#			
		#	cut     s--------e            s---------------e
		#	
		#			____________
		#	prog	            |_______________
		#			
		#	cut                 s---------------e
		#	
		my $prog_change = !defined($prog) || ($prog != $adv_href->{$framenum}{$PROG_FIELD}) ;
		$prog = $adv_href->{$framenum}{$PROG_FIELD} ;
		
		# look for start of advert 
		if (!$prog && $prog_change )
		{
			$cut_href = {
				$FRAME_FIELD		=> $adv_href->{$framenum}{$FRAME_FIELD},
				$FRAME_END_FIELD	=> $adv_href->{$framenum}{$FRAME_FIELD},
				$PACKET_FIELD		=> $adv_href->{$framenum}{$PACKET_FIELD},
				$PACKET_END_FIELD	=> $adv_href->{$framenum}{$PACKET_END_FIELD},
			} ;
		}
		
		# keep track of end of advert
		if (!$prog)
		{
			$cut_href->{$FRAME_END_FIELD} = $adv_href->{$framenum}{$FRAME_FIELD} ;
			$cut_href->{$PACKET_END_FIELD} = $adv_href->{$framenum}{$PACKET_END_FIELD} ;
		}
		
		# look for end
		if ($prog && $prog_change )
		{
			if ($cut_href)
			{
				push @cutlist, $cut_href ;
				$cut_href = undef ;
			}
		}
	}

	# catch end of video
	if ($cut_href)
	{
		push @cutlist, $cut_href ;
	}

	return @cutlist ;
}

# ============================================================================================
# END OF PACKAGE

1;

#Start of analyse: Memory used 50.6484375 MB (since last call 50.6484375 MB)
# + created ADA arrays: Memory used 179.1953125 MB (since last call 128.546875 MB)
# + got settings: Memory used 179.19921875 MB (since last call 0.00390625 MB)
#Black detect: Memory used 179.19921875 MB (since last call 0 MB)
#Logo detect: Memory used 189.3984375 MB (since last call 10.19921875 MB)
#Detect end: Memory used 940.23046875 MB (since last call 750.83203125 MB)
#End of analyse: Memory used 1313.71484375 MB (since last call 373.484375 MB)

__END__

=back

=head1 ACKNOWLEDGEMENTS

=head2 libmpeg2

This module uses libmpeg2 for MPEG2 video decoding:

 * Copyright (C) 2000-2003 Michel Lespinasse <walken@zoy.org>
 * Copyright (C) 1999-2000 Aaron Holtzman <aholtzma@ess.engr.uvic.ca>
 *
 * See http://libmpeg2.sourceforge.net/ for updates.
 *
 * libmpeg2 is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * libmpeg2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head2 mpegaudiodec

This module uses mpegaudiodec for AAC audio decoding:

 * MPEG Audio decoder
 * Copyright (c) 2001, 2002 Fabrice Bellard.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head2 Comskip

 Copyright (C) 2004 Scott Michael
 
Thanks to Erik Kaashoek for answering a few of my inane questions, and thanks to Comskip
for providing the inspiration for the detection algorithms.


=head1 AUTHOR

Steve Price

Please report bugs using L<http://rt.cpan.org>.

=head1 BUGS

One "problem" is when trying to run this code under Cygwin. With large videos, the combination
of Perl's excessive memory allocation and cygwin's draconian heap size allocation results in running
out of memory. This can be alleviated by increasing cygwin's heap size, but a re-write of my code
to use XS for all the large data structures would fix it (but make the analysis section more dependent
on calling XS, rather than being pure Perl)

=head1 FUTURE

Subsequent releases will include:

=over 4

=item *

Re-write of analysis section to make it use simpler, generic routines so that it is easier for me (and you) to
glue sequences of operations together

=item *

Re-write to provide XS memory handling routines

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Steve Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
