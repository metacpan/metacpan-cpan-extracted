package Linux::DVB::DVBT::Advert::Config ;

=head1 NAME

Linux::DVB::DVBT::Advert::Config - Advert detection config file

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Advert::Config ;
  

=head1 DESCRIPTION

This module provides the configuration file utilities for the advert detection and removal utilities.

=head2 Settings

Settings are passed into the routines via a HASH ref. Settings also come from the default set, and
from any config file parameters. The order of priority for these settings is:

=over 4

Default settings I<LOWEST priority>

Config file (Generic section) 

Config file (Channel-specific section)

Settings used for detection

Settings HASH ref  I<HIGHEST priority>

=back

Note that the "settings used for detection" only apply if the results from detection are saved in a file,
and then this file is read in for analysis (see L</Results Files>) 

Settings are split between those that control the detection phase, and those that control the 
analysis phase:

=head3 Detection Settings

Most of the detection settings (other than detection_method) can safely be left to their default values.


=over 4

=item B<detection_method>

Normally leave this set to the default (all methods used). Sometimes you may want to disable all advert detection (for non-commercial
channels), or possibly disable logo detection for channels that display a logo at all times.

This variable is actually a bitmap of flags: setting a bit enables the corresponding method. If you know what you want, you can specify 
the variable as a decimal or hex value. It's recommended, however, to use the following symbols:

=over 4

=item I<disable>

Use this symbol on it's own to disable advert detection

=item I<default>

Use this symbol to specify the built-in default detection method (usually means use all methods)

=item I<black>

Black frame detection. This is where "black" (or dark) frames are expected to appear before and after advert
breaks.

=item I<logo>

Logo detection. This is where the channel logo is expected to be present during programs, but absent during adverts.

=item I<audio>

Silence (audio volume) detection. Quiet (or silent) periods are expected before and after adverts.

=back

The symbols above can be combined to specify the complete detection method. Use '+' or '-' before the
symbol to enable or disable the method respectively. Using a '+' or '-' before the first symbol specified,
results in the symbols being added/subtracted from the default set. Otherwise the set specified are used
to fully define the methods to use.

Example: "detection_method = logo + black" means to use only black frame and logo detection.

Example: "detection_method = -logo" means to use default detection methods but disable logo detection.

Example: "detection_method = disable" means to disable advert detection.


=item B<frame.schange_jump>

Black frame detection: sets the threshold for the step difference of scene score between frames for a scene change
to be detected.

=item B<frame.schange_cutlevel>

Black frame detection: scene change detection percentage above which is deemed a scene change frame

=item B<frame.max_black>

Black frame detection: maximum pixel value for the pixel to be determined as "black"

=item B<frame.max_brightness>

Black frame detection: maximum brightness percentage under which is treated as black

=item B<frame.brightness_jump>

Black frame detection: step difference of the brightness score between frames used to detect a black frame

=item B<frame.window_percent>

Black frame detection: percentage of frame to use for black frame detection (for example, setting this to 90% results
in 5% of the edges around the frame to be ignored)

=item B<frame.test_brightness>

Black frame detection: pixel value used for brightness detection

=item B<frame.noise_level>

Black frame detection: noise level used for black frame uniformity detection



=item B<logo.logo_edge_step>

Logo detection: Step size used for moving between pixels in all logo detection functions. For example, setting this to 2 skips
every other pixel, resulting in halving the amount of dtaa to process.

=item B<logo.logo_max_percentage_of_screen>

Logo detection: Once a logo has been possibly detected, this is a check to ensure that the area of the screen used by the logo
is no greater than this value. Otherwise the detected region cannot be a valid logo and is discarded.

=item B<logo.logo_window>

Logo detection: Number of image frames stored in a rolling detection buffer. The number of frames skipped between each stored frame is set by L</logo.logo_skip_frames>

=item B<logo.logo_skip_frames>

Logo detection: Number of frames to skip between used frames. This creates a bigger discrepancy between images and makes the logo
area easier to detect.

=item B<logo.logo_edge_threshold>

Logo detection: level used to decided whether this is a logo edge

=item B<logo.logo_ave_points>

Logo detection: The logo detection score is averaged over this number of frames. 

=item B<logo.logo_checking_period>

Logo detection: maximum period (in frames) to use for detecting a logo. If a logo has not been found when we reach this number of frames
from the start of the video, then logo detection is cancelled.

=item B<logo.window_percent>

Logo detection: perecntage of total frame to use for logo detection

=item B<logo.logo_num_checks>

Logo detection: number of times a logo result is re-checked. Once a logo area is detected, the process is re-started this many times
to ensure we don't have a false detection. 

=item B<logo.logo_ok_percent>

Logo detection: the logo detection score % must be above this value before a frame is flagged as containing a logo.

=item B<logo.logo_edge_radius>

Logo detection: number of pixels to use in logo edge detection


=item B<audio.silence_window>

Silence detection: adds "fuzziness" to detection of silence frames

=back


=head3 Analysis Settings

The analysis settings consist of a global set of settings that are used in all cases. Also, each detection mode (black frame, logo etc)
has it's own set of settings that may be set to over-ride the global set. In the same manner as the detection settings, each set if prefixed 
by it's own namespace (e.g. for black frame detection use 'frame.' etc).

=over 4

=item B<max_advert>

The maximum length of a single advert (in frames). Multiple adverts may be joined to form the total advert/commercial break between 
program sections.

=item B<min_advert>

The minimum length of a single advert (in frames). 

=item B<min_program>

The minimum length (in frames) of a section of program.

=item B<start_pad>

(UNUSED) Expected amount of padding (in frames) before the start of a program recording.

=item B<end_pad>

(UNUSED) Expected amount of padding (in frames) at the start of a program recording.

=item B<min_frames>

Minimum number of frames to be contracted into a block. 

=item B<frame_window>

fuzziness window when contracting frames into a block 

=item B<max_gap>

widest gap (no valid frames) over which to span when contracting frames into a block 

=item B<reduce_end>

window (in frames) in which to reduce the end of the program to the nearest gap 

=item B<reduce_min_gap>

frame gap used for reducing program end point 


=back

Black frame settings (see above to descriptions):

=over 4

=item B<frame.max_advert>

=item B<frame.min_advert>

=item B<frame.min_program>

=item B<frame.start_pad>

=item B<frame.end_pad>

=item B<frame.min_frames>

=item B<frame.frame_window>

=item B<frame.max_gap>

=item B<frame.reduce_end>

=item B<frame.reduce_min_gap>

=item B<frame.increase_start>

=item B<frame.increase_min_gap>

=back

Logo frame settings (see above to descriptions):

=over 4

=item B<logo.max_advert>

=item B<logo.min_advert>

=item B<logo.min_program>

=item B<logo.start_pad>

=item B<logo.end_pad>

=item B<logo.min_frames>

=item B<logo.frame_window>

=item B<logo.max_gap>

=item B<logo.reduce_end>

=item B<logo.reduce_min_gap>

=item B<logo.increase_start>

=item B<logo.increase_min_gap>

=item B<logo.logo_rise_threshold>

=item B<logo.logo_fall_threshold>

=back

Silence frame settings (see above to descriptions):

=over 4

=item B<audio.max_advert>

=item B<audio.min_advert>

=item B<audio.min_program>

=item B<audio.start_pad>

=item B<audio.end_pad>

=item B<audio.min_frames>

=item B<audio.frame_window>

=item B<audio.max_gap>

=item B<audio.reduce_end>

=item B<audio.reduce_min_gap>

=item B<audio.increase_start>

=item B<audio.increase_min_gap>

=back

=head2 Config File

The configuration file is of the form:

    # global settings
	detection_method = 15
	frame.max_black = 48
	frame.window_percent = 95
	frame.max_brightness = 60
	frame.test_brightness = 40
	frame.brightness_jump = 200
	frame.schange_cutlevel = 85
	frame.schange_jump = 30
	frame.noise_level = 5
	logo.window_percent = 95
	logo.logo_window = 50
	logo.logo_edge_radius = 2
	logo.logo_edge_step = 1
	logo.logo_edge_threshold = 5
	logo.logo_checking_period = 30000
	logo.logo_skip_frames = 25
	logo.logo_num_checks = 5
	logo.logo_ok_percent = 80
	logo.logo_max_percentage_of_screen = 10
	logo.logo_ave_points = 250
	audio.scale = 1
	audio.silence_threshold = -80

	# Channel-specific settings
	[Dave]
	logo.logo_skip_frames = 30
	logo.logo_num_checks = 2
	logo.logo_ok_percent = 85


=head2 Config File Search Path

Some of the functions (for example L</read_dvb_adv( [$search_path] )>) accept an optional search path. If this is specified then the same
search path will be used from that point on (until a different search path is specified).

By default, the search path is set to attempt to match with L<Linux::DVB::DVBT> on those platforms that support that path; otherwise
the user's home directory is used.

Setting the search path allows the module to attempt to read/write the configuration file from multiple directories. This allows there to
be a common global file used by all users, but each user may then create their own configuration file to over ride the global one however
they choose.

The format for the search path is an ARRAY ref list of directories, for example:

	[ '/etc/dvb', '~/.tv' ]
	
or

	[ 'c:\tv', 'd:\profiles\user\tv' ]


=cut


use strict ;
use Carp ;

use File::Spec ;
use Data::Dumper ;

use Linux::DVB::DVBT::Advert::Constants ;

our $VERSION = '1.03' ;
our $DEBUG = 0 ;

our $DEFAULT_CONFIG_PATH ;
our $FILENAME = 'dvb-adv' ;

my %NUMERALS = (
	'one'	=> 1,
	'two'	=> 2,
	'three'	=> 3,
	'four'	=> 4,
	'five'	=> 5,
	'six'	=> 6,
	'seven'	=> 7,
	'eight'	=> 8,
	'nine'	=> 9,
) ;


#============================================================================================
our $ADVERT_GLOBAL_SECTION = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA__GLOBAL__" ;
our $METHOD_VAR = "detection_method" ;
our $METHOD_DISABLE = "disable" ;
our $METHOD_DISABLE_REGEXP = "none|$METHOD_DISABLE" ;

my %SETTINGS_COMMENTS = (
	
	'max_advert'	=> 'maximum length of a single advert (in frames)',
	'min_advert'	=> 'minimum length of advert period (cut period) excludes prog change (in frames)',
	'min_program'	=> 'minimum length of a program (in frames)',
	'start_pad'		=> 'padding at start of recording (in frames)',
	'end_pad'		=> 'padding at end of recording (in frames)',
	'min_frames' 	=> 'minimum number of frames to be contracted into a block',
	'frame_window' 	=> 'fuzziness window when contracting frames into a block',
	'max_gap' 		=> 'widest gap (no valid frames) over which to span when contracting frames into a block',
	'reduce_end'	=> 'window (in frames) in which to reduce the end of the program to the nearest gap',
	'reduce_min_gap'	=> 'frame gap used for reducing program end point',
	'detection_method' => 'advert detection method specified numerically or in symbols e.g. logo+black',
	
	'logo.logo_edge_step' => 'pixel step size for logo detection',
	'logo.logo_window' => 'number of frames stored in the logo detection buffer',
	'logo.logo_max_percentage_of_screen' => 'maximum size of a logo (anything larger is discarded)',
	'logo.logo_skip_frames' => 'number of frames to skip between logo detection',
	'logo.logo_edge_threshold' => 'level used to decided whether this is a logo edge',
	'logo.logo_ave_points' => 'logo averaging buffer size',
	'logo.logo_checking_period' => 'maximum period (in frames) to use for detecting a logo',
	'logo.window_percent' => 'percentage of frame to use for detection',
	'logo.logo_num_checks' => 'number of logo re-checks',
	'logo.logo_ok_percent' => 'percentage over which logo detection is deemed a match',
	'logo.logo_edge_radius' => 'number of pixels to use in logo edge detection',
	'logo.logo_rise_threshold'	=> 'percentage over which logo detection is deemed a match : going from non-logo to logo frames',
	'logo.logo_fall_threshold'	=> 'percentage over which logo detection is deemed a match : going from logo to non-logo frames',
	
	'frame.schange_jump' => 'sceen change detection level step',
	'frame.schange_cutlevel' => 'scene change detection percentage above which is deemed a scene change frame',
	'frame.max_black' => 'maximum pixel value under which pixel is treated as black',
	'frame.max_brightness' => 'maximum brightness percentage under which is treated as black',
	'frame.brightness_jump' => 'difference level between frames used to detect a black frame',
	'frame.window_percent' => 'percentage of frame to use for detection',
	'frame.test_brightness' => 'pixel value used for brightness detection',
	'frame.noise_level' => 'noise level used for black frame uniformity detection',
	                                     
	'audio.silence_window'	=> 'adds "fuzziness" to detection of silence frames',
                          
) ;


my @SETTINGS_REGIONS = (
	'global', 'frame', 'logo', 'audio',
) ;
my %SETTINGS_TEMPLATE = (

	'global' => [
		'# ------------------------------------------------',
		'# Global settings.',
		'#',
		'# Any settings here propagate down any unset ',
		'# detection-specific settings',
		'# ------------------------------------------------',
		'',
		'# -- Settings used by detection algorithms (XS) --',
		'',
		'detection_method',
		'',
		'# -- Settings used by analysis algorithms (Perl) --',
		'',
		'max_advert',
		'min_advert',
		'min_program',
		'start_pad',
		'end_pad',
		'min_frames',
		'frame_window',
		'max_gap',
		'reduce_end',
		'reduce_min_gap',
		'increase_start',
		'increase_min_gap',
		'',
	],

	'frame' => [
		'# ------------------------------------------------',
		'# Frame detection specific settings.',
		'# ------------------------------------------------',
		'',
		'# -- Settings used by detection algorithms (XS) --',
		'',
		'frame.schange_jump',
		'frame.schange_cutlevel',
		'frame.max_black',
		'frame.max_brightness',
		'frame.brightness_jump',
		'frame.window_percent',
		'frame.test_brightness',
		'frame.noise_level',
		'',
		'# -- Settings used by analysis algorithms (Perl) --',
		'',
		'frame.max_advert',
		'frame.min_advert',
		'frame.min_program',
		'frame.start_pad',
		'frame.end_pad',
		'frame.min_frames',
		'frame.frame_window',
		'frame.max_gap',
		'frame.reduce_end',
		'frame.reduce_min_gap',
		'frame.increase_start',
		'frame.increase_min_gap',
		'',
	],	                                     
	
	'logo' => [
		'# ------------------------------------------------',
		'# Logo detection specific settings.',
		'# ------------------------------------------------',
		'',
		'# -- Settings used by detection algorithms (XS) --',
		'',
		'logo.logo_edge_step',
		'logo.logo_max_percentage_of_screen',
		'logo.logo_window',
		'logo.logo_skip_frames',
		'logo.logo_edge_threshold',
		'logo.logo_ave_points',
		'logo.logo_checking_period',
		'logo.window_percent',
		'logo.logo_num_checks',
		'logo.logo_ok_percent',
		'logo.logo_edge_radius',
		'',
		'# -- Settings used by analysis algorithms (Perl) --',
		'',
		'logo.max_advert',
		'logo.min_advert',
		'logo.min_program',
		'logo.start_pad',
		'logo.end_pad',
		'logo.min_frames',
		'logo.frame_window',
		'logo.max_gap',
		'logo.reduce_end',
		'logo.reduce_min_gap',
		'logo.increase_start',
		'logo.increase_min_gap',
		'logo.logo_rise_threshold',
		'logo.logo_fall_threshold',
		'',
	],
	
	'audio' => [
		'# ------------------------------------------------',
		'# Audio detection specific settings.',
		'# ------------------------------------------------',
		'',
		'# -- Settings used by detection algorithms (XS) --',
		'',
		'audio.silence_window',
		'',
		'# -- Settings used by analysis algorithms (Perl) --',
		'',
		'audio.max_advert',
		'audio.min_advert',
		'audio.min_program',
		'audio.start_pad',
		'audio.end_pad',
		'audio.min_frames',
		'audio.frame_window',
		'audio.max_gap',
		'audio.reduce_end',
		'audio.reduce_min_gap',
		'audio.increase_start',
		'audio.increase_min_gap',
		'',
    ],          
) ;


#============================================================================================
BEGIN {
	
	## Default for Linux::DVB::DVBT
	$DEFAULT_CONFIG_PATH = [ qw(/etc/dvb ~/.tv) ] ;
	
	my $home ;
	if ( exists $ENV{HOME} and defined $ENV{HOME} ) 
	{
        $home = $ENV{HOME};
    }
	
	## Check OS
	if ( $^O eq 'MSWin32' ) 
	{
		# All versions of Windows

		# Do we have a user profile?
		if ( !$home && exists $ENV{USERPROFILE} && $ENV{USERPROFILE} ) 
		{
			$home = $ENV{USERPROFILE};
		}
	
		# Some Windows use something like $ENV{HOME}
		if ( !$home && exists $ENV{HOMEDRIVE} && exists $ENV{HOMEPATH} && $ENV{HOMEDRIVE} && $ENV{HOMEPATH} ) 
		{
			$home = File::Spec->catpath($ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '');
		}
		
		$DEFAULT_CONFIG_PATH = [] ;
		if ($home && -d $home)
		{
			$home =~ s%\\%/%g ;
			push @$DEFAULT_CONFIG_PATH, "$home/tv" ;
		}
		
		# add current dir
		push @$DEFAULT_CONFIG_PATH, "." ;
	} 
	elsif ( $^O eq 'darwin') 
	{
		if (!$home)
		{		
		    $home = (getpwuid($<))[7];
		}
		
		$DEFAULT_CONFIG_PATH = [] ;
		if ($home && -d $home)
		{
			push @$DEFAULT_CONFIG_PATH, "$home/tv" ;
		}
		
		# add current dir
		push @$DEFAULT_CONFIG_PATH, "." ;
	} 
	elsif ( $^O eq 'MacOS' ) 
	{
		if (!$home)
		{
			# On some platforms getpwuid dies if called at all
			local $SIG{'__DIE__'} = '';
			$home = (getpwuid($<))[7];
		}

		$DEFAULT_CONFIG_PATH = [] ;
		if ($home && -d $home)
		{
			push @$DEFAULT_CONFIG_PATH, "$home/tv" ;
		}
		
		# add current dir
		push @$DEFAULT_CONFIG_PATH, "." ;
	} 
	elsif ( ($^O eq 'linux') || ($^O eq 'cygwin') )
	{
		# Default to Linux::DVB::DVBT
	}
	else 
	{
		# Default to Unix semantics
		$DEFAULT_CONFIG_PATH = [ qw(/etc/dvb ~/.tv .) ] ;
	}
	
	
	
#print "Search Path:\n" ;
#foreach (@$DEFAULT_CONFIG_PATH)
#{
#	print "  $_\n" ;
#}

	
}

	

#============================================================================================

=head2 Functions

=over 4

=cut


#----------------------------------------------------------------------

=item B<read_dvb_adv( [$search_path] )>

Read the advert settings file and return a HASH ref containing the settings.

Optionally set the search path (see L</Config File Search Path>)

See L</Config File>
	
=cut

sub read_dvb_adv
{
	my ($search_path) = @_ ;

	$search_path ||= $DEFAULT_CONFIG_PATH ;
	$DEFAULT_CONFIG_PATH = $search_path ;
	
	my $adv_settings_href = {
		"$ADVERT_GLOBAL_SECTION"	=> {},
	} ;

	## Optional file so allow for it to be not present
	my @fnames = read_filenames($search_path) ;
	foreach my $fname (@fnames)
	{
		my %dvb_adv = (
			"$ADVERT_GLOBAL_SECTION"	=> {},
		) ;
		if (open my $fh, "<$fname")
		{
			my $line ;
			my $channel = $ADVERT_GLOBAL_SECTION ;
			while(defined($line=<$fh>))
			{
				chomp $line ;
				next if $line =~ /^\s*#/ ; # skip comments
				 
				if ($line =~ /\[([^]]+)\]/)
				{
					$channel=$1;
				}
				else
				{
					$dvb_adv{$channel} ||= {} ;
					parse_assignment($line, $dvb_adv{$channel}) ;
				}
			}	
			close $fh ;

			# combine
			$adv_settings_href = Linux::DVB::DVBT::Advert::Config::merge_settings(
									$adv_settings_href,
									\%dvb_adv,
								) ;
		}
		
	}

	return $adv_settings_href ;
}


#----------------------------------------------------------------------

=item B<write_dvb_adv($href [, $search_path])>

Write advert config information

Optionally set the search path (see L</Config File Search Path>)

=cut

sub write_dvb_adv
{
	my ($href, $search_path) = @_ ;
	
	$search_path ||= $DEFAULT_CONFIG_PATH ;
	$DEFAULT_CONFIG_PATH = $search_path ;
	
	## write settings
	do_write_dvb_adv(write_filename($search_path), $href) ;
}

#----------------------------------------------------------------------

=item B<write_filename([$search_path])>

Returns the advert config file writeable filename path

Optionally set the search path (see L</Config File Search Path>)

=cut

sub write_filename
{
	my ($search_path) = @_ ;

	$search_path ||= $DEFAULT_CONFIG_PATH ;
	$DEFAULT_CONFIG_PATH = $search_path ;
	
	my $dir = write_dir($search_path, $FILENAME) ;
	
	return "$dir/$FILENAME" ;
}

#----------------------------------------------------------------------

=item B<read_filenames([$search_path])>

Returns an array of found file paths for all readable advert config files found in search path

Optionally set the search path (see L</Config File Search Path>)

=cut

sub read_filenames
{
	my ($search_path) = @_ ;

	$search_path ||= $DEFAULT_CONFIG_PATH ;
	$DEFAULT_CONFIG_PATH = $search_path ;
	
	my @files = read_dir($search_path, $FILENAME) ;
print "read_filenames() dirs=@files\n" if $DEBUG ;
	foreach my $file (@files)
	{
		$file .= "/$FILENAME" ;
	}

print "read_filenames() = @files\n" if $DEBUG ;
	
	return @files ;
}

#----------------------------------------------------------------------

=item B<write_default_dvb_adv($href [, $search_path])>

Write a default advert config information file

Optionally set the search path (see L</Config File Search Path>)

=cut

sub write_default_dvb_adv
{
	my ($href, $search_path) = @_ ;

	$search_path ||= $DEFAULT_CONFIG_PATH ;
	$DEFAULT_CONFIG_PATH = $search_path ;
	
	# Add some example settings
	my $settings_href = { %$href } ;
	$settings_href->{'Dave'} = {
		'reduce_end' => 900,
		'reduce_min_gap' => 50,
	} ;
	$settings_href->{'BBC1'} = {
		'detection_method' => 'disable',
	} ;
	$settings_href->{'BBC2'} = {
		'detection_method' => 'disable',
	} ;
#	$settings_href->{'BBC3'} = {
#		'detection_method' => 'disable',
#	} ;
#	$settings_href->{'BBC4'} = {
#		'detection_method' => 'disable',
#	} ;
	$settings_href->{'Virgin1'} = {
		'detection_method' => 'disable',
	} ;

print Data::Dumper->Dump(["write_default_dvb_adv() settings:", $href]) if $DEBUG ;
	
	# comment everything EXCEPT detection_method
	my $commented_href = {} ;

	foreach my $section (keys %$settings_href)
	{
		foreach my $field (sort keys %{$href->{$section}})
		{		
			my $val = $href->{$section}{$field} ;
			if (ref($val) eq 'HASH')
			{
				foreach my $subvar (sort keys %{$val})
				{
					next if $subvar eq $METHOD_VAR ;
					$commented_href->{$section}{$field}{$subvar} = 1 ;
				}
			}
			else
			{
				next if $field eq $METHOD_VAR ;
				$commented_href->{$section}{$field} = 1 ;
			}
		}
	}
	
	## write example settings
	do_write_dvb_adv(write_filename($search_path), $settings_href, $commented_href) ;
}


# ============================================================================================
# PROTECTED

#----------------------------------------------------------------------
# Uses optional $commented_href which comments out any matching elements
# This is only used for writing default config files (i.e. allows for 
# commented examples)
#
sub do_write_dvb_adv
{
	my ($fname, $href, $commented_href) = @_ ;
	
	$commented_href ||= {} ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;
	
	# Write config information
	#

	## Global first then channel specific (sort automatically picks global key first)
	my %seen ;
	foreach my $section (sort keys %$href)
	{
		if ($section ne $ADVERT_GLOBAL_SECTION)
		{
			print $fh "\n\n" ;
			print $fh "# ====================================================================\n" ;
			print $fh "# $section channel-specific settings\n" ;
			print $fh "# ====================================================================\n" ;
			print $fh "[$section]\n" ;
		}
		else
		{
			print $fh "\n\n" ;
			print $fh "# ====================================================================\n" ;
			print $fh "# Global settings\n" ;
			print $fh "# \n" ;
			print $fh "# (These settings propagate to any unset channel-specific settings)\n" ;
			print $fh "# ====================================================================\n" ;
		}	
		print $fh "\n\n" ;
			
		$seen{$section} ||= {} ;
		
		## Drive output from template
		for my $region (@SETTINGS_REGIONS)
		{
			my $buffer = "" ;
			my $clear_buffer = 0 ;
			
			foreach my $line (@{$SETTINGS_TEMPLATE{$region}})
			{
				if (!$line || ($line =~ /#/))
				{
					$buffer = "" if $clear_buffer ;
					$buffer .= "$line\n" ;
				}
				else
				{
					# this is a variable
					++$clear_buffer ;
					my $printed = 0 ;
					my ($field, $subvar) = _field_parse($line) ;
					my $comment = _lookup_comment($field, $subvar) ;

					my $val = $href->{$section}{$field} ;
					if ($subvar)
					{
						if (exists($val->{$subvar}) && defined($val->{$subvar}))
						{
							print $fh $buffer ;
							++$printed ;

							print $fh "# $comment\n" if $comment ;
							print $fh "#" if ($commented_href->{$section}{$field}{$subvar}) ;
							print $fh "$field.$subvar = $val->{$subvar}\n" ;
						}
												
						$seen{$section}{$field} ||= {} ;
						$seen{$field}{$subvar} = 1 ;
					}
					else
					{
						if (defined($val))
						{						
							print $fh $buffer ;
							++$printed ;
	
							print $fh "# $comment\n" if $comment ;
							print $fh "#" if ($commented_href->{$section}{$field}) ;
							
							if ($field eq $METHOD_VAR)
							{
								my $str = method_string($val) ;
								print $fh "$field = $str\n" ;
							}
							else
							{
								print $fh "$field = $val\n" ;
							}
						}						
						$seen{$section}{$field} = 1 ;
					}
					
					if ($printed)
					{
						print $fh "\n" ;
						$buffer = "" ;
					}
				}	
			}
					
#			## Catch any "unseen" (i.e. I've forgotten to update the templates!)
#			foreach my $field (sort keys %{$href->{$section}})
#			{		
#				my $val = $href->{$section}{$field} ;
#				if (ref($val) eq 'HASH')
#				{
#					foreach my $subvar (sort keys %{$val})
#					{
#						next if ($seen{$section}{$field}{$subvar}) ;
#						print $fh "$field.$subvar = $val->{$subvar}\n" ;
#					}
#				}
#				else
#				{
#					next if ($seen{$section}{$field}) ;
#					
#					if ($field eq $METHOD_VAR)
#					{
#						my $str = method_string($val) ;
#						print $fh "$field = $str\n" ;
#					}
#					else
#					{
#						if ($val =~ /\S+/)
#						{
#							print $fh "$field = $val\n" ;
#						} 
#					}
#				}
#			}
		}
		
		print $fh "\n" ;
	}
	
	close $fh ;
}


#----------------------------------------------------------------------
sub method_string
{
	my ($val) = @_ ;
	my $method_str = "" ;
	
	if ($val == 0)
	{
		## disabled
		$method_str = $METHOD_DISABLE ;
	}
	else
	{
		## special
		foreach my $method_key (keys %{$Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}})
		{
			my $method_val = $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}{$method_key} ;
			if ($val == $method_val)
			{
				$method_str = $method_key ;
				last ;
			}
		}
	}
	
	## Not found it yet, so work out the string
	if (!$method_str)
	{
		foreach my $method_key (keys %{$Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method'}})
		{
			my $method_val = $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method'}{$method_key} ;
			if ($val & $method_val)
			{
				$method_str .= " + " if $method_str ;
				$method_str .= $method_key ;
			}
		}
	}

	if (!$method_str)
	{
		# error catchall
		$method_str = 'default' ;
	}
	
	return $method_str ;
}


#----------------------------------------------------------------------
sub parse_val
{
	my ($val) = @_ ;
	my $ival ;
	
	if ($val =~ /^0x([\da-z]+)/i)
	{
		$ival = hex($1) ;
	}
	elsif ($val =~ /([\d]+)/)
	{
		$ival = int($1) ;
	}

	return $ival ;
}

#----------------------------------------------------------------------
# Convert mode string into value (eg default - logo + audio)
sub parse_method
{
	my ($var, $val) = @_ ;

print "parse_method($var, $val)\n" if $DEBUG >= 10 ;
	
	my $ival = parse_val($val) ;
	if (defined($ival))
	{
		## Integer - if non-zero then ensure minimum settings are applied
		$val = $ival ;
		
		if ($val)
		{
			$val |= $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}{'MIN'} ;
		}
	}
	else
	{
		# Special string 'disable' or 'none' overrides everything
		if ($val =~ /$METHOD_DISABLE_REGEXP/)
		{
			# no detection
			$val = 0 ;
		}
		else
		{
			# Allow definitions of the form:
			#  default -logo +audio		= (black+logo+audio) - logo +audio = black+audio
			#  logo + audio				= logo+audio -> black+logo+audio (always add MIN)
			#  -logo +audio				= (black+logo+audio) - logo +audio = black+audio (infers default)
			#
			my $got_base=0 ;
			my $method=0 ;
			my $op = '' ;
			while ($val =~ /([\+\-]|\S+)/g)
			{
				my $token = $1 ;
	print " + token: \"$token\" (got base=$got_base) method=$method op=$op\n" if $DEBUG >= 10 ;
				if ($token =~ /(\+|\-)/)
				{
	print " + + an op\n" if $DEBUG >= 10 ;
					## + or - operator, see if a base value has been specified, otherwise start with default
					$op = $1 ;
					if (!$got_base)
					{
						$method = $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}{'DEFAULT'} ;
						++$got_base ; 
	print " + + + set base method=$method\n" if $DEBUG >= 10 ;
					}
	print " + + op=$op\n" if $DEBUG >= 10 ;
				}
				else
				{
					my $method_key = uc $token ;
	print " + + a key $method_key\n" if $DEBUG >= 10 ;
					if (exists($Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method'}{$method_key}))
					{
	print " + + + exists! (op=$op)\n" if $DEBUG >= 10 ;
						if (!$op)
						{
							# Set method to this value
							$method = $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method'}{$method_key} ;
							++$got_base ;
	print " + + + set base method=$method\n" if $DEBUG >= 10 ;
						}
						else
						{
							if ($op eq '+')
							{
								## Add
								$method |= $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method'}{$method_key} ;
							}
							else
							{
								## Subtract
								$method &= ~$Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method'}{$method_key} ;
							}
							$op = '' ;
	print " + + + set method=$method\n" if $DEBUG >= 10 ;
						}
					}
					elsif (exists($Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}{$method_key}))
					{
						## override with special value (e.g. 'default')
						$method = $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}{$method_key} ;
						$op = '' ;
	print " + + + set method=$method\n" if $DEBUG >= 10 ;
					}
				}
			}
			
	print " + method=$val\n" if $DEBUG >= 10 ;
			
			$method = 0 if $method < 0 ;
			$method |= $Linux::DVB::DVBT::Advert::Constants::CONSTANTS{'Advert'}{'detection_method_special'}{'MIN'} ; 
			
			$val = $method ;
	print "METHOD: method=$val\n" if $DEBUG >= 10 ;
		}
	}
print "METHOD: val=$val\n" if $DEBUG >= 10 ;
	
	return $val ;
}


#----------------------------------------------------------------------
sub parse_value
{
	my ($var, $val) = @_ ;
	
	if ($var eq $METHOD_VAR)
	{
		$val = parse_method($var, $val) ;
	}
	else
	{
		my $ival = parse_val($val) ;
		if (defined($ival))
		{
			$val = $ival ;
		}
	}
	return $val ;
}

#----------------------------------------------------------------------
sub parse_assignment
{
	my ($line, $href) = @_ ;

	if ($line =~ /(\S+)\s*=\s*(\S+.*)/)
	{
		my ($var, $val) = ($1, $2) ;
		$val =~ s/\s+$// ;
		if ($var =~ /([\w\d]+)\.([\w\d]+)/)
		{
			# of the form:
			#   logo.logo_threshold
			#
			# so save as:
			#   {logo}{logo_threshold}
			# 
			$href->{$1} ||= {} ;
			$href->{$1}{$2} = parse_value($var, $val) ;
		}
		else
		{
			$href->{$var} = parse_value($var, $val) ;
		}
	}
}

#----------------------------------------------------------------------
# Need to copy globals down to key (if not already set), then use defaults
# if neither set
#
sub cascade_settings
{
	my ($settings_href, $key, $defaults_href) = @_ ;
	
	$settings_href ||= {} ;
	$defaults_href ||= {} ;
	
	my $cascaded_href = {} ;

print Data::Dumper->Dump(["cascade_settings($key) IN:", $settings_href, "DEFAULTS:", $defaults_href]) if $DEBUG >= 10 ;
	
	## start with defaults as a baseline
	if ($key && exists($defaults_href->{$key}))
	{
		_hash_copy_shallow($defaults_href->{$key}, $cascaded_href) ;
	}
	else
	{
		_hash_copy_shallow($defaults_href, $cascaded_href) ;
	}
	
	## copy over any settings defined in the global namespace
	_hash_copy_shallow($settings_href, $cascaded_href) ;

	## copy over any settings defined in the key's namespace
	if ($key && exists($settings_href->{$key}))
	{
		_hash_copy_shallow($settings_href->{$key}, $cascaded_href) ;
	}
	else
	{
		_hash_copy_shallow($settings_href, $cascaded_href) ;
	}
print Data::Dumper->Dump(["cascade_settings($key) OUT:", $cascaded_href]) if $DEBUG >= 10 ;
	
	return $cascaded_href ;
}

#----------------------------------------------------------------------
# Do a deep copy of one HASH heirarchy of settings onto another
# List of settings starting with lowest priority
#
sub merge_settings
{
	my (@settings_list) = @_ ;

print Data::Dumper->Dump(["merge_settings() IN:", \@settings_list]) if $DEBUG >= 10 ;
	
	my $merged_href = {} ;
	foreach my $href (@settings_list)
	{
		_hash_copy_deep($href, $merged_href);
	}

print Data::Dumper->Dump(["merge_settings() OUT:", $merged_href]) if $DEBUG >= 10 ;
	
	return $merged_href ;
}



#----------------------------------------------------------------------
# Do a deep copy of the HASH and sub-hashes, propagating global settings down onto
# any unset channel settings
#
sub channel_settings
{
	my ($advert_settings_href, $channel) = @_ ;
	
	$channel ||= "" ;
	$channel =~ s/^['"](.*)['"]$/$1/ ;
	
print Data::Dumper->Dump(["channel_settings($channel) IN:", $advert_settings_href]) if $DEBUG >= 10 ;
	
	my $cascaded_href = {} ;
	
	## Get copy of globals
	_hash_copy_deep($advert_settings_href->{$ADVERT_GLOBAL_SECTION}, $cascaded_href);
	
	## If channel specified, overwrite globals with channel-specific
	if ($channel && exists($advert_settings_href->{$channel}))
	{
		_hash_copy_deep($advert_settings_href->{$channel}, $cascaded_href);
		
		## Insert channel name into settings
		$cascaded_href->{'channel'} = $channel ;
	}
	
print Data::Dumper->Dump(["channel_settings($channel) OUT:", $cascaded_href]) if $DEBUG >= 10 ;
	return $cascaded_href ;
}



# ============================================================================================
# ============================================================================================


#---------------------------------------------------------------------------------
# Copy key values from one hash into another. Follow a single depth of hierarchy for any
# HASH entries
sub _hash_copy_deep
{
	my ($base_href, $new_href) = @_ ;
	
	$base_href ||= {} ;
	croak "Error: cannot copy HASH because destination is not a HASH ref" if ref($new_href) ne 'HASH' ;
	
	foreach my $key (keys %$base_href)
	{
		my $val = $base_href->{$key} ;
		if (ref($val) eq 'HASH')
		{
			# copy HASH entries
			$new_href->{$key} ||= {} ;
			$new_href->{$key} = {
				%{$new_href->{$key}},
				%$val
			};
		}
		else
		{
			# scalar
			$new_href->{$key} = $val ;
		}
	}
}

#---------------------------------------------------------------------------------
# Copy key values from one hash into another. Skips any HASH entries
sub _hash_copy_shallow
{
	my ($base_href, $new_href) = @_ ;
	
	$base_href ||= {} ;
	
	croak "Error: cannot copy HASH because destination is not a HASH ref" if ref($new_href) ne 'HASH' ;

	foreach my $key (keys %$base_href)
	{
		my $val = $base_href->{$key} ;
		if (!ref($val))
		{
			# scalar
			$new_href->{$key} = $val ;
		}
	}
}

#---------------------------------------------------------------------------------
# Convert template line into field/subvar
sub _field_parse
{
	my ($line) = @_ ;
	my ($field, $subvar) = ($line, '') ;
	
	if ($field =~ /(\w+)\.(.*)/)
	{
		($field, $subvar) = ($1, $2) ;
	}
	return ($field, $subvar) ;
}

#---------------------------------------------------------------------------------
# Lookup the comment text for this field/subvar
sub _lookup_comment
{
	my ($field, $subvar) = @_ ;
	
	my $comment = '' ;
	my $name = $field ;
	$name .= ".$subvar" if $subvar ;
	
	if (exists($SETTINGS_COMMENTS{$name}))
	{
		## use specific comment
		$comment = $SETTINGS_COMMENTS{$name} ;	
	}
	elsif ($subvar && exists($SETTINGS_COMMENTS{$subvar}))
	{
		## no specific comment, so use global
		$comment = $SETTINGS_COMMENTS{$subvar} ;	
	}
	return $comment ;

}


# ============================================================================================
# From Linux::DVB::DVBT::Config
# ============================================================================================

#----------------------------------------------------------------------

=item B<read_dir($search_path, $fname)>

Find directories to read from - all readable directories in search path

=cut

sub read_dir
{
	my ($search_path, $fname) = @_ ;
	
	my @dirs = _expand_search_path($search_path) ;
#	my $dir ;
	
	my @found = () ;
	foreach my $d (@dirs)
	{
		my $found=1 ;
		if (! -f  "$d/$fname")
		{
			## can't find file, so mark as invalid directory 
			$found=0 ;
		}
		
		if ($found)
		{
#			$dir = $d ;
#			last ;
			push @found, $d ;
		}
	}

	@found = ('.') unless @found ;
	print "Searched [ @$search_path ] : read dir=@found\n" if $DEBUG ;
		
#	return $dir ;
	return @found ;
}

#----------------------------------------------------------------------

=item B<write_dir($search_path, $fname)>

Find directory to write to - first writeable directory in search path

=cut

sub write_dir
{
	my ($search_path, $fname) = @_ ;

	my @dirs = _expand_search_path($search_path) ;
	my $dir ;

	print STDERR "Find dir to write to from $search_path ...\n" if $DEBUG ;
	
	foreach my $d (@dirs)
	{
		my $found=1 ;

		print STDERR " + processing $d\n" if $DEBUG ;

		# See if dir exists
		if (!-d $d)
		{
			# See if this user can create the dir
			eval {
				mkpath([$d], $DEBUG, 0755) ;
			};
			$found=0 if $@ ;

			print STDERR " + $d does not exist - attempt to mkdir=$found\n" if $DEBUG ;
		}		

		if (-d $d)
		{
			print STDERR " + $d does exist ...\n" if $DEBUG ;

			# See if this user can write to the dir
			if (open my $fh, ">>$d/$fname")
			{
				close $fh ;
				print STDERR " + + Write to $d/$fname succeded\n" if $DEBUG ;
			}
			else
			{
				print STDERR " + + Unable to write to $d/$fname - aborting this dir\n" if $DEBUG ;

				$found = 0;
			}
		}		
		
		if ($found)
		{
			$dir = $d ;
			last ;
		}
	}

	print STDERR "Searched $search_path : write dir=".($dir?$dir:"")."\n" if $DEBUG ;
	
	return $dir ;
}


#----------------------------------------------------------------------
# Split the search path & expand all the directories to absolute paths
#
sub _expand_search_path
{
	my ($search_path) = @_ ;

	my @dirs = @$search_path ;
	foreach my $d (@dirs)
	{
		# Replace any '~' with $HOME
		$d =~ s/~/\$HOME/g ;
		
		# Now replace any vars with values from the environment
		$d =~ s/\$(\w+)/$ENV{$1}/ge ;
		
		# Ensure path is clean
		$d = File::Spec->rel2abs($d) ;
	}
	
	return @dirs ;
}


#----------------------------------------------------------------------
# 
sub _channel_search
{
	my ($channel_name, $search_href) = @_ ;
	
	my $found_channel_name ;
	
	# start by just seeing if it's the correct name...
	if (exists($search_href->{$channel_name}))
	{
		return $channel_name ;
	}
	else
	{
		## Otherwise, try finding variations on the channel name
		my %search ;

		$channel_name = lc $channel_name ;
		
		# lower-case, no spaces
		my $srch = $channel_name ;
		$srch =~ s/\s+//g ;
		$search{$srch}=1 ;

		# lower-case, replaced words with numbers, no spaces
		$srch = $channel_name ;
		foreach my $num (keys %NUMERALS)
		{
			$srch =~ s/\b($num)\b/$NUMERALS{$num}/ge ;
		}
		$srch =~ s/\s+//g ;
		$search{$srch}=1 ;

		# lower-case, replaced numbers with words, no spaces
		$srch = $channel_name ;
		foreach my $num (keys %NUMERALS)
		{
print STDERR " -- $srch - replace $NUMERALS{$num} with $num..\n" if $DEBUG>3 ;
			$srch =~ s/($NUMERALS{$num})\b/$num/ge ;
print STDERR " -- -- $srch\n" if $DEBUG>3 ;
		}
		$srch =~ s/\s+//g ;
		$search{$srch}=1 ;

		print STDERR " + Searching tuning info [", keys %search, "]...\n" if $DEBUG>2 ;
		
		foreach my $chan (keys %$search_href)
		{
			my $srch_chan = lc $chan ;
			$srch_chan =~ s/\s+//g ;
			
			foreach my $search (keys %search)
			{
				print STDERR " + + checking $search against $srch_chan \n" if $DEBUG>2 ;
				if ($srch_chan eq $search)
				{
					$found_channel_name = $chan ;
					print STDERR " + found $channel_name\n" if $DEBUG ;
					last ;
				}
			}
			
			last if $found_channel_name ;
		}
	}
	
	return $found_channel_name ;
}

# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

