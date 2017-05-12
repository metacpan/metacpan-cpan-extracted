package Linux::DVB::DVBT::TS ;

=head1 NAME

Linux::DVB::DVBT::TS - Transport Stream utilities 

=head1 SYNOPSIS

	use Linux::DVB::DVBT::TS ;
  
 	my $settings_href = {'debug' => $debug} ;
 	
	# get file information  
 	my %info = info($filename, $settings_href) ;
		
	# Splitting file...
	ts_split($filename, $ofilename, \@cuts, $settings_href) ;

	# Cutting file...
	ts_cut($filename, $ofilename, \@cuts, $settings_href) ;
  
	# repair a file...
	my %stats = repair($filename, $ofilename, \&error_display) ;  
 
 	sub error_display
	{
		my ($info_href) = @_ ;
		print "ERROR: PID $info_href->{'pidinfo'}{'pid'} $info_href->{'error'}{'str'} [$info_href->{'pidinfo'}{'pktnum'}]\n" ;
	}
 	
  
	# Parse the file, calling subroutines on each frame...
	parse($filename, {
		'mpeg2_rgb_callback' = \&colour_callback
		'user_data'		=> {
			'outname'		=> "$outdir/$base%03d.ppm",
		},
	}) ;
	
	sub colour_callback
	{
		my ($tsreader, $info_href, $width, $height, $data, $user_data_href) = @_ ;
		
		## save image
		write_ppm($user_data_href->{'outname'}, $info_href->{'framenum'},
			$width, $height, 
			$data, 
		) ;
	}
	
	

=head1 DESCRIPTION

Module provides a set of useful transport stream utility routines. As well as an underlying 
transport stream parsing framework, this module also incorporates MPEG2 video decoding and AAC 
audio decoding.

=head2 Callbacks

The transport stream parsing framework works through the video file, calling user provided
callback functions at the appropriate points. If you don't specify any callbacks, then the 
framework will run through the video file and do nothing!

Many of the callbacks have the following common arguments passed to them, and are described
here rather than in the callback description:

=over 4

=item $tsreader_ref

The $tsreader_ref is a pointer to the TS framework parser that is calling the callback.
Some other routines accept this value as a parameters (see L</parse_stop($tsreader_ref)>).
Do not modify this value!

=item $user_data

Optionally, you can pass a reference to your own user data into the settings
when calling the framework (see L</Settings>). This reference is passed back
in the $user_data argument

=back

The list of supported callbacks and the arguments they are called with are as follows:


=head3 PID callback

	pid_callback($tsreader_ref, $pid, $user_data)

The pid of the current stream is passed as an integer in $pid. You must return 
a TRUE value to tell the framework to continue processing with this pid; otherwise
return a FALSE value to indicate that the framework should move on to the next pid.

You can use this to skip processing any unwanted pids (mainly to speed up operation).

=head3 Error callback

	error_callback($tsreader_ref, $info_href, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = HASH ref containing:

=over 4

B<pid> = current pid

B<err_flag> = TRUE if error flag is set in this TS packet

B<pes_start> = TRUE is this packet is the start of a PES packet

B<afc> = afc field code

B<pid_error> = count of errors (so far) for this pid

B<pktnum> = TS packet count (from start of video, starting at 0)

=back

B<error> = HASH ref containing:

=over 4

B<code> = error code

B<str> = error string

=back

=back

Called either when there is an error indication in the transport stream, or for 
other errors. 	

=head3 TS callback

	ts_callback($tsreader_ref, $info_href, $packet, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = (see L</Error callback>)

=back

This is called with the complete transport stream packet.


=head3 Payload callback

	payload_callback($tsreader_ref, $info_href, $payload, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = (see L</Error callback>)

=back

This is called with the payload data of the transport stream packet (i.e. with
the headers stripped off).


=head3 PES callback

	pes_callback($tsreader_ref, $info_href, $pes_packet, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = (see L</Error callback>)

=back

=over 4
	
B<pesinfo> = HASH ref containing:

=over 4

B<pes_error> = number of errors in PES packets

B<psi_error> = number of errors in PSI packets

B<ts_error> = number of TS packet errors

B<pes_psi> = String set to:

=over 4

"PES" for a PES packet

"PSI" for an SI packet

=back

B<pts> = presentation timestamp as a HASH ref (see below for details)

B<dts> = display timestamp in same format as B<pts>

B<start_pts> = first pts in video (in same format as B<pts>)

B<start_dts> = first dts in video (in same format as B<pts>)

B<end_pts> = current last pts in video (in same format as B<pts>)

B<end_dts> = current last dts in video (in same format as B<pts>)

B<rel_pts> = pts relative to start (in same format as B<pts>)

B<rel_dts> = dts relative to start (in same format as B<pts>)

=back

=back

The timestamp format (for pts and dts entries) is a HASH containing:

=over 4

B<secs> = pts integer seconds

B<usecs> = remainder in microseconds

B<ts> = string of the 33-bit timestamp integer

=back

So the time in seconds and fractional seconds can be displayed using:

	printf "%d.%06d", $pts->{'secs'},  $pts->{'usecs'} ;
	
(Note: The 33-bit pts value is (roughly) = 'secs'*90000 + 'usecs'*90)


Called with the complete PES/PSI packet.


=head3 PES data callback

	pes_data_callback($tsreader_ref, $info_href, $pes_data, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = (see L</Error callback>)

B<pesinfo> =  (see L</PES callback>)

=back

Called with just the PES/PSI data (i.e. with headers removed).


=head3 MPEG2 callback

	mpeg2_callback($tsreader_ref, $info_href, $width, $height, $image, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = (see L</Error callback>)

B<pesinfo> =  (see L</PES callback>)

B<framenum> = Frame number (starting at 0)

B<gop_pkt> = TS packet number of the last GOP (see MPEG2 docs for details on a GOP!)

=back

This callback is called with a greyscale image, 1 per video frame. The image data ($image) is 
$width pixels wides and $height pixels tall, each pixel being a single 8-bit byte value.

NOTE: If you use the L</PES data callback> with the video pid, you can write the data directly
into a file and this data will be the raw MPEG2 video.


=head3 MPEG2 RGB callback

	mpeg2_rgb_callback($tsreader_ref, $info_href, $width, $height, $image, $user_data)

The information HASH ref is as L</MPEG2 callback>

This callback is called with a colour image. Here the pixels are represented by 3 consecutive
bytes: a byte each for red, green, and blue.


=head3 Audio callback

	audio_callback($tsreader_ref, $info_href, $audio_data, $user_data)

The information HASH ref contains:

=over 4

B<pidinfo> = (see L</Error callback>)

B<pesinfo> =  (see L</PES callback>)

B<sample_rate> = Number of samples pre second (usually 48000)

B<channels> = number of audio channels (usually 2)

B<samples_per_frame> = Total number of samples in an audio frame (usually 1152)

B<samples> = the number of audio samples in the data

B<audio_framenum> = Count of audio frames (starting with 0)

B<framesize> = number of samples per frame for a single channel

=back

Called for every audio frame's worth of data. The audio data is stored as 16-bit values, 1 for each channel.

NOTE: If you use the L</PES data callback> with the audio pid, you can write the data directly
into a file and this data will be the raw AAC audio for the video.

=head3 Progress callback

	progress_callback($tsreader_ref, $state_str, $progress, $total, $user_data)

This is a general progress update callback that is called at regular intervals during the parsing of the video
file. The $progress and $total values are scaled versions of the current packet count and total number of packets
respectively.
 
The $state_str string is one of:

=over 4

"START" = callback will be called once with this string at the start of execution

"END" = callback will be called once with this string at the end of execution

"RUNNING" = normal execution - framework is parsing the video file

"STOPPED" = set if the user has told the framework to abort (see L</parse_stop($tsreader_ref)>)

=back

=head2 Settings

The parsing framework accepts a variety of settings. These are passed as values in a HASH ref. The settings
HASH ref consists of:

=over 4

B<debug> = set this to get debug information (higher setting gives more output) [default=0]

B<num_pkts> = number of TS packets to process before stopping [default=0 which means the whole file]

B<skip_pkts> = start processing the file this many packets from the origin [default=0]

B<origin> = used with B<skip_pkts>. May be 0=FILE START, 1=FILE CENTER, 2=FILE END [default=0]

B<user_data> = set to whatever data you like. This is passed on to all callbacks.

B<pid_callback> = see L</PID callback>

B<error_callback> = see L</error callback>

B<payload_callback> = see L</Payload callback>

B<ts_callback> = see L</TS callback>

B<pes_callback> = see L</PES callback>

B<pes_data_callback> = see L</PES data callback>

B<progress_callback> = see L</Progress callback>

B<mpeg2_callback> = see L</MPEG2 callback>

B<mpeg2_rgb_callback> = see L</MPEG2 RGB callback>

B<audio_callback> = see L</Audio callback>

=back

Most of the entries may be omitted, but it is expected that at least one callback function be set.



=head2 Example

The following example shows the use of the callback in order to save the AAC audio stream to a file:

	Linux::DVB::DVBT::TS::parse("file.ts", {
			# you can put whatever you like in this...
			'user_data'		=> {
				'outname'		=> "test.aac",
			},
			# the callback routine:
			'audio_callback' => \&audio_callback,
		} ;
	    
	sub audio_callback
	{
		my ($tsreader_ref, $info_href, $audio_data, $user_data_href) = @_ ;
		
		open my $fh, ">>$user_data_href->{'outname'}" or die "Unable to write AAC file" ;
		print $fh $audio_data ;
		close $fh ;
	}




=cut


#============================================================================================
# USES
#============================================================================================
use strict ;
use Env ;
use Carp ;
use File::Basename ;
use File::Path ;

use Data::Dumper ;

#============================================================================================
# EXPORTER
#============================================================================================
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw/
	error_str
	info
	parse
	parse_stop
	repair
	ts_cut
	ts_split
/ ;


#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '0.08' ;
our $DEBUG = 0 ;

#============================================================================================
# XS
#============================================================================================
require XSLoader;

if (!$ENV{'TS_NO_XS'})
{
	XSLoader::load('Linux::DVB::DVBT::TS', $VERSION);
}
else
{
	print STDERR "WARNING: Running Linux::DVB::DVBT::TS without XS\n" ;
}

#============================================================================================

#============================================================================================

=head2 Functions

=over 4

=cut


#-----------------------------------------------------------------------------

=item B<repair($src, $dest, $error_display)>

Repair a transport stream file by removing error packets. Returns a hash
of repair stats containing a HASH entry per PID. Each entry is of the form:

=over 4

B<errors>  => error count for this pid

B<details> => HASH where the keys are the error reason string, and the values
               are the error count for that reason.

=back

If any runtime error occurs (e.g. unable to read file), then an error string is added
to the HASH with the field 'error'. 

$error_display is an optional callback routine (see L</Error callback>)

At the moment "repair" is probably an overstatement. What this currently does is just dump
any packets that contain any errors (transport stream or PES). All of the players/transcoders
I've tried so far seem fine with this approach. It also prevents ffmpeg from grabbing all available
memory then crashing!


=cut

sub repair
{
	my ($src, $dest, $error_display) = @_ ;
	my %stats ;
	my %settings = (
		'debug'				=> $DEBUG,
		'error_callback'	=> \&_repair_error_callback,
		'user_data'			=> {
			'error_display' => $error_display,
			'stats' 		=> \%stats,
		},
	) ;
	croak "Unable to read \"$src\"" unless -f $src ;
	croak "Zero-length file \"$src\"" unless -s $src ;
	croak "Must specify a destination filename" unless $dest ;
	
	## Ensure dest dir is present
	my $dir = dirname($dest) ;
	if (! -d $dir)
	{
		mkpath([$dir], 0, 0755) or croak "Unable to create destination directory $dir : $!" ;	
	}
	
	## repair
	Linux::DVB::DVBT::TS::dvb_ts_repair($src, $dest, \%settings) ;
	
	if (Linux::DVB::DVBT::TS::dvb_ts_error())
	{
		$stats{'error'} = Linux::DVB::DVBT::TS::dvb_ts_error_str() ;
		$stats{'errorcode'} = Linux::DVB::DVBT::TS::dvb_ts_error() ;
	}
	
	return %stats ;
}

#-----------------------------------------------------------------------------

=item B<parse($src, $settings_href)>

Parse a TS file. Uses the settings HASH ref ($settings_href) to configure the callbacks etc. 
(see L</Settings> for further details).

=cut

sub parse
{
	my ($src, $settings_href) = @_ ;

	croak "Unable to read \"$src\"" unless -f $src ;
	croak "Zero-length file \"$src\"" unless -s $src ;

	$settings_href ||= {} ;
	Linux::DVB::DVBT::TS::dvb_ts_parse($src, $settings_href) ;
}

#-----------------------------------------------------------------------------

=item B<parse_stop($tsreader_ref)>

Abort the parsing of a TS file now (rather than completing to the end of the file).

=cut

sub parse_stop
{
	my ($tsreader_ref) = @_ ;

	croak "Invalid tsreader reference" unless $tsreader_ref ;
	Linux::DVB::DVBT::TS::dvb_ts_parse_stop($tsreader_ref) ;
}

#-----------------------------------------------------------------------------

=item B<info($src, $settings_href)>

Get information about a TS file. Returns a HASH containing information about the transport
stream file:

=over 4

B<total_pkts> = total number of TS packets in the file

B<start_ts> = first timestamp in file (see L</PES callback> for timestamp format)

B<end_ts> = last timestamp in file (see L</PES callback> for timestamp format)

B<duration> = HASH ref containing video duration information in timestamp format and also:

=over 4

B<hh> = integer hours  

B<mm> = integer minutes

B<ss> = integer seconds  

=back

B<pids> = HASH ref containing an entry per pid found in the file. Each pid contains:

=over 4

B<pidinfo> = (see L</Error callback>)

B<pesinfo> =  (see L</PES callback>)

=back

=back

If there is an error of any kind, the returned HASH conatins a single entry:

=over 4

B<error> = error string describing the error cause

=back

=cut

sub info
{
	my ($src, $settings_href) = @_ ;

	my $info_href = {} ;
	
	unless (-f $src)
	{
		$info_href->{'error'} = "Unable to read \"$src\"" ;
	}
	else
	{
		$settings_href ||= {} ;
		$info_href = Linux::DVB::DVBT::TS::dvb_ts_info($src, $settings_href) ;
	}

	return %$info_href ;
}

#-----------------------------------------------------------------------------

=item B<ts_cut($src, $dest, $cuts_aref, $settings_href)>

Cut a transport stream file, removing the reqions described in $cuts_aref, saving
the results in the new file $dest. 

The ARRAY ref $cuts_aref consists of an array of HASH refs, each HASH ref defining
the start and end of a region to be cut:

=over 4

B<start_pkt> = TS packet number of start of region

B<end_pkt> = TS packet number of end of region

=back

(Note that these ar transport stream packet numbers NOT mpeg2 frame counts. You will need
to scan the file to produce a lookup table if you want to specify cuts in frames (or video
time)).

See L</Settings> for a description of $settings_href.


=cut

sub ts_cut
{
	my ($src, $dest, $cuts_aref, $settings_href) = @_ ;
	
	croak "Unable to read \"$src\"" unless -f $src ;
	croak "Zero-length file \"$src\"" unless -s $src ;
	croak "Must specify a destination filename" unless $dest ;
	
	## Ensure dest dir is present
	my $dir = dirname($dest) ;
	if (! -d $dir)
	{
		mkpath([$dir], 0, 0755) or croak "Unable to create destination directory $dir : $!" ;	
	}
	
	## check cuts
	croak "Must specify a cuts list array ref" unless ref($cuts_aref) eq 'ARRAY' ;
	
	## run command
	$settings_href ||= {} ;
	my $rc = Linux::DVB::DVBT::TS::dvb_ts_cut($src, $dest, $cuts_aref, $settings_href) ;
	if ($rc)
	{
		croak "Error while running ts_cut() : " . Linux::DVB::DVBT::TS::dvb_ts_error_str() ;
	}
	
}

#-----------------------------------------------------------------------------

=item B<ts_split($src, $dest, $cuts_aref, $settings_href)>

Split a transport stream file into multiple files, starting a new file at the 
boundaries described in the ARRAY ref $cuts_aref (see L</ts_cut($src, $dest, $cuts_aref, $settings_href)>).

In this case, a new file is created at the start of the boundary and at the end of the boundary. 
This means that the original file is simply the concatenation of all of the individual files. 

The output files are created using the specified destination name (without any exetension), and appending
a 4-digit count:

	sprintf("%s-%04d.ts", $dest, $filenum)

Where $filenum is the file counter (starting at 1).

For example, with a cut list of:

	start=100, end=200
	start=500, end=600

and assuming a file of 1000 ts packets, running this function will result in 5 output files (where $dest="file"):

	file-0001.ts created from packets 0 to 99 
	file-0002.ts created from packets 100 to 199 
	file-0003.ts created from packets 200 to 499 
	file-0004.ts created from packets 500 to 599 
	file-0005.ts created from packets 600 to 999 

See L</Settings> for a description of $settings_href.


=cut

sub ts_split
{
	my ($src, $dest, $cuts_aref, $settings_href) = @_ ;
	
	croak "Unable to read \"$src\"" unless -f $src ;
	croak "Zero-length file \"$src\"" unless -s $src ;
	croak "Must specify a destination filename" unless $dest ;
	
	## Ensure dest dir is present
	my $dir = dirname($dest) ;
	if (! -d $dir)
	{
		mkpath([$dir], 0, 0755) or croak "Unable to create destination directory $dir : $!" ;	
	}
	
	## check cuts
	croak "Must specify a cuts list array ref" unless ref($cuts_aref) eq 'ARRAY' ;
	croak "Must specify a non-empty cuts list array ref" unless @$cuts_aref ;
	
	## run command
	$settings_href ||= {} ;
	my $rc = Linux::DVB::DVBT::TS::dvb_ts_split($src, $dest, $cuts_aref, $settings_href) ;
	if ($rc)
	{
		croak "Error while running ts_split() : " . Linux::DVB::DVBT::TS::dvb_ts_error_str() ;
	}
}

#-----------------------------------------------------------------------------

=item B<error_str()>

In the event of an error, calling this routine will return the appropriate error
string that (hopefully) makes more sense than an error code integer.

=cut

sub error_str
{
	return Linux::DVB::DVBT::TS::dvb_ts_error_str() ;
}



#============================================================================================
# PRIVATE
#============================================================================================

#-----------------------------------------------------------------------------
sub _repair_error_callback
{
	my ($tsreader, $info_href, $user_href) = @_ ;

	## callback user-provided
	my $error_display = $user_href->{'error_display'} ;
	if ($error_display)
	{
		&$error_display($info_href) ;
	}
	
	## save stats
	my $pid = $info_href->{'pidinfo'}{'pid'} ;
	my ($code, $str) = @{$info_href->{'error'}}{qw/code str/} ;
	
	my $stats_href = $user_href->{'stats'} ;
	$stats_href->{$pid} ||= {
		'errors'	=> 0,
		'details'	=> {},
	} ;
	$stats_href->{$pid}{'errors'}++ ;
	$stats_href->{$pid}{'details'}{$str}++ ;
}


# ============================================================================================
# END OF PACKAGE


1;

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


=head1 AUTHOR

Steve Price

Please report bugs using L<http://rt.cpan.org>.

=head1 BUGS

None that I know of!

=head1 FUTURE

Subsequent releases will include:

=over 4

=item *

Proper transport stream file repair/cutting (which probably involves re-encoding!)

=item *

Add parsing of SI streams (e.g. PAT, epg etc) read from a file

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Steve Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

