package Linux::DVB::DVBT::Config ;

=head1 NAME

Linux::DVB::DVBT::Config - DVBT configuration functions

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Config ;
  

=head1 DESCRIPTION

Module provides a set of configuration routines used by the DVBT module. It is unlikely that you will need to access these functions directly, but
you can if you wish.

=cut


use strict ;

use Data::Dumper ;

our $VERSION = '2.08' ;
our $DEBUG = 0 ;

our $DEFAULT_CONFIG_PATH = '/etc/dvb:~/.tv' ;

use File::Path ;
use File::Spec ;

my %FILES = (
	'ts'		=> { 'file' => "dvb-ts", 		'required' => 1 },
	'pr'		=> { 'file' => "dvb-pr",		'required' => 1 },
	'aliases'	=> { 'file' => "dvb-aliases",	'required' => 0 },
) ;

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

our @SCAN_INFO_FIELDS = qw/pr ts lcn freqs/ ;

#============================================================================================

=head2 Functions

=over 4

=cut



#----------------------------------------------------------------------

=item B<find_tsid($frequency, $tuning_href)>

Given a frequency, find the matching TSID.

$tuning_href is the HASH returned by L<Linux::DVB::DVBT::get_tuning_info()|lib::Linux::DVB::DVBT/get_tuning_info()>.

=cut

sub find_tsid
{
	my ($frequency, $tuning_href) = @_ ;
	my $tsid ;

#	'ts' => 
#	      4107 =>
#	        { 
#	          tsid => 4107,   
#			  frequency => 57800000,            
#	          ...
#	        },

	foreach my $this_tsid (keys %{$tuning_href->{'ts'}})
	{
		if ($frequency == $tuning_href->{'ts'}{$this_tsid}{'frequency'})
		{
			$tsid = $this_tsid ;
			last ;
		}
	}
	return $tsid ;
}

#----------------------------------------------------------------------

=item B<tsid_params($tsid, $tuning_href)>

Given a tsid, return the frontend params (or undef). The frontend params HASH
contain the information used to tune the frontend i.e. this is the transponder
(TSID) information. It corresponds to the matching 'ts' entry in the tuning info
HASH.

$tuning_href is the HASH returned by L<Linux::DVB::DVBT::get_tuning_info()|lib::Linux::DVB::DVBT/get_tuning_info()>.

=cut

sub tsid_params
{
	my ($tsid, $tuning_href) = @_ ;

	my $params_href ;

#	'ts' => 
#	      4107 =>
#	        { 
#	          tsid => 4107,   
#			  frequency => 57800000,            
#	          ...
#	        },

	if ($tsid && exists($tuning_href->{'ts'}{$tsid}))
	{
		$params_href = $tuning_href->{'ts'}{$tsid} ;
	}

	return $params_href ;
}

#----------------------------------------------------------------------

=item B<chan_from_pid($tsid, $pid, $tuning_href)>

Given a tsid and pid, find the matching channel information and returns the 
program HASH ref if found. This corresponds to the matching 'pr' entry in the tuning
info HASH.

$tuning_href is the HASH returned by L<Linux::DVB::DVBT::get_tuning_info()|lib::Linux::DVB::DVBT/get_tuning_info()>.

=cut

sub chan_from_pid
{
	my ($tsid, $pid, $tuning_href) = @_ ;
	my $pr_href ;
	
	# skip PAT
	return $pr_href unless $pid ;

#	'pr' =>
#	      BBC ONE => 
#	        {
#	          pnr => 4171,
#	          tsid => 4107,
#	          tuned_freq => 57800000,
#	          ...
#	        },

	foreach my $chan (keys %{$tuning_href->{'pr'}})
	{
#		if ($tsid == $tuning_href->{'pr'}{$chan}{'tsid'})
		if ($tsid eq $tuning_href->{'pr'}{$chan}{'tsid'})
		{
			foreach my $stream (qw/video audio teletext subtitle/)
			{
				if ($pid == $tuning_href->{'pr'}{$chan}{$stream})
				{
					$pr_href = $tuning_href->{'pr'}{$chan} ;
					last ;
				}
			}
			last if $pr_href ;

			# check other audio
			my @audio = audio_list( $tuning_href->{'pr'}{$chan} ) ;
			foreach (@audio)
			{
				if ($pid == $_)
				{
					$pr_href = $tuning_href->{'pr'}{$chan} ;
					last ;
				}
			}
		}
		
		last if $pr_href ;
	}

	return $pr_href ;
}

#----------------------------------------------------------------------

=item B<pid_info($pid, $tuning_href)>

Given a pid, find the matching channel & TSID information

Returns an array of HASH entries, each HASH containing the stream type (video, audio, subtitle, or
teletext), along with a copy of the associated program information (i.e. the matching 'pr' entry from the
tuning info HASH):

	@pid_info = [
		{
			  'pidtype' => video, audio, subtitle, teletext
		     pnr => 4171,
		     tsid => 4107,
		     tuned_freq => 57800000,
		          ...
		},
		...
	]


$tuning_href is the HASH returned by L<Linux::DVB::DVBT::get_tuning_info()|lib::Linux::DVB::DVBT/get_tuning_info()>.

=cut

sub pid_info
{
	my ($pid, $tuning_href) = @_ ;

print "pid_info(pid=\"$pid\")\n" if $DEBUG ;

	my @pid_info ;
	
	# skip PAT
	return @pid_info unless $pid ;
	
	foreach my $chan (keys %{$tuning_href->{'pr'}})
	{
		my $tsid = $tuning_href->{'pr'}{$chan}{'tsid'} ;
		
		# program
		my @chan_pids ;
		foreach my $stream (qw/video audio teletext subtitle/)
		{
			push @chan_pids, [$stream, $tuning_href->{'pr'}{$chan}{$stream}] ;
		}
		
		# extra audio
		my @audio = audio_list( $tuning_href->{'pr'}{$chan} ) ;
		foreach (@audio)
		{
			push @chan_pids, ['audio', $_] ;
		}

		# extra subtitle by rainbowcrypt
		my @sub = sub_list( $tuning_href->{'pr'}{$chan} ) ;
		foreach (@sub)
		{
			push @chan_pids, ['subtitle', $_] ;
		}
		
		# SI
		foreach my $si (qw/pmt/)
		{
			push @chan_pids, [uc $si, $tuning_href->{'pr'}{$chan}{$si}] ;
		}
		

		# check pids
		foreach my $aref (@chan_pids)
		{
			if ($pid == $aref->[1])
			{
print " + pidtype=$aref->[0]\n" if $DEBUG ;
				push @pid_info, {
					%{$tuning_href->{'pr'}{$chan}},
					'pidtype'		=> $aref->[0],
					
					# keep ref to program HASH (used by downstream functions)  
					'demux_params'	=> $tuning_href->{'pr'}{$chan},
				} ;
			}
		}
	}

	return @pid_info ;
}

#----------------------------------------------------------------------

=item B<find_channel($channel_name, $tuning_href)>

Given a channel name, do a "fuzzy" search and return an array containing params:

	($frontend_params_href, $demux_params_href)

$demux_params_href HASH ref are of the form:

	        {
	          pnr => 4171,
	          tsid => 4107,
	          tuned_freq => 57800000,
	          ...
	        },
	        
(i.e. $tuning_href->{'pr'}{$channel_name})

$frontend_params_href HASH ref are of the form:

	        { 
	          tsid => 4107,   
			  frequency => 57800000,            
	          ...
	        },
	
(i.e. $tuning_href->{'ts'}{$tsid} where $tsid is TSID for the channel)
	 
$tuning_href is the HASH returned by L<Linux::DVB::DVBT::get_tuning_info()|lib::Linux::DVB::DVBT/get_tuning_info()>.

=cut

sub find_channel
{
	my ($channel_name, $tuning_href) = @_ ;
	
	my ($frontend_params_href, $demux_params_href) ;

	## Look for channel info
	print STDERR "find $channel_name ...\n" if $DEBUG ;
	
	$channel_name = _channel_alias($channel_name, $tuning_href->{'aliases'}) ;
	my $found_channel_name = _channel_search($channel_name, $tuning_href->{'pr'}) ;
	if ($found_channel_name)
	{
		$demux_params_href = $tuning_href->{'pr'}{$found_channel_name} ;
	}
					
	## If we've got the channel, look up it's frontend settings
	if ($demux_params_href)
	{
		my $tsid = $demux_params_href->{'tsid'} ;
		$frontend_params_href = {
			%{$tuning_href->{'ts'}{$tsid}},
			'tsid'	=> $tsid,
		} ;
	}

	return ($frontend_params_href, $demux_params_href) ;
}


#----------------------------------------------------------------------
# Do "fuzzy" search for channel name
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


#----------------------------------------------------------------------
# Lookup channel name alias (if it exists)
#
sub _channel_alias
{
	my ($channel_name, $alias_href) = @_ ;

	if ($alias_href && scalar(keys %$alias_href))
	{
print STDERR "Searching channel aliases for \"$channel_name\" ... \n" if $DEBUG>3 ;
		my $alias_key = _channel_search($channel_name, $alias_href) ;
		if ($alias_key)
		{
			my $alias = $alias_href->{$alias_key} ;
print STDERR "... using alias \"$alias\" for \"$channel_name\"\n" if $DEBUG>3 ;
			$channel_name = $alias ;
		}
	}	
	
	return $channel_name ;
}

#----------------------------------------------------------------------

=item B<audio_pids($demux_params_href, $language_spec, $pids_aref)>

Process the demux parameters and a language specifier to return the list of audio
streams required. 

demux_params are of the form:

	        {
	          pnr => 4171,
	          tsid => 4107,
	          tuned_freq => 57800000,
	          ...
	        },

(i.e. $tuning_href->{'pr'}{$channel_name})

	
Language specifier string is in the format:

=over 4

=item a)

Empty string : just return the default audio stream pid

=item b)

Comma/space seperated list of one or more language names : returns the audio stream pids for all that match (does not necessarily include default stream)

=back
	
If the list in (b) contains a '+' character (normally at the start) then the default audio stream is automatically included in teh list, and the 
extra streams are added to it.
	
For example, if a channel has the following audio details: eng:100 eng:101 fra:102 deu:103
Then the following specifications result in the lists as shown:

=over 4

=item *	

"" => (100)

=item *	

"eng deu" => (100, 103)

=item *	

"+eng fra" => (100, 101, 102)

=back
	
Note that the language names are not case sensitive


=cut

sub audio_pids
{
	my ($demux_params_href, $language_spec, $pids_aref) = @_ ;
	my $error = 0 ;
	
print "audio_pids(lang=\"$language_spec\")\n" if $DEBUG ;

	my $audio_pid = $demux_params_href->{'audio'} ;
	
	## simplest case is no language spec
	$language_spec ||= "" ;
	if (!$language_spec)
	{
print " + simplest case - add default audio $audio_pid\n" if $DEBUG ;

		push @$pids_aref, $audio_pid ;
		return 0 ;		
	}

	# split details
	my @audio_details ;
	my $details = $demux_params_href->{'audio_details'} ;
print "audio_details=\"$details\")\n" if $DEBUG ;
	while ($details =~ m/(\S+):(\d+)/g)
	{
		my ($lang, $pid) = ($1, $2) ;
		push @audio_details, {'lang'=>lc $lang, 'pid'=>$pid} ;

print " + lang=$audio_details[-1]{lang}  pid=$audio_details[-1]{pid}\n" if $DEBUG >= 10 ;
	}

	# drop default audio
	shift @audio_details ;

	# process language spec
	if ($language_spec =~ s/\+//g)
	{
		# ensure default is in the list
		push @$pids_aref, $audio_pid ;

print " - lang spec contains '+', added default audio\n" if $DEBUG >= 10 ;
	}

print "process lang spec\n" if $DEBUG >= 10 ;

	# work through the language spec
	my $pid ;
	my $lang ;
	my @lang = split /[\s,]+/, $language_spec ;
	while (@lang)
	{
		$lang = shift @lang ;

print " + lang=$lang\n" if $DEBUG >= 10 ;
		
		$pid = undef ;
		while (!$pid && @audio_details)
		{
			my $audio_href = shift @audio_details ;
print " + + checking this audio detail: lang=$audio_href->{lang}  pid=$audio_href->{pid}\n" if $DEBUG >= 10 ;
			if ($audio_href->{'lang'} =~ /$lang/i)
			{
				$pid = $audio_href->{'pid'} ;
print " + + Found pid = $pid\n" if $DEBUG >= 10 ;

				push @$pids_aref, $pid ;
print " + Added pid = $pid\n" if $DEBUG >= 10 ;
			}
		}
		last unless @audio_details ;
	}
	
	# clean up
	if (@lang || !$pid)
	{
		unshift @lang, $lang if $lang ;
		$error = "Error: could not find the languages: " . join(', ', @lang) . " associated with program \"$demux_params_href->{pnr}\"" ;
	}
	
	return $error ;
}
#----------------------------------------------------------------------

=item B<subtitle_pids($demux_params_href, $language_spec, $pids_aref)> #copy/paste from audio_pid by rainbowcrypt

Process the demux parameters and a language specifier to return the list of audio
streams required. 

demux_params are of the form:

	        {
	          pnr => 4171,
	          tsid => 4107,
	          tuned_freq => 57800000,
	          ...
	        },

(i.e. $tuning_href->{'pr'}{$channel_name})

	
Language specifier string is in the format:

=over 4

=item a)

Empty string : just return the default audio stream pid

=item b)

Comma/space seperated list of one or more language names : returns the audio stream pids for all that match (does not necessarily include default stream)

=back
	
If the list in (b) contains a '+' character (normally at the start) then the default audio stream is automatically included in teh list, and the 
extra streams are added to it.
	
For example, if a channel has the following audio details: eng:100 eng:101 fra:102 deu:103
Then the following specifications result in the lists as shown:

=over 4

=item *	

"" => (100)

=item *	

"eng deu" => (100, 103)

=item *	

"+eng fra" => (100, 101, 102)

=back
	
Note that the language names are not case sensitive


=cut

sub subtitle_pids
{ #copy/paste from audio_pid by rainbowcrypt
	my ($demux_params_href, $language_spec, $pids_aref) = @_ ;
	my $error = 0 ;
	
print "subtitle_pids(lang=\"$language_spec\")\n" if $DEBUG ;

	my $subtitle_pid = $demux_params_href->{'subtitle'} ;
	
	## simplest case is no language spec
	$language_spec ||= "" ;
	if (!$language_spec)
	{
print " + simplest case - add default subtitle $subtitle_pid\n" if $DEBUG ;

		push @$pids_aref, $subtitle_pid ;
		return 0 ;		
	}

	# split details
	my @subtitle_details ;
	my $details = $demux_params_href->{'subtitle_details'} || "" ;
print "subtitle_details=\"$details\")\n" if $DEBUG ;
	while ($details =~ m/(\S+):(\d+)/g)
	{
		my ($lang, $pid) = ($1, $2) ;
		push @subtitle_details, {'lang'=>lc $lang, 'pid'=>$pid} ;

print " + lang=$subtitle_details[-1]{lang}  pid=$subtitle_details[-1]{pid}\n" if $DEBUG >= 10 ;
	}

	# drop default audio
	shift @subtitle_details ;

	# process language spec
	if ($language_spec =~ s/\+//g)
	{
		# ensure default is in the list
		push @$pids_aref, $subtitle_pid ;

print " - lang spec contains '+', added default subtitle\n" if $DEBUG >= 10 ;
	}

print "process lang spec\n" if $DEBUG >= 10 ;

	# work through the language spec
	my $pid ;
	my $lang ;
	my @lang = split /[\s,]+/, $language_spec ;
	while (@lang)
	{
		$lang = shift @lang ;

print " + lang=$lang\n" if $DEBUG >= 10 ;
		
		$pid = undef ;
		while (!$pid && @subtitle_details)
		{
			my $subtitle_href = shift @subtitle_details ;
print " + + checking this subtitle detail: lang=$subtitle_href->{lang}  pid=$subtitle_href->{pid}\n" if $DEBUG >= 10 ;
			if ($subtitle_href->{'lang'} =~ /$lang/i)
			{
				$pid = $subtitle_href->{'pid'} ;
print " + + Found pid = $pid\n" if $DEBUG >= 10 ;

				push @$pids_aref, $pid ;
print " + Added pid = $pid\n" if $DEBUG >= 10 ;
			}
		}
		last unless @subtitle_details ;
	}
	
	# clean up
	if (@lang || !$pid)
	{
		unshift @lang, $lang if $lang ;
		$error = "Error: could not find the languages: " . join(', ', @lang) . " associated with program \"$demux_params_href->{pnr}\"" ;
	}
	
	return $error ;
}

#----------------------------------------------------------------------

=item B<out_pids($demux_params_href, $out_spec, $language_spec, $subtitle_language_spec, $pids_aref)> #modified by rainbowcrypt

Process the demux parameters and an output specifier to return the list of all
stream pids required. 

Output specifier string is in the format such that it just needs to contain the following characters:

   a = audio
   v = video
   s = subtitle

Returns an array of HASHes of the form:

	 {'pid' => $pid, 'pidtype' => $type, 'pmt' => $pmt} 


=cut

sub out_pids
{
	my ($demux_params_href, $out_spec, $language_spec, $subtitle_language_spec, $pids_aref) = @_ ;
	my $error = 0 ;

	## default
	$out_spec ||= "av" ;
	
#	my $pmt = $demux_params_href->{'pmt'} ;

	## Audio required?
	if ($out_spec =~ /a/i)
	{
		my @audio_pids ;
		$error = audio_pids($demux_params_href, $language_spec, \@audio_pids) ;
		return $error if $error ;
		
		foreach my $pid (@audio_pids)
		{
			push @$pids_aref, {
				'pid' => $pid, 
				'pidtype' => 'audio', 
					
				# keep ref to program HASH (used by downstream functions)  
				'demux_params'	=> $demux_params_href,
			} if $pid ;
		}
	}
	
	## Video required?
	if ($out_spec =~ /v/i)
	{
		my $pid = $demux_params_href->{'video'} ;
		push @$pids_aref, {
			'pid' => $pid, 
			'pidtype' => 'video', 
					
			# keep ref to program HASH (used by downstream functions)  
			'demux_params'	=> $demux_params_href,
		} if $pid ;
	}
	
	## Subtitle required?
	if ($out_spec =~ /s/i) #modified by rainbowcrypt
	{
		my @subtitle_pids ;
		$error = subtitle_pids($demux_params_href, $subtitle_language_spec, \@subtitle_pids) ;
		return $error if $error ;
		
		foreach my $pid (@subtitle_pids)
		{
			push @$pids_aref, {
				'pid' => $pid, 
				'pidtype' => 'subtitle', 
					
				# keep ref to program HASH (used by downstream functions)  
				'demux_params'	=> $demux_params_href,
			} if $pid ;
		}
	}
	
	return $error ;
}

#----------------------------------------------------------------------

=item B<audio_list($demux_params_href)>

Process the demux parameters and return a list of additional audio
streams (or an empty list if none available).

For example:

	        { 
	          audio => 601,                   
	          audio_details => eng:601 eng:602,       
				...
	        },

would return the list: ( 602 )


=cut

sub audio_list
{
	my ($demux_params_href) = @_ ;
	my @pids ;
	
	my $audio_pid = $demux_params_href->{'audio'} ;
	my $details = $demux_params_href->{'audio_details'} ;
	while ($details =~ m/(\S+):(\d+)/g)
	{
		my ($lang, $pid) = ($1, $2) ;
		push @pids, $pid if ($pid != $audio_pid) ;
	}
	
	return @pids ;
}

#----------------------------------------------------------------------

=item B<sub_list($demux_params_href)> by rainbowcrypt

Process the demux parameters and return a list of additional subtitle
streams (or an empty list if none available).

For example:

	        { 
	          subtitle => 601,                   
	          subtitle_details => DVD_malentendant:601 DVB-francais:602,       
				...
	        },

would return the list: ( 602 )


=cut

sub sub_list
{
	my ($demux_params_href) = @_ ;
	my @pids ;
	
	my $sub_pid = $demux_params_href->{'subtitle'} ;
	my $details = $demux_params_href->{'subtitle_details'} || "" ;
	while ($details =~ m/(\S+):(\d+)/g)
	{
		my ($lang, $pid) = ($1, $2) ;
		push @pids, $pid if ($pid != $sub_pid) ;
	}
	
	return @pids ;
}


#----------------------------------------------------------------------

=item B<read($search_path)>

Read tuning information from config files. Look in search path and return first
set of readable file information in a tuning HASH ref.

Returns a HASH ref of tuning information - i.e. it contains the complete information on all
transponders (under the 'ts' field), and all programs (under the 'pr' field). [see L<Linux::DVB::DVBT::scan()> method for format].


=cut

sub read
{
	my ($search_path) = @_ ;
	
	$search_path = $DEFAULT_CONFIG_PATH unless defined($search_path) ;
	
	my $href ;
	my $dir = read_dir($search_path) ;
	if ($dir)
	{
		$href = {} ;
		foreach my $region (keys %FILES)
		{
		no strict "refs" ;
			my $fn = "read_dvb_$region" ;

			print STDERR " + Running $fn() for $region ...\n" if $DEBUG ;

			$href->{$region} = &$fn("$dir/$FILES{$region}{'file'}") ;
		}
		
		## Special case - get tuning info if present
		$href->{'freqfile'} = read_dvb_ts_freqs("$dir/$FILES{ts}{'file'}") ;
		
		print STDERR "Read config from $dir\n" if $DEBUG ;
		print STDERR Data::Dumper->Dump(["Config=", $href]) if $DEBUG >= 5 ;
		
	}
	return $href ;
}

#----------------------------------------------------------------------

=item B<write($search_path, $tuning_href)>

Write tuning information into the first writeable area in the search path.

=cut

sub write
{
	my ($search_path, $href) = @_ ;

	$search_path = $DEFAULT_CONFIG_PATH unless defined($search_path) ;
	my $dir = write_dir($search_path) ;
	if ($dir && $href)
	{
		foreach my $region (keys %FILES)
		{
		no strict "refs" ;
			my $fn = "write_dvb_$region" ;
			&$fn("$dir/$FILES{$region}{'file'}", $href->{$region}, $href->{'freqfile'}) ;
		}

		print STDERR "Written config to $dir\n" if $DEBUG ;
	}
}


#----------------------------------------------------------------------

=item B<read_filename($filetype, [$search_path] )>

Returns the readable filename for the specified file type, which can be one of: 'pr'=program, 'ts'=transponder.

Optionally specify the search path (otherwise the default search path is used)

Returns undef if invalid file type is specified, or unable to find a readable area.

=cut

sub read_filename
{
	my ($filetype, $search_path) = @_ ;
	
	my $filename ;
	return $filename if (!exists($FILES{$filetype}));
	
	$search_path = $DEFAULT_CONFIG_PATH unless defined($search_path) ;
	my $dir = read_dir($search_path) ;

	if ($dir)
	{
		$filename = "$dir/$FILES{$filetype}{'file'}" ;
	}
	return $filename ;
}

#----------------------------------------------------------------------

=item B<write_filename($filetype, [$search_path] )>

Returns the writeable filename for the specified file type, which can be one of: 'pr'=program, 'ts'=transponder.

Optionally specify the search path (otherwise the default search path is used)

Returns undef if invalid file type is specified, or unable to find a writeable area.

=cut

sub write_filename
{
	my ($filetype, $search_path) = @_ ;

	my $filename ;
	return $filename if (!exists($FILES{$filetype}));

	$search_path = $DEFAULT_CONFIG_PATH unless defined($search_path) ;
	my $dir = write_dir($search_path) ;

	if ($dir)
	{
		$filename = "$dir/$FILES{$filetype}{'file'}" ;
	}
	return $filename ;
}


#----------------------------------------------------------------------

=item B<tsid_sort($tsid_a, $tsid_b)>

Sorts TSIDs. As I now allow duplicate TSIDs in scans, and the duplicates
are suffixed with a letter to make it obvious, numeric sorting is not possible.

This function can be used to correctly sort the TSIDs into order. Returns the usual
-1, 0, 1 depending on if a is <, ==, or > b

=cut

sub tsid_sort
{
	my ($tsid_a, $tsid_b) = @_ ;
	
	my $a_int = int($tsid_a) ;
	my $b_int = int($tsid_b) ;
	
	return 
		$a_int <=> $b_int
			||
		$tsid_a cmp $tsid_b
	 ;
}

#----------------------------------------------------------------------

=item B<tsid_str($tsid)>

Format the tsid number/name into a string. As I now allow duplicate TSIDs in 
scans, and the duplicates are suffixed with a letter to make it obvious which
are duplicates. This routine formats the numeric part and always adds a suffix
character (or space if none present).

=cut

sub tsid_str
{
	my ($tsid) = @_ ;
	
	my ($tsid_int, $tsid_suffix) = ($tsid, " ") ;
	if ($tsid =~ /(\d+)([a-z])/i)
	{
		($tsid_int, $tsid_suffix) = ($1, $2) ;
	}

	return sprintf "%5d$tsid_suffix", $tsid_int ;
}

#----------------------------------------------------------------------

=item B<tsid_delete($tsid, $tuning_href)>

Remove the specified TSID from the tuning information. Also removes any channels
that are under that TSID. 

=cut

sub tsid_delete
{
	my ($tsid, $tuning_href) = @_ ;
	
	my $ok = 0;
	if (exists($tuning_href->{'ts'}{$tsid}))
	{
		$ok = 1 ;
		my $info_href = _scan_info($tuning_href) ;
	
		delete $tuning_href->{'ts'}{$tsid} ;
			
		foreach my $pnr (keys %{$info_href->{'tsid'}{$tsid}{'pr'}} )
		{
			my $chan = $info_href->{'tsid'}{$tsid}{'pr'}{$pnr} ;
			delete $tuning_href->{'pr'}{$chan} ;
		}

	}
	
	return $ok ;
}



#----------------------------------------------------------------------

=item B<merge($new_href, $old_href)>

Merge tuning information - overwrites previous with new - into $old_href and return
the HASH ref.

=cut

sub merge
{
	my ($new_href, $old_href, $scan_info_href) = @_ ;

print STDERR Data::Dumper->Dump(["merge - Scan info [$scan_info_href]=", $scan_info_href]) if $DEBUG>=5 ;

	$scan_info_href ||= {} ;

#	region: 'ts' => 
#		section: '4107' =>
#			field: name = Oxford/Bexley
#
	if ($old_href && $new_href)
	{
		foreach my $region (keys %FILES)
		{
			$old_href->{$region} ||= {} ;
			if (exists($new_href->{$region}))
			{
				foreach my $section (keys %{$new_href->{$region}})
				{
					foreach my $field (keys %{$new_href->{$region}{$section}})
					{
						$old_href->{$region}{$section}{$field} = $new_href->{$region}{$section}{$field} ; 
					}
				}
			}
		}
	}

	$old_href = $new_href if (!$old_href) ;
	
print STDERR Data::Dumper->Dump(["merge END - Scan info [$scan_info_href]=", $scan_info_href]) if $DEBUG>=5 ;

	return $old_href ;
}

#----------------------------------------------------------------------

=item B<merge_scan_freqs($new_href, $old_href, $verbose)>

Merge tuning information - checks to ensure new program info has the 
best strength, and that new program has all of it's settings

	'pr' => {
	      BBC ONE => 
	        {
	          pnr => 4171,
	          tsid => 4107,
	          lcn => 1,
	          ...
	        },
	     $chan => ...
	},
	'lcn' => { 
	      4107 => {
	      	4171 => {
		          service_type => 2,   
				  visible => 1,            
		          lcn => 46,               
		          ...
		        },
	        },
	        
	     $tsid => {
	     	$pnr => ...
	     }
	},
	'ts' => {
	      4107 =>
	        { 
	          tsid => 4107,   
			  frequency => 57800000,            
	          strength => 46829,               
	          ...
	        },
	     $tsid => ..
	},
	'freqs' => {
	      57800000 =>
	        { 
	          strength => 46829,               
	          snr => bbb,               
	          ber => ccc,               
	          ...
	        },
	      $freq => ...
	},



=cut


sub merge_scan_freqs
{
	my ($new_href, $old_href, $options_href, $verbose, $scan_info_href) = @_ ;

print STDERR Data::Dumper->Dump(["merge_scan_freqs - Scan info [$scan_info_href]=", $scan_info_href]) if $DEBUG>=5 ;

	$scan_info_href ||= {} ;
	$scan_info_href->{'chans'} ||= {} ;
	$scan_info_href->{'tsids'} ||= {} ;
	
print STDERR "merge_scan_freqs()\n" if $DEBUG ;

	if ($old_href && $new_href)
	{
print STDERR Data::Dumper->Dump(["New:", $new_href, "Old:", $old_href]) if $DEBUG>=2 ;
		
		## gather information on new & existing
		my %old_new_info ;
		$old_new_info{'new'} = _scan_info($new_href) ;
		$old_new_info{'old'} = _scan_info($old_href) ;
		
		## Copy special fields first
		my %fields = map {$_ => 1} @SCAN_INFO_FIELDS ;
		
		# ts
		delete $fields{'ts'} ;
		_merge_tsid($new_href, $old_href, $options_href, $verbose, $scan_info_href, \%old_new_info) ;
		
		# pr
		delete $fields{'pr'} ;
		_merge_chan($new_href, $old_href, $options_href, $verbose, $scan_info_href, \%old_new_info) ;
		
		# merge the rest
		foreach my $region (keys %fields)
		{
			foreach my $section (keys %{$new_href->{$region}})
			{
print STDERR " + Overwrite existing {$region}{$section} with new ....\n" if $DEBUG ;

				## Just overwrite
				foreach my $field (keys %{$new_href->{$region}{$section}})
				{
					$old_href->{$region}{$section}{$field} = $new_href->{$region}{$section}{$field} ; 
				}
			}
		}
	}

	$old_href = $new_href if (!$old_href) ;
	
print STDERR Data::Dumper->Dump(["merge_scan_freqs END - Scan info [$scan_info_href]=", $scan_info_href]) if $DEBUG>=5 ;
	
print STDERR "merge_scan_freqs() - DONE\n" if $DEBUG ;
	
	return $old_href ;
}

		
#----------------------------------------------------------------------
sub _merge_tsid
{
	my ($new_href, $old_href, $options_href, $verbose, $scan_info_href, $new_old_info_href) = @_ ;

	$scan_info_href->{'chans'} ||= {} ;
	$scan_info_href->{'tsids'} ||= {} ;
	
print STDERR "_merge_tsid()\n" if $DEBUG ;
print STDERR Data::Dumper->Dump(["_merge_tsid()", $new_href->{'ts'}]) if $DEBUG>=2 ;			


	## Compare new with old
	foreach my $tsid (keys %{$new_old_info_href->{'new'}{'tsid'}})
	{
		my $new_chans = scalar(keys %{$new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}}) ;
		my $old_chans = 0 ;

		my $new_strength_href = _strength_create($new_old_info_href->{'new'}{'tsid'}{$tsid}) ;
		my $old_strength_href = _strength_create(0) ;
#		my $new_strength = $new_old_info_href->{'new'}{'tsid'}{$tsid}{'strength'} ;
#		my $old_strength = 0 ;
		
		my $new_freq = $new_old_info_href->{'new'}{'tsid'}{$tsid}{'freq'} ;
		my $old_freq ;
	
		my $overlap = 0 ;
		if ( exists($new_old_info_href->{'old'}{'tsid'}{$tsid}) )
		{
			$overlap = 1 ;
			$old_chans = scalar(keys %{$new_old_info_href->{'old'}{'tsid'}{$tsid}{'pr'}}) ;
#			$old_strength = $new_old_info_href->{'old'}{'tsid'}{$tsid}{'strength'} ;
			$old_strength_href = _strength_create($new_old_info_href->{'old'}{'tsid'}{$tsid}) ;
			$old_freq = $new_old_info_href->{'old'}{'tsid'}{$tsid}{'freq'} ;
			
			if ($old_freq == $new_freq)
			{
				$overlap = 0 ;
			}
		}
		
		$scan_info_href->{'tsids'}{$tsid} ||= {
			'comments'	=> [],
		} ;
	
		my $delete = 0 ;
		my $duplicate = 0 ;
		my $reason = "" ;
		
		if (!$overlap)
		{
			$reason = "[merge] TSID $tsid : creating new freq $new_freq (contains $new_chans chans)" ;
		}
		else
		{
			## overlap - do something 
			if ($options_href->{'duplicates'})
			{
				$duplicate = 1 ;
				$reason = "[duplicate] TSID $tsid : tsid already exists (new freq $new_freq chans $new_chans, old freq $old_freq chans $old_chans), creating duplicate" ;
			}
			else
			{
				# do we overwrite based on number of channels a multiplex contains OR on the signal strength
				if (!$options_href->{'num_chans'} || ($new_chans == $old_chans))
				{

					# overwrite based on signal strength
##					if ($new_strength < $old_strength)
					if (_strength_cmp($new_strength_href, $old_strength_href) < 0)
					{
						my $new_strength_str = _strength_str($new_strength_href);
						my $old_strength_str = _strength_str($old_strength_href);

						$delete = 1 ;
#						$reason = "[overlap] TSID $tsid : new freq $new_freq strength $new_strength ($new_chans chans) < existing freq $old_freq strength $old_strength ($old_chans chans) - new freq ignored" ;
						$reason = "[overlap] TSID $tsid : new freq $new_freq strength $new_strength_str ($new_chans chans) < existing freq $old_freq strength $old_strength_str ($old_chans chans) - new freq ignored" ;
					}
					else
					{
						my $new_strength_str = _strength_str($new_strength_href);
						my $old_strength_str = _strength_str($old_strength_href);

#						$reason = "[overlap] TSID $tsid : new freq $new_freq strength $new_strength >= existing freq $old_freq strength $old_strength - using new freq" ;
						$reason = "[overlap] TSID $tsid : new freq $new_freq strength $new_strength_str ($new_chans chans) >= existing freq $old_freq strength $old_strength_str ($old_chans chans) - using new freq" ;
					}
				}
				
				# compare number of channels
				elsif ($new_chans < $old_chans)
				{
					$delete = 1 ;
					$reason = "[overlap] TSID $tsid : new freq $new_freq has only $new_chans chans (existing freq $old_freq has $old_chans chans) - new freq ignored" ;
				}
				else
				{
					$reason = "[overlap] TSID $tsid : new freq $new_freq has $new_chans chans (existing freq $old_freq has $old_chans chans) - using new freq" ;
				}
			}
		}	
	
		## delete if required
		if ($delete)
		{
			delete $new_href->{'ts'}{$tsid} ;
				
			foreach my $pnr (keys %{$new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}} )
			{
				my $chan = $new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}{$pnr} ;
				$scan_info_href->{'chans'}{$chan} ||= {
					'comments'	=> [],
				} ;
				push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, $reason ;
				
				delete $new_href->{'pr'}{$chan} ;
			}
		}
		## duplicate if required
		elsif ($duplicate)
		{
			## Create a dummy name for this tsid
			my $suffix = 'a' ;
			my $tsid_dup = "$tsid$suffix" ;
			while (exists($new_old_info_href->{'old'}{'tsid'}{$tsid_dup}))
			{
				++$suffix ;
				$tsid_dup = "$tsid$suffix" ;
			}
			$reason .= " TSID $tsid_dup" ;
			
			
			## rename tsid
			
			# ts
			my $tsid_href = delete $new_href->{'ts'}{$tsid} ;
			$new_href->{'ts'}{$tsid_dup} = $tsid_href ;
			$new_href->{'ts'}{$tsid_dup}{'tsid'} = $tsid_dup ;
				
			# pr
			foreach my $pnr (keys %{$new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}} )
			{
				my $chan = $new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}{$pnr} ;
				$scan_info_href->{'chans'}{$chan} ||= {
					'comments'	=> [],
				} ;
				push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, $reason ;
				
				$new_href->{'pr'}{$chan}{'tsid'} = $tsid_dup ;
			}
			
			# lcn
			my $lcn_href = delete $new_href->{'lcn'}{$tsid} ;
			$new_href->{'lcn'}{$tsid_dup} = $lcn_href ;

			## rename chan
			
			# pr
			foreach my $pnr (keys %{$new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}} )
			{
				my $chan = $new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}{$pnr} ;

				my $count = 1 ;
				my $chan_dup = "$chan ($count)";
				while (exists($new_old_info_href->{'old'}{'pr'}{$chan_dup}))
				{
					++$count ;
					$chan_dup = "$chan ($count)";
				}
				
				push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, "[duplicate] Renamed $chan to $chan_dup" ;
				
				my $chan_href = delete $new_href->{'pr'}{$chan} ;
				$new_href->{'pr'}{$chan_dup} = $chan_href  ;
				$new_href->{'pr'}{$chan_dup}{'name'} = $chan_dup  ;
			}
			

print STDERR " + duplicate TSID\n" if $DEBUG ;
print STDERR Data::Dumper->Dump(["After tsid rename ", $new_href]) if $DEBUG>=2 ;			
			
		}
		else
		{
			## ok to copy
			foreach my $pnr (keys %{$new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}} )
			{
				my $chan = $new_old_info_href->{'new'}{'tsid'}{$tsid}{'pr'}{$pnr} ;
				$scan_info_href->{'chans'}{$chan} ||= {
					'comments'	=> [],
				} ;
				push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, $reason ;
			}
		}

		# update TSID debug info
		push @{$scan_info_href->{'tsids'}{$tsid}{'comments'}}, $reason ;
	}
		
	## Do merge
	foreach my $tsid (keys %{$new_href->{'ts'}})
	{
		## Just overwrite
		foreach my $field (keys %{$new_href->{'ts'}{$tsid}})
		{
			$old_href->{'ts'}{$tsid}{$field} = $new_href->{'ts'}{$tsid}{$field} ; 
		}
	}

}


#----------------------------------------------------------------------
sub _merge_chan
{
	my ($new_href, $old_href, $options_href, $verbose, $scan_info_href, $new_old_info_href) = @_ ;

	$scan_info_href->{'chans'} ||= {} ;
	$scan_info_href->{'tsids'} ||= {} ;
	
print STDERR "_merge_chan()\n" if $DEBUG ;
print STDERR Data::Dumper->Dump(["_merge_chan()", $new_href->{'pr'}]) if $DEBUG>=2 ;			
		
	## Do merge
	foreach my $chan (keys %{$new_href->{'pr'}})
	{
		## Check for channel rename
		my $tsid = $new_href->{'pr'}{$chan}{'tsid'} ;
		my $pnr = $new_href->{'pr'}{$chan}{'pnr'} ;

print STDERR " + check {$tsid-$pnr} = $chan \n" if $DEBUG ;
					
		if (exists($new_old_info_href->{'old'}{'tsid-pnr'}{"$tsid-$pnr"}) && ($new_old_info_href->{'old'}{'tsid-pnr'}{"$tsid-$pnr"} ne $chan))
		{
			# Rename
			my $old_chan = $new_old_info_href->{'old'}{'tsid-pnr'}{"$tsid-$pnr"} ;
			push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, "[merge] channel renamed from \"$old_chan\" to \"$chan\" " ;
			delete $old_href->{'pr'}{$old_chan} ;											
print STDERR " + + delete $old_chan \n" if $DEBUG ;
		}

		## Check for channel TSID change
		my $overlap = 0 ;
		if (exists($old_href->{'pr'}{$chan}))
		{
			$overlap = 1 ;
			if ($new_href->{'pr'}{$chan}{'tsid'} eq $old_href->{'pr'}{$chan}{'tsid'})
			{
				$overlap = 0 ;
			}
		}
				
		$scan_info_href->{'chans'}{$chan} ||= {
			'comments'	=> [],
		} ;
			
		my $reason ;
		my $copy_chan = $chan ;
		if (!$overlap)
		{
			$reason = "[merge] creating new channel info" ;
		}
		else
		{
			## overlap - do something 
			if ($options_href->{'duplicates'})
			{
				# duplicate
				$reason = "[duplicate] Channel $chan already exists (new TSID $new_href->{'pr'}{$chan}{'tsid'}, old TSID $old_href->{'pr'}{$chan}{'tsid'}), creating duplicate" ;
			

				my $count = 1 ;
				$copy_chan = "$chan ($count)";
				while (exists($old_href->{'pr'}{$copy_chan}))
				{
					++$count ;
					$copy_chan = "$chan ($count)";
				}
				
				$reason .= " New channel name $copy_chan" ;
			}
			else
			{
				# overwrite
				$reason = "[overlap] overwriting existing channel info with new (old: TSID $old_href->{'pr'}{$chan}{tsid})" ;
			}
		}
		push @{$scan_info_href->{'chans'}{$chan}{'comments'}}, $reason ;

			
		## Now overwrite
		foreach my $field (keys %{$new_href->{'pr'}{$chan}})
		{
			$old_href->{'pr'}{$copy_chan}{$field} = $new_href->{'pr'}{$chan}{$field} ; 
		}
		$old_href->{'pr'}{$copy_chan}{'name'} = $copy_chan ;
	}

}




#----------------------------------------------------------------------
sub _scan_info
{
	my ($scan_href) = @_ ;
	
	## Get info on existing
	my %tsid_map ;
	foreach my $chan (keys %{$scan_href->{'pr'}})
	{
		my $tsid = $scan_href->{'pr'}{$chan}{'tsid'} ;
		my $pnr = $scan_href->{'pr'}{$chan}{'pnr'} ;
		$tsid_map{"$tsid-$pnr"} = $chan ;
	}
		
	## Various ways of looking at tsid info
	my %ts_info ;
	foreach my $tsid (keys %{$scan_href->{'ts'}})
	{
		my $freq = $scan_href->{'ts'}{$tsid}{'frequency'} ;
		$ts_info{$tsid} = {
			'pr'		=> {},
			'freq'		=> $scan_href->{'ts'}{$tsid}{'frequency'},
			'strength'	=> $scan_href->{'ts'}{$tsid}{'strength'},
			'snr'	=> $scan_href->{'ts'}{$tsid}{'snr'},
			'ber'	=> $scan_href->{'ts'}{$tsid}{'ber'},
		} ;
	}
	foreach my $chan (keys %{$scan_href->{'pr'}})
	{
		my $tsid = $scan_href->{'pr'}{$chan}{'tsid'} ;
		my $pnr = $scan_href->{'pr'}{$chan}{'pnr'} ;
		$ts_info{$tsid}{'pr'}{$pnr} = $chan ;
	}
			
	
	## Various ways of looking at channel info
	my %chan_info ;
	foreach my $chan (keys %{$scan_href->{'pr'}})
	{
		my $tsid = $scan_href->{'pr'}{$chan}{'tsid'} ;
		$chan_info{$chan} = $tsid ;
	}
	
	my %info = (
		'tsid-pnr'	=> \%tsid_map,
		'tsid'		=> \%ts_info,
		'chan'		=> \%chan_info,
	) ;
	return \%info ;
}




#----------------------------------------------------------------------
# Split the search path & expand all the directories to absolute paths
#
sub _expand_search_path
{
	my ($search_path) = @_ ;

	my @dirs = split /:/, $search_path ;
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

=item B<read_dir($search_path)>

Find directory to read from - first readable directory in search path

=cut

sub read_dir
{
	my ($search_path) = @_ ;
	
	my @dirs = _expand_search_path($search_path) ;
	my $dir ;
	
	foreach my $d (@dirs)
	{
		my $found=1 ;
		foreach my $region (keys %FILES)
		{
			if ($FILES{$region}{'required'})
			{
				$found=0 if (! -f  "$d/$FILES{$region}{'file'}") ;
			}
		}
		
		if ($found)
		{
			$dir = $d ;
			last ;
		}
	}

	print STDERR "Searched $search_path : read dir=".($dir?$dir:"")."\n" if $DEBUG ;
		
	return $dir ;
}

#----------------------------------------------------------------------

=item B<write_dir($search_path)>

Find directory to write to - first writeable directory in search path

=cut

sub write_dir
{
	my ($search_path) = @_ ;

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
			foreach my $region (keys %FILES)
			{
				if (open my $fh, ">>$d/$FILES{$region}{'file'}")
				{
					close $fh ;

					print STDERR " + + Write to $d/$FILES{$region}{'file'} succeded\n" if $DEBUG ;
				}
				else
				{
					print STDERR " + + Unable to write to $d/$FILES{$region}{'file'} - aborting this dir\n" if $DEBUG ;

					$found = 0;
					last ;
				}
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


#============================================================================================

=back

=head3 TSID config file (dvb-ts) read/write

=over 4

=cut


#----------------------------------------------------------------------

=item B<read_dvb_ts($fname)>

Read the transponder settings file of the form:

	[4107]
	name = Oxford/Bexley
	frequency = 578000000
	bandwidth = 8
	modulation = 16
	hierarchy = 0
	code_rate_high = 34
	code_rate_low = 34
	guard_interval = 32
	transmission = 2
	
=cut

sub read_dvb_ts
{
	my ($fname) = @_ ;

	my %dvb_ts ;
	open my $fh, "<$fname" or die "Error: Unable to read $fname : $!" ;
	
	my $line ;
	my $tsid ;
	while(defined($line=<$fh>))
	{
		chomp $line ;
		next if $line =~ /^\s*#/ ; # skip comments
		 
		if ($line =~ /\[([\da-z]+)\]/i)
		{
			$tsid=$1;
		}
		elsif ($line =~ /(\S+)\s*=\s*(\S+)/)
		{
			if ($tsid)
			{
				$dvb_ts{$tsid}{$1} = $2 ;
			}
		}
		elsif ($line =~ /(\S+)\s*=/)
		{
			# skip empty entries
		}
		else
		{
			$tsid = undef ;
		}
	}	
	close $fh ;
	
	return \%dvb_ts ;
}

#----------------------------------------------------------------------

=item B<read_dvb_ts_freqs($fname)>

Read the transponder settings file comments section, if present, containing the
frequency file information used during the scan. The values are in "VDR" format:

	# VDR freq      bw   fec_hi fec_lo mod   transmission-mode guard-interval hierarchy inversion

For example, the frequency file format:

	# T 578000000 8MHz 2/3    NONE   QAM64 2k                1/32           NONE
	
will be saved as:	
	
	# VDR 578000000 8  23     0      64    2                 32             0			0

=cut

sub read_dvb_ts_freqs
{
	my ($fname) = @_ ;

print STDERR "read_dvb_ts_freqs($fname)\n" if $DEBUG>=5 ;

	my %dvb_ts_freqs = () ;
	open my $fh, "<$fname" or die "Error: Unable to read $fname : $!" ;
	
	my $line ;
	while(defined($line=<$fh>))
	{
		chomp $line ;
		next unless $line =~ /^\s*#/ ; # skip non-comments
		
print STDERR " + line $line\n" if $DEBUG>=5 ;

		## Parse line
		if ($line =~ m%^\s*#\s*VDR\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%i)
		{
			my $freq = Linux::DVB::DVBT::dvb_round_freq($1) ;
			
			if (exists($dvb_ts_freqs{$freq}))
			{
				print STDERR "Note: frequency $freq Hz already seen, skipping\n" ;
				next ;
			}

print STDERR " + + add $freq\n" if $DEBUG>=5 ;

			$dvb_ts_freqs{$freq} = {
				frequency => $freq,
				bandwidth => $2,
				code_rate_high => $3,
				code_rate_low => $4,
				modulation => $5,
				transmission => $6,
				guard_interval => $7,
				hierarchy => $8,
				inversion => $9,
			} ;
		}		
		 
	}	
	close $fh ;

print STDERR Data::Dumper->Dump(["read_dvb_ts_freqs - href=", \%dvb_ts_freqs]) if $DEBUG>=5 ;
	
	return \%dvb_ts_freqs ;
}


#----------------------------------------------------------------------

=item B<write_dvb_ts($fname, $href)>

Write transponder config information

=cut

sub write_dvb_ts
{
	my ($fname, $href, $freqs_href) = @_ ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;

print STDERR Data::Dumper->Dump(["write_dvb_ts - href=", $href, "freqs=", $freqs_href]) if $DEBUG>=5 ;
	
	## Save frequency list first (if available)
	if ($freqs_href && (keys %$freqs_href))
	{
		#		# VDR freq      bw   fec_hi fec_lo mod   transmission-mode guard-interval hierarchy inversion
		#	
		#		# VDR 578000000 8    23     0      64    2                 32             0         0 
		#
		print $fh "##    freq bw fec_hi fec_lo mod transmission-mode guard-interval hierarchy inversion\n" ;
		foreach my $freq (sort {$a <=> $b} keys %$freqs_href)
		{
			my $tuning_href = $freqs_href->{$freq} ;
			print $fh "# VDR " ;
			foreach my $field (qw/
				frequency
				bandwidth
				code_rate_high
				code_rate_low
				modulation
				transmission
				guard_interval
				hierarchy
				inversion
			/)
			{
				printf $fh "%d ", $tuning_href->{$field} ;
			}
			print $fh "\n" ;
		}
	}
	
	# Write config information
	#
	#	'ts' => 
	#	      4107 =>
	#	        { # HASH(0x83241b8)
	#	          bandwidth => 8,
	#	          code_rate_hp => 34,         code_rate_high
	#	          code_rate_lp => 34,         code_rate_low
	#	          constellation => 16,        modulation
	#	          frequency => 578000000,
	#	          guard => 32,                guard_interval
	#	          hierarchy => 0,
	#	          net => Oxford/Bexley,
	#	          transmission => 2,
	#	          tsid => 4107,               
	#	        },
	#	
	#[4107]
	#name = Oxford/Bexley
	#frequency = 578000000
	#bandwidth = 8
	#modulation = 16
	#hierarchy = 0
	#code_rate_high = 34
	#code_rate_low = 34
	#guard_interval = 32
	#transmission = 2
	#
	#
	foreach my $section (sort {$a <=> $b} keys %$href)
	{
		print $fh "[$section]\n" ;
		foreach my $field (sort keys %{$href->{$section}})
		{
			my $val = $href->{$section}{$field} ;
			if ($val =~ /\S+/)
			{
				print $fh "$field = $val\n" ;
			} 
		}
		print $fh "\n" ;
	}
	
	close $fh ;
}


#============================================================================================

=back

=head3 Channels config file (dvb-pr) read/write

=over 4

=cut


#----------------------------------------------------------------------

=item B<read_dvb_pr($fname)>

Read dvb-pr - channel information - of the form:
	
	[4107-4171]
	video = 600
	audio = 601
	audio_details = eng:601 eng:602
	type = 1
	net = BBC
	name = BBC ONE

=cut

sub read_dvb_pr
{
	my ($fname) = @_ ;

	my %dvb_pr ;
	open my $fh, "<$fname" or die "Error: Unable to read $fname : $!"  ;
	
	my $line ;
	my $pnr ;
	my $tsid ;
	while(defined($line=<$fh>))
	{
		chomp $line ;
		next if $line =~ /^\s*#/ ; # skip comments
		 
		if ($line =~ /\[([\da-z]+)\-([\d]+)\]/i)
		{
			($tsid, $pnr)=($1,$2);
		}
		elsif ($line =~ /(\S+)\s*=\s*(\S+.*)/)
		{
			if ($pnr && $tsid)
			{
				$dvb_pr{"$tsid-$pnr"}{$1} = $2 ;
				
				# ensure tsid & pnr are in the hash
				$dvb_pr{"$tsid-$pnr"}{'tsid'} = $tsid ;
				$dvb_pr{"$tsid-$pnr"}{'pnr'} = $pnr ;
			}
		}
		elsif ($line =~ /(\S+)\s*=/)
		{
			# skip empty entries
		}
		else
		{
			$pnr = undef ;
			$tsid = undef ;
		}
	}	
	close $fh ;
	
	# Make channel name the first key
	my %chans ;
	foreach (keys %dvb_pr)
	{
		# handle chans with no name
		my $name = $dvb_pr{$_}{'name'} || $_ ; 
		$chans{$name} = $dvb_pr{$_} ; 
	}
	
	return \%chans ;
}

#----------------------------------------------------------------------

=item B<write_dvb_pr($fname, $href)>

Write program config file.

=cut

sub write_dvb_pr
{
	my ($fname, $href) = @_ ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;
	
	# Write config information
	#
	#	'pr' =>
	#	      BBC ONE => 
	#	        { # HASH(0x8327848)
	#	          a_pid => 601,                   audio
	#	          audio => eng:601 eng:602,       audio_details
	#	          ca => 0,
	#	          name => "BBC ONE",
	#	          net => BBC,
	#	          p_pid => 4171,                  -N/A-
	#	          pnr => 4171,
	#	          running => 4,
	#	          t_pid => 0,                     teletext
	#	          tsid => 4107,
	#	          type => 1,
	#	          v_pid => 600,                   video
	#	          version => 26,                  -N/A-
	#	        },
	#
	#[4107-4171]
	#video = 600
	#audio = 601
	#audio_details = eng:601 eng:602
	#type = 1
	#net = BBC
	#name = BBC ONE
	#
	foreach my $section (sort {
		$href->{$a}{'tsid'} <=> $href->{$b}{'tsid'}
		||
		$href->{$a}{'pnr'} <=> $href->{$b}{'pnr'}
	} keys %$href)
	{
		print $fh "[$href->{$section}{tsid}-$href->{$section}{pnr}]\n" ;
		foreach my $field (sort keys %{$href->{$section}})
		{
			my $val = $href->{$section}{$field} ;
			if ($val =~ /\S+/)
			{
				print $fh "$field = $val\n" ;
			} 
		}
		print $fh "\n" ;
	}
	
	close $fh ;
}


#============================================================================================

=back

=head3 Channel names aliases config file (dvb-aliases) read/write

=over 4

=cut

#----------------------------------------------------------------------

=item B<read_dvb_aliases($fname)>

Read dvb-aliases - channel names aliases - of the form:
	
	FIVE = Channel 5

=cut

sub read_dvb_aliases
{
	my ($fname) = @_ ;

	my %dvb_aliases ;

#print STDERR "read_dvb_aliases($fname)\n" ;

	if (-f $fname)
	{
		open my $fh, "<$fname" or die "Error: Unable to read $fname : $!"  ;
		
		my $line ;
		while(defined($line=<$fh>))
		{
			chomp $line ;
			next if $line =~ /^\s*#/ ; # skip comments
			$line =~ s/\s+$// ;
			$line =~ s/^\s+// ;
#	print STDERR "!! $line !!\n" ;

			if ($line =~ /(\S+[^=]+)\s*=\s*(\S+[^=]+)\s*/)
			{
				my ($from, $to) = ($1, $2) ;
				
				$from =~ s/\s+$// ;
				
				$dvb_aliases{$from} = $to ;
#	print STDERR " + <$from> = <$to>\n" ;
			}
		}	
		close $fh ;
	
	}
#print STDERR "read_dvb_aliases - done\n" ;
	
	return \%dvb_aliases ;
}


#----------------------------------------------------------------------

=item B<write_dvb_aliases($fname, $href)>

Write channel names aliases config file.

=cut

sub write_dvb_aliases
{
	my ($fname, $href) = @_ ;

	open my $fh, ">$fname" or die "Error: Unable to write $fname : $!" ;
	
	# Write config information
	#
	#	'aliases' =>
	#	      "FIVE" => "Channel 5"
	#
	#   FIVE = Channel 5
	#
	foreach my $from (sort keys %$href)
	{
		my $val = $href->{$from} ;
		if ($val =~ /\S+/)
		{
			print $fh "$from = $val\n" ;
		} 
	}
	
	close $fh ;
}


#============================================================================================

# TSID strength/snr/ber

#----------------------------------------------------------------------
sub _strength_create
{
	my ($href) = @_ ;

	my $strength_href = {
		'strength'	=> 0,
		'snr'		=> 0,
		'ber'		=> undef,
		
		'use'		=> undef,
	} ;

print STDERR "_strength_create()\n" if $DEBUG ;

	if (ref($href) eq 'HASH')
	{
		foreach my $field (qw/strength snr ber/)
		{
print STDERR " + $field = $href->{$field}\n" if $DEBUG ;

			$strength_href->{$field} = $href->{$field} if exists($href->{$field}) ;

			# Handle special case where value reads back as all 1's
			if ($strength_href->{$field} == 0xffff)
			{
print STDERR " + + clamped dodgy value\n" if $DEBUG ;

				# treat it as a bad value
				$strength_href->{$field} = 0 ;
			}
		}
		
#		# Handle special case where strength reads back as all 1's
#		if ($strength_href->{'strength'} == 0xffff)
#		{
#			# treat it as a bad value
#			$strength_href->{'strength'} = 0 ;
#		}
	}
	
	return $strength_href ;
}


#----------------------------------------------------------------------
sub _strength_cmp
{
	my ($a_href, $b_href) = @_ ;

	## Work through the fields in order of preference
	my $use ;
	foreach my $field (qw/snr strength ber/)
	{
		if (defined($a_href->{$field}) && defined($b_href->{$field}) && ($a_href->{$field} > 0) && ($a_href->{$field} > 0))
		{
			$use = $field ;
			last ;
		}
	}

print STDERR "_strength_cmp()\n" if $DEBUG ;
	
	$use ||= 'strength' ;
	$a_href->{'use'} = $use ;
	$b_href->{'use'} = $use ;

	my $a_val = $a_href->{$use} ;
	my $b_val = $b_href->{$use} ;
	if ($use eq 'ber')
	{
		$a_val = 0xffff - $a_val ;
		$b_val = 0xffff - $b_val ;
	}

print STDERR " + using $use - $a_val <=> $b_val\n" if $DEBUG ;
	
	return $a_val <=> $b_val ;
}

#----------------------------------------------------------------------
sub _strength_str
{
	my ($href) = @_ ;

	my $str = "unset" ;
	if ($href->{'use'})
	{
		$str = "$href->{$href->{use}} ($href->{use})" ;
	}
	return $str ;
}

# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

