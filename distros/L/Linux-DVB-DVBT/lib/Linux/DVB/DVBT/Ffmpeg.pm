package Linux::DVB::DVBT::Ffmpeg ;

=head1 NAME

Linux::DVB::DVBT::Ffmpeg - Helper module for transcoding recorded streams 

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Ffmpeg ;
  

=head1 DESCRIPTION

Module provides a set of useful routines used for transcoding the recorded .ts transport stream file
into mpeg/mp4 etc. Use of these routines is entirely optional and does not form part of the base 
DVBT functionality.

Currently supported file formats are:

=over 4

=item B<.mpeg> - mpeg2 video / audio / subtitles

=item B<.mp4> - mpeg4 video / audio

The mp4 settings are configured to ensure that the file is compatible with playback on the PS3
(server by Twonky media server).

Note: if you use this then be prepared for a long wait! On my system, a 2 hour film can take 13 hours to transcode.

=item B<.m2v> - mpeg2 video

=item B<.mp2> - mpeg2 audio

=item B<.mp3> - mpeg3 audio

You may notice ffmpeg reports the error:

	lame: output buffer too small
	
Apparently (accoriding to the ffmpeg developers) this is perfectly fine. For further details see (http://howto-pages.org/ffmpeg/#basicaudio).

=back

Obviously, ffmpeg must be installed on your machine to run these functions.

=head1 SUPPORT

I don't intend to support every possible option in ffmpeg! These routines are provided as being helpful, but you
can ignore them if you don't like them.

Helpful suggestions/requests may result in my adding functionality, but I don't promise anything!

=cut


#============================================================================================
# USES
#============================================================================================
use strict ;
use File::Basename ;
use Data::Dumper ;

#============================================================================================
# GLOBALS
#============================================================================================

our $VERSION = '2.10' ;
our $DEBUG = 0 ;
our $DEBUG_FFMPEG = 0 ;

# margin on video length checks (in seconds) - allow for 3 minutes of padding
our $DURATION_MARGIN = 180 ;

# Niceness level
our $NICE = 19 ;

## mpeg4

# const
our $vidbitrate='1050kb' ;
our $bittolerance='200kb' ;
our $audbitrate='128kb' ;
our $audchannels=2 ;
our $threads=2 ;

my $me_method_opt="-me_method" ;

my $common_start =  "-vcodec libx264 ". 
					"-b $vidbitrate ". 
					"-flags +loop ".
					"-cmp +chroma ".
					"-partitions +parti4x4+partp8x8+partb8x8" ;
my $common_end =    "-bf 3 ".
					"-b_strategy 1 ".
					"-threads $threads ". 
					"-level 31 ".
					"-coder 1 ".
					"-me_range 16 ". 
					"-g 250 ".
					"-keyint_min 25 ".
					"-sc_threshold 40 ".
					"-i_qfactor 0.71 ".
					"-bt $bittolerance ".
					"-rc_eq 'blurCplx^(1-qComp)' ". 
					"-qcomp 0.6 ".
					"-qmin 10 ".
					"-qmax 51 ".
					"-qdiff 4 ".
					"-aspect 16:9 ".
					"-y " ;						
my $pass1_codec =   "-an" ;
my $pass2_codec =   "-acodec libfaac ".
					"-ac $audchannels ".
					"-ab $audbitrate ". 
					"-async 1 ".
					"-f mp4 " ;
my $pass1_options = "$me_method_opt epzs ".
					"-subq 1 ".
					"-trellis 0 ". 
					"-refs 1" ;
my $pass2_options = "$me_method_opt umh ".
					"-subq 5 ".
					"-trellis 1 ". 
					"-refs 5 " .
					"-scodec copy ";



## This is how to transcode the source into the various supported formats
our %COMMANDS = (

	'ts'		=> 
		'ffmpeg -i "$src"  -vcodec copy -acodec copy -scodec copy -async 1 -y "$dest.$ext"',

	'mpeg'		=> [
		# First try
		'ffmpeg -i "$src"  -vcodec copy -acodec copy -scodec copy -async 1 -y "$dest.$ext"',
		
		# Alternate
		'ffmpeg -i "$src"  -vcodec mpeg2video -sameq -acodec copy -scodec copy -async 1 -y "$dest.$ext"',
	],
	
	'm2v'		=> [
		# First try
		'ffmpeg -i "$src"  -vcodec copy -f mpeg2video  -y "$dest.$ext"',
		
		# Alternate
		'ffmpeg -i "$src"  -vcodec mpeg2video -sameq -f mpeg2video  -y "$dest.$ext"',
	],

	'mp2'		=> 
		'ffmpeg -i "$src"  -acodec copy -f mp2   -y "$dest.$ext"',

	'mp3'		=> 
		'ffmpeg -i "$src"  -f mp3  -y "$dest.$ext"',

	'mp4'		=> [
		[
			# 1st pass
			'ffmpeg -i "$src" ' . "$pass1_codec -pass 1 $common_start $pass1_options $common_end" . ' -y "$temp.$ext"',
			
			# 2nd pass
			'ffmpeg -i "$src" ' . "$pass2_codec -pass 2 $common_start $pass2_options $common_end" . '$title_opt -y "$dest.$ext"',
		],
	],
) ;


## Order in which to process streams
my @STREAM_ORDER = qw/video audio subtitle/ ;

## Map the requested audio/video/subtitle streams into a file format
#
# file format (extension),	output spec regexp,		supported audio channels (0, 1, 2+)
#
# List is ordered so that preferred file formats are earlier in the list
# End of lis contain least preferred options.
#
our @FORMATS ;

# map file extension into format 
my %FORMATS ;

# Aliases
my %ALIASES ;

BEGIN {



	## Map the requested audio/video/subtitle streams into a file format
	#
	# file format (extension),	output spec regexp,		supported audio channels (0, 1, 2+)
	#
	# List is ordered so that preferred file formats are earlier in the list
	# End of lis contain least preferred options.
	#
	@FORMATS = (
		# default
		['mpeg',	 'va+s*'],	# normal video
		
		['m2v',		 'v'],
		['mp2',		 'a'],
		['mp3',		 'a'],
	
		# catch-alls:
		['mpeg',	 'a+s*'],	# mpeg can also be a container for just multiple audio etc
		['mpeg',	 'vs*'],	

		['mp4',		 'va+s*'],
		['mp4',		 'a+s*'],
		['mp4',		 'vs*'],	

		['ts',	 	'va+s*'],	# normal video
		['ts',		 'a+s*'],	# mpeg can also be a container for just multiple audio etc
		['ts',		 'vs*'],	
		['ts',		 '.+'],		# must contain at least 1 stream
	) ;

	# make a HASH keyed on the file format (extension), where the value is an array of the possible
	# output regexps
	foreach (@FORMATS)
	{
		my ($ext, $regexp) = @$_ ;
		$FORMATS{$ext} ||= [] ;
		push @{$FORMATS{$ext}}, $regexp ;
	}
	
	# Create alias list
	%ALIASES = (
		'mpg'	=> 'mpeg',
		'mpeg2'	=> 'mpeg',
		'mpeg4'	=> 'mp4',
		'TS'	=> 'ts',
	) ;
	foreach (@FORMATS)
	{
		my ($ext, $regexp) = @$_ ;
		$ALIASES{$ext} = $ext ;
	}
	
}


#============================================================================================

=head2 Functions

=over 4

=cut



#-----------------------------------------------------------------------------

=item B<ts_transcode($srcfile, $destfile, $multiplex_info_href, [$written_files_href])>

Transcode the recorded transport stream file into the required format, as specified by $multiplex_info_href. 

(Called by L<Linux::DVB::DVBT::multiplex_transcode()|lib::Linux::DVB::DVBT/multiplex_transcode(%multiplex_info)>).

Multiplex info HASH ref is of the form:

	{
		'pids'	=> [
			{
				'pid'	=> Stream PID
				'pidtype'	=> pid type (video, audio, subtitle)
			},
			...
		],
		'errors' => [],
		'warnings' => [],
		'lines' => [],

		'destfile'	=> final written file name (set by this function)
	}

$written_files_href is an optional HASH that may be provided by the calling routine to track which files have been written.
Since the file type (extension) can be adjusted by the routine to match it's supported formats/codecs, there is the chance that
a file may be accidently over written. The tracking HASH ensures that, if a file was previously written with the same filename,
then the new file is written with a unique filename.

The 'errors' and 'warnings' ARRAY refs are filled with any error/warning messages as the routine is run. Also, the 'lines'
ARRAY ref is filled with the ffmpeg output.

If $destfile is undefined, then the routine just checks that $srcfile duration is as expected; setting the errors array if not.

When $destfile is defined, it's file type is checked to ensure that the number of streams (pids) and the stream types are supported
for this file. If not, then the next preferred file type is used and the destination file adjusted accordingly. The final written 
destination filename is written into the HASH as 'destfile'.

The routine returns 0 on success; non-zero for any error.

=cut

sub ts_transcode
{
	my ($src, $destfile, $multiplex_info_href, $written_files_href) = @_ ;
	my $error = 0 ;

print STDERR "ts_transcode($src, $destfile)\n" if $DEBUG ;
	
	## errors, warnings, and output lines are stored in the HASH
	my $errors_aref = ($multiplex_info_href->{'errors'} ||= []) ;
	my $warnings_aref = ($multiplex_info_href->{'warnings'} ||= []) ;
	my $lines_aref = ($multiplex_info_href->{'lines'} ||= []) ;
	
	## if src not specified, then destination is a ts file - just check it's length
	if (! $src)
	{
		#### Check the destination file duration
		if (! -s "$destfile")
		{
			$error = "final file \"$destfile\" zero length" ;
			push @$errors_aref, $error ;
			return $error ;
		}
		my $file_duration = video_duration("$destfile") ;
		if ($file_duration < $multiplex_info_href->{'duration'} - $DURATION_MARGIN)
		{
			$error = "Duration of final \"$destfile\" ($file_duration secs) not as expected ($multiplex_info_href->{'duration'} secs)" ;
			push @$errors_aref, $error ;
			return $error ;
		}
	}
	else
	{
		#### Check the source file duration
		if (! -s "$src")
		{
			$error = "source file \"$src\" zero length" ;
			push @$errors_aref, $error ;
			return $error ;
		}
		my $file_duration = video_duration("$src") ;
		if ($file_duration < $multiplex_info_href->{'duration'} - $DURATION_MARGIN)
		{
			my $warn = "Duration of source \"$src\" ($file_duration secs) not as expected ($multiplex_info_href->{'duration'} secs)" ;
			push @$warnings_aref, $warn ;
		}
	}
	
	## Save source filename
	$multiplex_info_href->{'srcfile'} = $src ;


	
	#### Select the dest file format
	if ($src)
	{
		# turn the pid types into a valid output spec
		# e.g. vaa for 2 audio + 1 video
		my $out_spec = _pids_out_spec(@{$multiplex_info_href->{'pids'}}) ;
		
		# Ensure the file format is correct
		$error = _sanitise_options(\$destfile, \$out_spec, $errors_aref, $warnings_aref) ;
		return $error if $error ;
		
		
		# check specified filename
		my ($name, $path, $ext) = fileparse($destfile, '\..*') ;
		$ext = substr $ext, 1 if $ext ;
		my $dest = "$path$name" ;
	
		# check to see if we've already written this filename
		if (exists($written_files_href->{"$dest.$ext"}))
		{
			# have to amend the filename so we don't overwrite
			my $num=1 ;
			while (exists($written_files_href->{"$dest$num.$ext"}))
			{
				++$num ;
			}
			
			# report the change
			push @$warnings_aref, "Filename \"$dest.$ext\" was modified to \"$dest$num.$ext\" because a previously written file has the same name" ;
	
			# change
			$dest .= $num ;
		}
		
		# track filenames
		$written_files_href->{"$dest.$ext"} = 1 ;
		
		# return written filename & extension
		$multiplex_info_href->{'destfile'} = "$dest.$ext" ;
		$multiplex_info_href->{'destext'} = ".$ext" ;
		
	
		# make sure the extension is in a form we understand
		my $aliased_ext = $ALIASES{$ext} ;
	
	print STDERR " + dest=$dest  ext=$ext\n" if $DEBUG ;
		
print STDERR "COMMANDS list for $aliased_ext =" . Data::Dumper->Dump([$COMMANDS{$aliased_ext}]) if $DEBUG >= 5 ;
	
		## Run ffmpeg
		my $cmds_ref = $COMMANDS{$aliased_ext} ;
		my @cmds = ref($cmds_ref) ? @$cmds_ref : ($cmds_ref) ;
		
		# create extra variables for variable replacement
		my $temp = "${path}temp$$.$name" ; # used for mp4
		my $title_opt = "" ;	# used for mp4
		if ($multiplex_info_href->{'title'})
		{
			$title_opt = "-metadata title=\"$multiplex_info_href->{'title'}\" " ;
		}
		
		# run through alternatives
		for (my $idx=0; $idx < scalar(@cmds); ++$idx)
		{
			my $cmd = $cmds[$idx] ;
			my $rc=0 ;
			my $pass_str ;
			
			# if this is an array, then it's a multi-pass algorithm
			my @passes = ref($cmd) ? @$cmd : ($cmd) ;
			foreach my $pass (@passes)
			{
	
	print STDERR "PASS: $pass\n" if $DEBUG ;
				($pass_str = $pass) =~ s/\\/\\\\/g ; 
				$pass_str =~ s/\"/\\\"/g ; 
	
	print STDERR "PASS STR: $pass_str\n" if $DEBUG ;
	
				# expand all variables
				my $args ;
				eval "\$args = \"$pass_str\";" ;
	
	print STDERR "ARGS: $args\n" if $DEBUG ;
				
				# run the ffmpeg command
				my @lines ;
				$rc = run_transcoder($args, \@lines) ;
				
				# save results
				push @$lines_aref, @lines ;
	
	print STDERR "RC = $rc\n" if $DEBUG ;
				
				# stop if failed (non-zero exit status)
				last if $rc ;
			}
			
			# failed?
			my $pass_failed ;
			if ($rc)
			{
				$pass_failed = "ffmpeg command failed (status = $rc)" ;
			}
			else
			{
				# check video duration
				if (! -s "$dest.$ext")
				{
					$pass_failed = "destination file \"$dest.$ext\" zero length" ;
				}
				else
				{
					my $file_duration = video_duration("$dest.$ext") ;
					if ($file_duration < $multiplex_info_href->{'duration'} - $DURATION_MARGIN)
					{
						$pass_failed = "Duration of \"$dest.$ext\" ($file_duration secs) not as expected ($multiplex_info_href->{'duration'} secs)" ;
					}
					else
					{
						# all's well so stop
						last ;			
					}
				}
			}
	
			if ($pass_failed)
			{
				# can we try again
				if ( ($idx+1) < scalar(@cmds))
				{
					push @$warnings_aref, "$pass_failed, trying alternate command" ;
				}			
				else
				{
					$error = $pass_failed ;
					push @$errors_aref, $error ;
					return $error ;
				}
			}
		}
		
		# delete any temp files
		for my $tempfile (glob("${path}temp*"))
		{
			unlink $tempfile ;
		}
	}
	
	return $error ;
}




#-----------------------------------------------------------------------------

=item B<sanitise_options($destfile_ref, $out_ref, $lang_ref)>

Processes the destination file, the requested output spec (if any), and the language spec (if any)
to ensure they are set to a valid combination of settings which will result in a supported file format
being written. Adjusts/sets the values accordingly.

If defined, the output spec (and language) always has precedence over the specified file format and the file format
(i.e. extension) will be adjusted to match the required output.

This is used when scheduling recording of multiple channels in the multiplex. This routine ensures that the correct
streams are added to the recording.

=cut

#	Want	Input						Out
#			ext			lang	out		record		out		ext		
#	av					''		''		av			av		.mpeg
#	av		.mpeg		''		''		av			av		.mpeg (=ext)
#	a+v		.mpeg		'a a'	''		a+v			a+v		.mpeg (=ext)
#	avs		.mpeg		''		'avs'	avs			=out	.mpeg (=ext)
#	a+vs	.mpeg		'a a'	'avs'	a+vs		=out	.mpeg (=ext)

#	a					''		'a'		a			=out	.mp2
#	a					'a'		'a'		a			=out	.mp2
#	a		.mp2		''		''		a			a		.mp2  (=ext)
#	a		.mp3		''		''		a			a		.mp3  (=ext)
#	a		.mp3		'a'		''		a			a		.mp3  (=ext)

#	v		.m2v		''		''		v			v		.m2v  (=ext)
#	v					''		'v'		v			=out	.m2v  (=ext)

sub sanitise_options
{
	my ($destfile_ref, $out_ref, $lang_ref, $errors_aref, $warnings_aref) = @_ ;
	my $error = 0 ;
	
	# language spec is optional
	my $lang = "" ;
	$lang_ref ||= \$lang ;
	
	$$destfile_ref  ||= "" ;
	$$lang_ref ||= "" ;
	my $orig_lang = $$lang_ref ;
	
	# merge together the output spec & language spec and ensure output spec is in the correct form
	($$out_ref, $$lang_ref)  = _normalise_output_spec($$out_ref, $$lang_ref) ; 
print STDERR "sanitise_options($$destfile_ref, $$out_ref, $$lang_ref)\n" if $DEBUG ;
	
	# check specified filename
	my ($name, $path, $ext) = fileparse($$destfile_ref, '\..*') ;
	$ext = substr $ext, 1 if $ext ;
	my $dest = "$path$name" ;

print STDERR " + dest=$dest  ext=$ext\n" if $DEBUG ;

	# check output spec
	if (!$$out_ref)
	{
		## no output spec defined

		# get default output spec 
		my $default_ext = $FORMATS[0][0] ;
print STDERR "format regexp 2 out - Default...\n" if $DEBUG ;
		my $default_out = _format_regexp2out($FORMATS[0][1], $$lang_ref) ;

print STDERR "No out specified: default out=$default_out  default ext=$default_ext\n" if $DEBUG ;

		# check file format
		if (!$ext)
		{
print STDERR " + No ext specified: using default out=$default_out  default ext=$default_ext\n" if $DEBUG ;
			# no file format, set it based on default output spec
			$$out_ref = $default_out ;
			$ext = $default_ext ;
		}
		else
		{
			# file format specified, see if we support it
			if (exists($ALIASES{$ext}))
			{
				# make sure the extension is in a form we understand
				my $aliased_ext = $ALIASES{$ext} ;
				
print STDERR "format regexp 2 out - preferred for $ext ...\n" if $DEBUG ;
				# convert the first (preferred) regexp into output spec
				($$out_ref, $$lang_ref) = _format_regexp2out($FORMATS{$aliased_ext}[0], $$lang_ref) ;

print STDERR " + ext specified ($ext): using regexp $FORMATS{$aliased_ext}[0] out=$$out_ref  ext=$aliased_ext\n" if $DEBUG ;
			}
			else
			{
print STDERR " + non-supported ext specified: using default out=$default_out  default ext=$default_ext\n" if $DEBUG ;

				# report warning
				push @$warnings_aref, "File type \"$ext\" is not supported, changing to \"$default_ext\"" ;
					
				# non-supoported file format, set to defaults
				$$out_ref = $default_out ;
				$ext = $default_ext ;
			}
		}
	}

	# check for language spec being dropped due to output spec
	if (($orig_lang) && ($$lang_ref ne $orig_lang))
	{
		# report warning
		push @$warnings_aref, "Language spec \"$orig_lang\" is being ignored because of the specified required output (no audio)" ;
	}
	
	## Do the rest of the processing now that we've handled the language spec
	$error = _sanitise_options($destfile_ref, $out_ref, $errors_aref, $warnings_aref) ;

	return $error ;
}


#-----------------------------------------------------------------------------

=item B<video_duration($file)>

Uses ffmpeg to determine the video file duration. Returns the duration in seconds.

=cut

sub video_duration
{
	my ($file) = @_ ;
	
	my %info = video_info($file) ;
	return $info{'duration'} ;	
}

#-----------------------------------------------------------------------------

=item B<video_info($file)>

Uses ffmpeg to determine the video file contents. Returns a HASH containing:

	'input'	=> Input number
	'duration' => video duration in seconds
	'pids'	=> {
		$pid	=> {
			'input'		=> input number that this pid is part of
			'stream'	=> stream number
			'lang'		=> audio language
			'pidtype'		=> pid type (video, audio, subtitle)
		}
	}

=cut

sub video_info
{
	my ($file) = @_ ;
	
	my @lines ;
	run_transcoder("ffmpeg -i '$file'", \@lines) ;
	
	my %info = (
		'input'	=> undef,
		'duration' => 0,
		'pids'	=> {},
	) ;
	foreach my $line (reverse @lines)
	{
		#	Input #0, mpegts, from 'bbc1-bbc2.ts':
		#	  Duration: 00:00:27.18, start: 15213.487800, bitrate: 4049 kb/s
		#	    Stream #0.0[0x259]: Audio: mp2, 48000 Hz, 2 channels, s16, 256 kb/s
		#	    Stream #0.1[0x258]: Video: mpeg2video, yuv420p, 720x576 [PAR 64:45 DAR 16:9], 15000 kb/s, 25 fps, 25 tbr, 90k tbn, 50 tbc
		#	    Stream #0.2[0x262]: Video: mpeg2video, yuv420p, 720x576 [PAR 64:45 DAR 16:9], 15000 kb/s, 25 fps, 25 tbr, 90k tbn, 50 tbc
		#	    Stream #0.3[0x263]: Audio: mp2, 48000 Hz, 2 channels, s16, 256 kb/s
		#	At least one output file must be specified
		
		#    Stream #0.0[0x258]: Video: mpeg2video, yuv420p, 720x576 [PAR 64:45 DAR 16:9], 15000 kb/s, 25 fps, 25 tbr, 90k tbn, 50 tbc
		#    Stream #0.1[0x259](eng): Audio: mp2, 48000 Hz, 2 channels, s16, 256 kb/s
		#    Stream #0.2[0x25a](eng): Audio: mp2, 48000 Hz, 1 channels, s16, 64 kb/s
		#    Stream #0.3[0x25d](eng): Subtitle: dvbsub

		#    Stream #0.1[0x259](eng): Audio: mp2, 48000 Hz, 2 channels, s16, 256 kb/s
		if ($line =~ /Stream #(\d+)\.(\d+)\[(0x[\da-f]+)\]\((\S+)\): (\S+): /i)
		{
			my ($input, $stream, $lang, $pid, $type) = ($1, $2, $3, hex($4), lc $5) ;
			$info{'pids'}{$pid} = {
				'input'		=> $input,
				'stream'	=> $stream,
				'lang'		=> $lang,
				'pidtype'		=> $type,
			} ;
		}
		#    Stream #0.0[0x258]: Video: mpeg2video, yuv420p, 720x576 [PAR 64:45 DAR 16:9], 15000 kb/s, 25 fps, 25 tbr, 90k tbn, 50 tbc
		elsif ($line =~ /Stream #(\d+)\.(\d+)\[(0x[\da-f]+)\]: (\S+): /i)
		{
			my ($input, $stream, $pid, $type) = ($1, $2, hex($3), lc $4) ;
			$info{'pids'}{$pid} = {
				'input'		=> $input,
				'stream'	=> $stream,
				'pidtype'		=> $type,
			} ;
		}
		#	  Duration: 00:00:27.18, start: 15213.487800, bitrate: 4049 kb/s
		elsif ($line =~ /Duration: (\d+):(\d+):(\d+).(\d+)/i)
		{
			my ($hour, $min, $sec, $ms) = ($1, $2, $3, $4) ;
			$sec += $min*60 + $hour*60*60;
			$info{'duration'} = $sec ;
		}
		#	Input #0, mpegts, from 'bbc1-bbc2.ts':
		elsif ($line =~ /Input #(\d+),/i)
		{
			$info{'input'} = $1 ;
			last ;
		}
	}	
	
	return %info ;
}

#-----------------------------------------------------------------------------

=item B<run_transcoder($args[, $lines_aref])>

Run the transcoder command with the provided arguments. If the $lines_aref ARRAY ref is supplied,
then the output lines from ffmpeg are returned in that array (one entry per line).

Returns the exit status from ffmpeg.

=cut

sub run_transcoder
{
	my ($args, $lines_aref) = @_ ;

	$lines_aref ||= [] ;

	# get command name
	my $transcoder = "" ;
	($transcoder = $args) =~ s/^\s*(\S+).*/$1/ ;

	# set niceness
	my $nice = "" ;
	if ($NICE)
	{
		$nice = "nice -n $NICE" ;
	}
	# run ffmpeg
#	my $cmd = "$nice ffmpeg $args" ;
	my $cmd = "$nice $args" ;
	@$lines_aref = `$cmd 2>&1 ; echo RC=$?` ;
	
	# strip newlines
	foreach (@$lines_aref)
	{
		chomp $_ ;
		
		# Strip out the intermediate processing output
		$_ =~ s/^.*\r//g ;
		
		# prepend with command name
		$_ = "[$transcoder] $_" ;
	}

	# Add command to start
	unshift @$lines_aref , $cmd ;
	
	# get status
	my $rc=-1 ;
	if ($lines_aref->[-1] =~ m/RC=(\d+)/)
	{
		$rc = $1 ;
	}

if ($DEBUG_FFMPEG)
{
	print STDERR "-------------------------------------------\n" ;
	foreach (@$lines_aref)
	{
		print STDERR "$_\n" ;
	}
	print STDERR "STATUS = $rc\n" ;
	print STDERR "-------------------------------------------\n" ;
}
	
	return $rc ;
}

# ============================================================================================
# PRIVATE
# ============================================================================================

# --------------------------------------------------------------------------------------------
# Internal routine that expects the output spec to already have been created/normalised into
# a valid spec (including any language options)
sub _sanitise_options
{
	my ($destfile_ref, $output_spec_ref, $errors_aref, $warnings_aref) = @_ ;
	my $error = 0 ;
	
	$$destfile_ref  ||= "" ;
	$errors_aref ||= [] ;
	$warnings_aref ||= [] ;
	
print STDERR "_sanitise_options($$destfile_ref, $$output_spec_ref)\n" if $DEBUG ;
	
	# check specified filename
	my ($name, $path, $ext) = fileparse($$destfile_ref, '\..*') ;
	$ext = substr $ext, 1 if $ext ;
	my $dest = "$path$name" ;

print STDERR " + dest=$dest  ext=$ext\n" if $DEBUG ;

	# check output spec
	if ($$output_spec_ref)
	{
		## output spec defined
		
		# use it to check the file format
		my @supported_types = _output_formats($$output_spec_ref) ;

print STDERR "out specified: supported types=" . Data::Dumper->Dump([\@supported_types]) if $DEBUG ;
		
		# check file format
		if (!$ext)
		{
			# no file format, set it based on output spec
			if (@supported_types)
			{
				# use first supported type
				$ext = $supported_types[0] ;
			}
		}
		else
		{
			# file format specified, check it matches supported types
			my %valid_types = map { $_ => 1} @supported_types ;
			if (exists($ALIASES{$ext}) && exists($valid_types{ $ALIASES{$ext} }))
			{
				# ok to use
			}
			else
			{
				# file format does not match requested output, use default for the requested output
				my $old_ext = $ext ;
				$ext = undef ;
				if (@supported_types)
				{
					# use first supported type
					my $new_ext = $supported_types[0] ;
					
					# report warning
					push @$warnings_aref, "File type \"$old_ext\" does not match requested output, changing to \"$new_ext\"" ;
					
					# change
					$ext = $new_ext ;
				}
			}
		}
	}


	## If we get here and either the output spec or the file format are not defined, then there's been an error
	if (!$$output_spec_ref)
	{
		$error = "Unable to determine the correct recording type for the specified output file format" ;
	}
	elsif (!$ext)
	{
		$error = "Unable to determine the correct recording type for the specified output file format" ;
	}
	else
	{
		## ok to finish off the output file
		$$destfile_ref = "$path$name.$ext" ;
	}
	
	if ($error)
	{
		push @$errors_aref, $error ;
	}
	
	return $error ;
}


# --------------------------------------------------------------------------------------------
# Ensure the output spec is in the correct form & has the stream types in the correct order
sub _normalise_output_spec
{
	my ($out, $lang) = @_ ;
	
	$out ||= "" ;
	$lang ||= "" ;
	
	my $out_spec = "" ;

print STDERR "_normalise_output_spec(out=\"$out\", lang=\"$lang\")\n" if $DEBUG ;
	
	if ($out)
	{
		# number of audio channels (-1 because, if audio is specified in the output, that already adds 1)
		my $num_audio = _audio_chan_count($lang) ;
		$num_audio-- if $num_audio >= 1 ;

print STDERR " + num_audio=$num_audio\n" if $DEBUG ;
		
		# look at each stream type in the correct order
		foreach my $type (@STREAM_ORDER)
		{
			# add stream type code (a=audio, v=video etc) to spec if this type
			# is in the specified spec
			my $type_ch = substr $type, 0, 1 ;
			if ($out =~ /$type_ch/)
			{
				$out_spec .= $type_ch ;

print STDERR " + + add $type : $type_ch\n" if $DEBUG ;
				
				if ($type eq 'audio')
				{
					## add in the language audio channels (-1 )
					$out_spec .= 'a'x$num_audio ;

print STDERR " + + add lang : ".'a'x$num_audio."\n" if $DEBUG ;
				}
			}
			else
			{
				# this type is not in the output spec
				if ($type eq 'audio')
				{
					## no audio specified, so kill off the language spec
					$lang = "" ;

print STDERR " + + no audio : removing any language spec\n" if $DEBUG ;
				}
			}
		}
	}

print STDERR "final out_spec=\"$out_spec\"\n" if $DEBUG ;

	return ($out_spec, $lang) ;
}


# --------------------------------------------------------------------------------------------
# Convert the output spec into a list of supported types
sub _output_formats
{
	my ($out) = @_ ;
	
	## Get list of valid file types
print STDERR "checking out $out...\n" if $DEBUG ;
	my @valid_types ;
	foreach my $fmt_aref (@FORMATS)
	{
		my ($valid_fmt, $regexp) = @$fmt_aref ;
		
print STDERR " + check $out : $valid_fmt => $regexp\n" if $DEBUG ;
		if ($out =~ m/^$regexp$/)
		{
print STDERR " + + match\n" if $DEBUG ;
			# save format with the command information
#			$valid_types{$valid_fmt} = $COMMANDS{$valid_fmt} ;
			push @valid_types, $valid_fmt ;
		}
	}
	return @valid_types ;
}

# --------------------------------------------------------------------------------------------
# Convert the regular expression string into an output spec string. For example, converts:
#   v+a+s*
# into
#   va
#
# Also amends the spec with any language specifier
#
sub _format_regexp2out
{
	my ($regexp, $lang) = @_ ;
	
	my $out = $regexp ;

print STDERR "_format_regexp2out($regexp)\n" if $DEBUG ;
	
	$out =~ s/\+//g ;
print STDERR " + remove + : $out\n" if $DEBUG ;
	$out =~ s/(.)\*//g ;
print STDERR " + remove X* : $out\n" if $DEBUG ;
	$out =~ s/\*//g ;
print STDERR " + remove * : $out\n" if $DEBUG ;

	# normalise
	($out, $lang) = _normalise_output_spec($out, $lang) ;

print STDERR " + final out : $out\n" if $DEBUG ;
	
	return wantarray ? ($out, $lang) : $out ;
}

# --------------------------------------------------------------------------------------------
# Return the number of audio channels requested by the language spec
#
sub _audio_chan_count
{
	my ($language_spec) = @_ ;
	my $num_audio = 0 ;
	
	# process language spec
	$language_spec ||= "" ;
	if ($language_spec)
	{
		# appends to default audio chan
		if ($language_spec =~ s/\+//g)
		{
			++$num_audio ;
		}
	
		# work through the language spec
		my @lang = split /[\s,]+/, $language_spec ;
		$num_audio += scalar(@lang) ;
	}

	return $num_audio ;	
}

# --------------------------------------------------------------------------------------------
# Convert the recorded pids into a valid output spec
#
sub _pids_out_spec
{
	my (@pids) = @_ ;

print STDERR "_pids_out_spec()\n" if $DEBUG>=10 ;
	
	## turn the pid types into a format string of the form: <audio><video><subtitle>
	## e.g. aav for 2 audio + 1 video
	my $out_spec = "" ;
	foreach my $type (@STREAM_ORDER)
	{
		foreach my $pid_href (@pids)
		{
print STDERR " + check pid $pid_href->{'pid'} type=$pid_href->{'type'} against $type..\n" if $DEBUG>=10 ;
			if ($pid_href->{'pidtype'} eq $type)
			{
				$out_spec .= substr($type, 0, 1) ;
print STDERR " + + added outspec=\"$out_spec\"\n" if $DEBUG>=10 ;
			}
		}
	}
	return $out_spec ;
}


# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

