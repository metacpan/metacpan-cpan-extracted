package Linux::DVB::DVBT::Utils ;

=head1 NAME

Linux::DVB::DVBT::Utils - DVBT utilities 

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Utils ;
  

=head1 DESCRIPTION

Module provides a set of useful miscellaneous utility routines used by the DVBT module. You may use them in your own scripts
if you wish to (I mainly use the time coversion functions in my scripts).

=cut


use strict ;

our $VERSION = '2.07' ;
our $DEBUG = 0 ;

our %CONTENT_DESC = (
    0x10 => "Film|movie/drama (general)",
    0x11 => "Film|detective/thriller",
    0x12 => "Film|adventure/western/war",
    0x13 => "Film|science fiction/fantasy/horror",
    0x14 => "Film|comedy",
    0x15 => "Film|soap/melodrama/folkloric",
    0x16 => "Film|romance",
    0x17 => "Film|serious/classical/religious/historical movie/drama",
    0x18 => "Film|adult movie/drama",

    0x20 => "News|news/current affairs (general)",
    0x21 => "News|news/weather report",
    0x22 => "News|news magazine",
    0x23 => "News|documentary",
    0x24 => "News|discussion/interview/debate",

    0x30 => "Show|show/game show (general)",
    0x31 => "Show|game show/quiz/contest",
    0x32 => "Show|variety show",
    0x33 => "Show|talk show",

    0x40 => "Sports|sports (general)",
    0x41 => "Sports|special events (Olympic Games, World Cup etc.)",
    0x42 => "Sports|sports magazines",
    0x43 => "Sports|football/soccer",
    0x44 => "Sports|tennis/squash",
    0x45 => "Sports|team sports (excluding football)",
    0x46 => "Sports|athletics",
    0x47 => "Sports|motor sport",
    0x48 => "Sports|water sport",
    0x49 => "Sports|winter sports",
    0x4A => "Sports|equestrian",
    0x4B => "Sports|martial sports",

    0x50 => "Children|children's/youth programmes (general)",
    0x51 => "Children|pre-school children's programmes",
    0x52 => "Children|entertainment programmes for 6 to 14",
    0x53 => "Children|entertainment programmes for 10 to 16",
    0x54 => "Children|informational/educational/school programmes",
    0x55 => "Children|cartoons/puppets",

    0x60 => "Music|music/ballet/dance (general)",
    0x61 => "Music|rock/pop",
    0x62 => "Music|serious music/classical music",
    0x63 => "Music|folk/traditional music",
    0x64 => "Music|jazz",
    0x65 => "Music|musical/opera",
    0x66 => "Music|ballet",

    0x70 => "Arts|arts/culture (without music, general)",
    0x71 => "Arts|performing arts",
    0x72 => "Arts|fine arts",
    0x73 => "Arts|religion",
    0x74 => "Arts|popular culture/traditional arts",
    0x75 => "Arts|literature",
    0x76 => "Arts|film/cinema",
    0x77 => "Arts|experimental film/video",
    0x78 => "Arts|broadcasting/press",
    0x79 => "Arts|new media",
    0x7A => "Arts|arts/culture magazines",
    0x7B => "Arts|fashion",

    0x80 => "Social|social/political issues/economics (general)",
    0x81 => "Social|magazines/reports/documentary",
    0x82 => "Social|economics/social advisory",
    0x83 => "Social|remarkable people",

    0x90 => "Education|education/science/factual topics (general)",
    0x91 => "Education|nature/animals/environment",
    0x92 => "Education|technology/natural sciences",
    0x93 => "Education|medicine/physiology/psychology",
    0x94 => "Education|foreign countries/expeditions",
    0x95 => "Education|social/spiritual sciences",
    0x96 => "Education|further education",
    0x97 => "Education|languages",

    0xA0 => "Leisure|leisure hobbies (general)",
    0xA1 => "Leisure|tourism/travel",
    0xA2 => "Leisure|handicraft",
    0xA3 => "Leisure|motoring",
    0xA4 => "Leisure|fitness & health",
    0xA5 => "Leisure|cooking",
    0xA6 => "Leisure|advertizement/shopping",
    0xA7 => "Leisure|gardening",

    0xB0 => "Special|original language",
    0xB1 => "Special|black & white",
    0xB2 => "Special|unpublished",
    0xB3 => "Special|live broadcast",
);

our %AUDIO_FLAGS = (
  'AD' => 'is_audio_described',
  'S'  => 'is_subtitled',
  'SL' => 'is_deaf_signed',
);

our %CHAR_TRANSLATE ;

#============================================================================================
BEGIN {
	
	foreach my $cc (0..255)
	{
		my $chr = chr $cc ;
		my $xlt = $chr ;
		if (($cc < ord(' ')) || ($cc > ord('~') ))
		{
			$xlt = '' ;
		}
		$CHAR_TRANSLATE{$chr} = $xlt ;
	}
	
	$CHAR_TRANSLATE{"\n"} = ' ' ;
}


#============================================================================================

=head2 Functions

=over 4

=cut




#-----------------------------------------------------------------------------

=item B<time2mins($time)>

Convert time (in HH:MM format) into minutes

=cut

sub time2mins
{
	my ($time) = @_ ;
	my $mins=0;
	if ($time =~ m/(\d+)\:(\d+)/)
	{
		$mins = 60*$1 + $2 ;
	}
	return $mins ;
}

#-----------------------------------------------------------------------------

=item B<mins2time($mins)>

Convert minutes into time (in HH:MM format)

=cut

sub mins2time
{
	my ($mins) = @_ ;
	my $hours = int($mins/60) ;
	$mins = $mins % 60 ;
	my $time = sprintf "%02d:%02d", $hours, $mins ;
	return $time ;
}

#-----------------------------------------------------------------------------

=item B<secs2time($secs)>

Convert seconds into time (in HH:MM:SS format)

=cut

sub secs2time
{
	my ($secs) = @_ ;
	
	my $mins = int($secs/60) ;
	$secs = $secs % 60 ;
	
	my $hours = int($mins/60) ;
	$mins = $mins % 60 ;
	
	my $time = sprintf "%02d:%02d:%02d", $hours, $mins, $secs ;
	return $time ;
}



#-----------------------------------------------------------------------------

=item B<duration($start, $end)>

Calculate duration in minutes between start and end times (in HH:MM format)

=cut

sub duration
{
	my ($start, $end) = @_ ;
	my $start_mins = time2mins($start) ;
	my $end_mins = time2mins($end) ;
	$end_mins += 24*60 if ($end_mins < $start_mins) ;
	my $duration_mins = $end_mins - $start_mins ;
	my $duration = mins2time($duration_mins) ;

#print STDERR "duration($start ($start_mins), $end ($end_mins)) = $duration ($duration_mins)\n" if $this->debug() ;

	return $duration ;
}

#-----------------------------------------------------------------------------

=item B<time2secs($time)>

Convert time (in HH:MM, HH:MM:SS, or MM format) into seconds

=cut

sub time2secs
{
	my ($time) = @_ ;
	
	# Default to 30mins
	my $seconds = 30*60 ;
	
	# Convert duration to seconds
	if ($time =~ m/^(\d+)$/)
	{
		$seconds = 60 * $1 ;
	}
	elsif ($time =~ m/^(\d+):(\d+):(\d+)$/)
	{
		$seconds = (60*60 * $1) + (60 * $2) + $3 ;
	}
	elsif ($time =~ m/^(\d+):(\d+)$/)
	{
		$seconds = (60*60 * $1) + (60 * $2) ;
	}
	return $seconds ;
}

#-----------------------------------------------------------------------------

=item B<timesec2secs($time)>

Convert time (in HH:MM, HH:MM:SS, or SS format) into seconds

(i.e. if integer value is specified, treat it as a time in seconds rather than minutes)

=cut

sub timesec2secs
{
	my ($time) = @_ ;
	
	# Default to 30mins
	my $seconds = 30*60 ;
	
	# Convert duration to seconds
	if ($time =~ m/^(\d+)$/)
	{
		$seconds = $1 ;
	}
	elsif ($time =~ m/^(\d+):(\d+):(\d+)$/)
	{
		$seconds = (60*60 * $1) + (60 * $2) + $3 ;
	}
	elsif ($time =~ m/^(\d+):(\d+)$/)
	{
		$seconds = (60*60 * $1) + (60 * $2) ;
	}
	return $seconds ;
}

#============================================================================================

=back

=head2 EPG Functions

=over 4

=cut


#-----------------------------------------------------------------------------

=item B<text($text)>

(Used by EPG function)

Ensure text returned by epg() is formatted as text.

=cut

sub text
{
	my ($text) = @_ ;

	if ($text)
	{
		## if text starts with non-ascii then assume it is encrypted and skip it
		if ($text =~ /^\\x([\da-fA-F]{2})/)
		{
			my $cc = hex $1 ;
			if ( ($cc < 0x20) || ($cc > 0x7e) )
			{
				return "" ;
			}
		}
		
		$text =~ s/\\x([\da-fA-F]{2})/$CHAR_TRANSLATE{chr hex $1}/ge ;

		# remove newlines
		$text =~ s/[\r\n]/ /g ;
		# replace multiple whitespace
		$text =~ s/\s+/ /g ;
		# remove leading space
		$text =~ s/^\s+//g ;
		# remove trailing space
		$text =~ s/\s+$//g ;
	}	
	return $text ;
}

#-----------------------------------------------------------------------------

=item B<genre($cat)>

(Used by EPG function)

Convert category code into genre string.

=cut

sub genre
{
	my ($cat) = @_ ;

	my $genre = "" ;
	if ($cat && exists($CONTENT_DESC{$cat}))
	{
		$genre = $CONTENT_DESC{$cat} ;
	}
		
	return $genre ;
}



#-----------------------------------------------------------------------------
# Usually run in the order:
#
#		fix_title(\$title, \$synopsis) ;
#		fix_synopsis(\$title, \$synopsis, \$new_program) ;
#		fix_episodes(\$title, \$synopsis, \$episode, \$num_episodes) ;
#		fix_audio(\$title, \$synopsis, \%flags) ;
#		subtitle(\$synopsis, \$subtitle) ;


=item B<fix_title($title_ref, $synopsis_ref)>

(Used by EPG function)

Fix title when title is truncated by ellipses and the synopsis continues the title.

For example:

	title = Julian Fellowes Investigates...
	synopsis = ...a Most Mysterious Murder. The Case of xxxx
	
Returns:

	title = Julian Fellowes Investigates a Most Mysterious Murder. 
	synopsis = The Case of xxxx

=cut

sub fix_title
{
	my ($title_ref, $synopsis_ref) = @_ ;

	return unless ($$title_ref && $$synopsis_ref) ;

print STDERR "fix_title(title=\"$$title_ref\", synopsis=\"$$synopsis_ref\")\n" if $DEBUG ;

	# fix title when title is 'Julian Fellowes Investigates...'
	# and synopsis is '...a Most Mysterious Murder. The Case of xxxxx'
	if ($$synopsis_ref =~ s/^\.\.\.\s?//) 
	{
		# remove trailing ... from title		
		$$title_ref =~ s/\.\.\.//;
		
		# synopsis = 'a Most Mysterious Murder. The Case of xxxxx'
		# match = 'a Most Mysterious Murder'
		# new synopsis = 'The Case of xxxxx'
		$$synopsis_ref =~ s/^(.+?)\. //;
		if ($1) 
		{
			# new title = 'Julian Fellowes Investigates a Most Mysterious Murder'
			$$title_ref .= ' ' . $1;
			
			# remove duplicate spaces
			$$title_ref =~ s/ {2,}/ /;
		}
	}

	# Followed by ...
	$$synopsis_ref =~ s/Followed by .*// ;
	
	# Strip leading/trailing space
	$$title_ref =~ s/^\s+// ;
	$$title_ref =~ s/\s+$// ;
	$$synopsis_ref =~ s/^\s+// ;
	$$synopsis_ref =~ s/\s+$// ;
	
	
print STDERR "fix_title() - END title=\"$$title_ref\", synopsis=\"$$synopsis_ref\"\n" if $DEBUG ;
}

#-----------------------------------------------------------------------------

=item B<fix_synopsis($title_ref, $synopsis_ref, $new_prog_ref)>

(Used by EPG function)

Checks the synopsis for any indication that this is a new program/series.

Examples of supported new program indication are:

	New.
	Brand new ****.
	All new ****.

Also removes extraneous information like:

	Also in HD.

=cut

sub fix_synopsis
{
	my ($title_ref, $synopsis_ref, $new_prog_ref) = @_ ;

	$$synopsis_ref ||= "" ;
	$$new_prog_ref ||= 0 ;

print STDERR "fix_synopsis(title=\"$$title_ref\", synopsis=\"$$synopsis_ref\")\n" if $DEBUG ;

	# Examples:
	
	# All New!
	# Brand new series.
	# New.
	# New:
	if ($$synopsis_ref =~ s%^\s*(all\s+|brand\s+){0,1}new(\s+\S+){0,1}\s*([\.\!\:\-]+\s*)%%i) 
	{
		$$new_prog_ref = 1 ;
	}
	
	# Also in HD.
	$$synopsis_ref =~ s%\s*Also in HD[\.\s]*%%i ;

	# Strip leading/trailing space
	$$synopsis_ref =~ s/^\s+// ;
	$$synopsis_ref =~ s/\s+$// ;

print STDERR "fix_synopsis() - END title=\"$$title_ref\", synopsis=\"$$synopsis_ref\", newprog=$$new_prog_ref\n" if $DEBUG ;
}




#-----------------------------------------------------------------------------

=item B<fix_episodes($title_ref, $synopsis_ref, $episode_ref, $num_episodes_ref)>

(Used by EPG function)

Checks the synopsis for mention of episodes and removes this information if found (setting
the $episode_ref and $num_episodes_ref refs accordingly).

Examples of supported episode descriptions are:

	(part 1 of 7)
	1/7
	Episode 1 of 7

=cut

sub fix_episodes
{
	my ($title_ref, $synopsis_ref, $episode_ref, $num_episodes_ref) = @_ ;

	$$synopsis_ref ||= "" ;

print STDERR "fix_episodes(title=\"$$title_ref\", synopsis=\"$$synopsis_ref\")\n" if $DEBUG ;

	# optional ()
	# optional ending .
	#			
	# "(XXX 1 of 7)"
	# "1/7"
	# "Episode 1 of 7."
	# "Part 1 of 7."
	# "(1/7)."
	
	#                        (*   word*  dig        /|\|of     dig    :.)*
	if ($$synopsis_ref =~ s%\(*\s*\w*\s*(\d+)\s*(?:/|\\|of)\s*(\d+)[\:\.\s\)]*%%i) 
	{
		$$episode_ref = $1;
		$$num_episodes_ref = $2;
	}

	# Strip leading/trailing space
	$$synopsis_ref =~ s/^\s+// ;
	$$synopsis_ref =~ s/\s+$// ;
						
print STDERR "fix_episodes() - END title=\"$$title_ref\", synopsis=\"$$synopsis_ref\", episode=$$episode_ref, num_episodes_ref=$$num_episodes_ref\n" if $DEBUG ;
}

#-----------------------------------------------------------------------------

=item B<fix_audio($title_ref, $synopsis_ref, $flags_href)>

(Used by EPG function)

Searches the synopsis string and removes any audio information, adding the information
to the $flags HASH reference.

The flags supported are:

  'AD' => 'is_audio_described',
  'S'  => 'is_subtitled',
  'SL' => 'is_deaf_signed',

=cut

sub fix_audio
{
	my ($title_ref, $synopsis_ref, $flags_href) = @_ ;

print STDERR "fix_audio(title=\"$$title_ref\", synopsis=\"$$synopsis_ref\")\n" if $DEBUG ;

    # extract audio described / subtitled / deaf_signed from synopsis
	$$synopsis_ref ||= "" ;
	return unless $$synopsis_ref =~ s/\[([A-Z,]+)\][\.\s]*//;
	
	my $flags = $1;
    foreach my $flag (split ",", $flags) 
    {
	    my $method = $AUDIO_FLAGS{$flag} || next; # bad data
	    $flags_href->{$method} = 1;
    }
print STDERR "fix_audio() - END title=\"$$title_ref\", synopsis=\"$$synopsis_ref\"\n" if $DEBUG ;
}

#-----------------------------------------------------------------------------

=item B<subtitle($synopsis_ref, $subtitle_ref, $genre_ref)>

Extracts a sub-title from the synopsis. Looks for text of the format:

	Some sort of subtitle: the rest of the synopsis....
	
And returns the sentence before the ':' i.e.
	
	Some sort of subtitle

Returns empty string if not found.

NOTE: Not to be confused with subtitling for the hard of hearing!

=cut

=item B<subtitle($synopsis)>

Same as L</subtitle($synopsis_ref, $subtitle_ref, $genre_ref)> but supports old-style
interface.

=cut

sub subtitle
{
	my ($synopsis_ref, $subtitle_ref, $genre_ref) = @_ ;

	## Allow for old-style interface
	if (!ref($synopsis_ref))
	{
		my $synopsis = $synopsis_ref ;
		$synopsis_ref = \$synopsis ;
	}
	my $subtitle = "" ;
	$subtitle_ref ||= \$subtitle ;
	my $genre = "" ;
	$genre_ref ||= \$genre ;


	## Defaults	
	$$genre_ref = "" ;
	$$subtitle_ref = "" ;

print STDERR "subtitle(synopsis=\"$$synopsis_ref\")\n" if $DEBUG ;

	my $restore_synopsis ;

	# Strip out "* series." from start (e.g. Drama series, Crime drama series, etc)
	## Check what's left of synopsis to remove any genre info
	if ($$synopsis_ref =~ s/^\s*(\w+\s+){1,2}series\.\s*//i)
	{
		$$genre_ref = $1 ;
	}
	
	## Don't treat time(s) as start of subtitle
	## e.g. 4:50 from paddington
	# "Blood Wedding (Part 1): ...."
	if ($$synopsis_ref =~ s/^\s*(.+?)\:(?!\d\d)\s*//) 
	{
		$$subtitle_ref = $1;
		$restore_synopsis = ':' ;
	}
	
	# If none found then see if we can use a sort sentence from the start of the synopsis
	if (!$$subtitle_ref)
	{
		if ($$synopsis_ref =~ s/^\s*([^\.]+)\.\s*//) 
		{
			$$subtitle_ref = $1;
			$restore_synopsis = '.' ;
		}
		else
		{
			# get a limited subset
			$$subtitle_ref = $$synopsis_ref ;
			$$subtitle_ref =~ s/^\s+// ;
			$$subtitle_ref = substr $$subtitle_ref, 0, 32 ;
		}
	}

	## Check what's left of synopsis to remove any genre info
	# Drama series. 
	if ($$synopsis_ref =~ s/^\s*(\w+\s+){1,2}series\.\s*//i)
	{
		$$genre_ref = $1 ;
	}
	
	
	## Glue subtitle back onto front of synopsis
	if ($restore_synopsis)
	{
		$$synopsis_ref = "$$subtitle_ref$restore_synopsis $$synopsis_ref" ;
	}

	# Strip leading/trailing space
	$$synopsis_ref =~ s/^\s+// ;
	$$synopsis_ref =~ s/\s+$// ;
	$$subtitle_ref =~ s/^\s+// ;
	$$subtitle_ref =~ s/\s+$// ;

print STDERR "subtitle() - END synopsis=\"$$synopsis_ref\", subtitle=\"$$subtitle_ref\"\n" if $DEBUG ;

	# return subtitle
	return $$subtitle_ref ;
}





# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

