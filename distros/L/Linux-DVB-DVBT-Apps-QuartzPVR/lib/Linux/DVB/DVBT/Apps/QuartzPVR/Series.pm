package Linux::DVB::DVBT::Apps::QuartzPVR::Series ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Series - series recording

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Series ;


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

our $VERSION = "1.005" ;

#============================================================================================
# USES
#============================================================================================
use Data::Dumper ;

#use Linux::DVB::DVBT::Utils ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Time ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Path ;

#============================================================================================
# GLOBALS
#============================================================================================

our $debug = 0 ;

our $opts_href ;


#============================================================================================
# OBJECT METHODS 
#============================================================================================

BEGIN {
	
	$opts_href = {
		'app'				=> undef,
		'video_dir'			=> '/served/videos/PVR',
		'audio_dir'			=> '/served/stories',
		'video_path'		=> '$video_dir/$title.mp3',
		'audio_path'		=> '$audio_dir/$title.mp3',
		'variables'			=> {},
	} ;
}

#---------------------------------------------------------------------
# Set options 
sub set
{
	my (%options) = @_ ;

	foreach my $opt (keys %options)
	{
		$opts_href->{$opt} = $options{$opt} ;
	}
	
	$debug = $options{'debug'} if exists($options{'debug'}) ;
	
	## Post-process
	$opts_href->{'variables'} = {
#		%ENV,
		%{$opts_href->{'variables'}},
	} ;
	
	foreach my $d (qw/video_dir audio_dir/)
	{
		$opts_href->{$d} = Linux::DVB::DVBT::Apps::QuartzPVR::Path::expand_path($options{$d}, $opts_href->{'variables'}) ;
		$opts_href->{'variables'}{$d} = $opts_href->{$d} ;
	}
	
}

#---------------------------------------------------------------------
# Return the pathspec for this type of program
sub default_pathspec
{
	my ($rec_href) = @_ ;

	my $pathspec ;
	
	# channel type (tv/audio)
	my $type = $rec_href->{'chan_type'} ;
	if ($type eq 'radio')
	{
		# audio 
		$pathspec = $opts_href->{'audio_path'} ;
	}
	else
	{
		# video 
		$pathspec = $opts_href->{'video_path'} ;
	}

	return $pathspec ; 
}	


#---------------------------------------------------------------------
# filename including directories EXCLUDING extension
sub get_vars
{
	my ($rec_href) = @_ ;
	
	## global vars
	my %vars = %{$opts_href->{'variables'}} ;


	my $date = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_format($rec_href->{'start_datetime'}, "%Y %m %d %H %M %S") ;
	my @date = split(/\s+/, $date) ;	
	my $datestr = join('', @date) ;	 

	my $date_only = "$date[0]$date[1]$date[2]" ;
	my $time_only = "$date[3]$date[4]$date[5]" ;
	
	## specific
	# title = main program title (e.g. 'New Tricks')
	# genre = program genre (e.g. 'Crime')
	# series = series (e.g. 'Series 3')
	# name = episode name (e.g. 'episode 2', or 'The Lovecar Displacency')
	#
	%vars = (
		%vars,
		
		# date/time
		'Y'			=> $date[0],
		'm'			=> $date[1],
		'd'			=> $date[2],
		'H'			=> $date[3],
		'M'			=> $date[4],
		'S'			=> $date[5],

		'Ymd'		=> $date_only,
		'HMS'		=> $time_only,
		##'YmdHMS'	=> $datestr,
		'YmdHMS'	=> "$date_only$time_only",
		
		# program
		'genre'			=> '',
		'series'		=> '',	# Series X
		'series_num'	=> '',	# X
		'episode'		=> '',	# Episode Y
		'episode_num'	=> '',	# Y
		'name'			=> '',
		
		'tva_series_num'=> '',
		'tva_prog_num'	=> '',
		
		# Override with all existing program fields
		'title'			=> '',
		'subtitle'		=> '',
		'tva_series'	=> '',
		'tva_prog'		=> '',
		%$rec_href,
	) ;
	
	
	## Special case for 'dir'
	my $type = $rec_href->{'chan_type'} ;
	my $dir = "" ;
	if ($type eq 'radio')
	{
		# audio 
		$dir = $opts_href->{'audio_dir'} ;
	}
	else
	{
		# video 
		$dir = $opts_href->{'video_dir'} ;
	}
	$vars{'dir'} = $dir ;
	
	## Special case for tva_*
	foreach my $field (qw/series prog/)
	{
		$vars{"tva_${field}"} ||= '' ;

		# clear item if it's set to the special marker '-'
		if ($vars{"tva_${field}"} eq '-')
		{
			$vars{"tva_${field}"} = '' ;
		}
		
		$vars{"tva_${field}_num"} = $vars{"tva_${field}"} ;
		$vars{"tva_${field}_num"} =~ s%/%%g ;
		$vars{"tva_${field}"} = '' ;
		if ($vars{"tva_${field}_num"})
		{
			$vars{"tva_${field}"} = "Series " . $vars{"tva_${field}_num"} ;
		}
	}
	
	
#	$vars{'tva_series_num'} = $vars{'tva_series'} || '' ;
#	$vars{'tva_series_num'} =~ s%/%%g ;
#	$vars{'tva_series'} = '' ;
#	if ($vars{'tva_series_num'})
#	{
#		$vars{'tva_series'} = "Series $vars{'tva_series_num'}" ;
#	}
#	
#	$vars{'tva_prog_num'} = $vars{'tva_prog'} || '' ;
#	$vars{'tva_prog_num'} =~ s%/%%g ;
#	if ($vars{'tva_prog_num'})
#	{
#		$vars{'tva_prog'} = "Program $vars{'tva_prog_num'}" ;
#	}
	

$opts_href->{'app'}->prt_data("Series::get_vars() - prog=", $rec_href) if $debug ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_vars() : title=\"$rec_href->{title}\"") ;

	my $name = "" ;
	my $title = $rec_href->{'title'} ;
	my $subtitle = $rec_href->{'subtitle'} ;
	my $series = "" ;
	my $series_num = "" ;
	my $episode = "" ;
	my $episode_num = "" ;
	
	## Get genre information
	if ($rec_href->{'genre'})
	{
		# In the form: <main>|<sub1> / <sub2> (<info>)
		if ($rec_href->{'genre'} =~ /^([^\|]+)\s*\|/)
		{
			$vars{'genre'} = $1 ;
		}
	}
	
	## Is this a series
	if (is_series($rec_href))
	{
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_vars() : is a series") ;
		
		if ($rec_href->{'series'})
		{
			$series_num = sprintf "%02d", $rec_href->{'series'} ;	
			$series = "Series $series_num" ;	
		}
		
		if ($rec_href->{'episode'})
		{
			$episode_num = sprintf "%02d", $rec_href->{'episode'} ;	
			$episode = "Episode $episode_num" ;	
		}
		
		Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_vars() : subtitle=\"$subtitle\", series=\"$series\", episode=\"$episode\"") ;
		
		if ($subtitle)
		{
			$name = $subtitle ;
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_vars() : got subtitle") ;
		}
		elsif ($episode)
		{
			$name = ${episode} ;
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_vars() : got episode") ;
		}
		else
		{
			$subtitle ||= $title ;
			$name = $subtitle ;
			Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_vars() : not got subtitle or episode : subtitle=\"$subtitle\"") ;
		}
		
	}

	$vars{'name'} = $name || $subtitle || $title || $datestr ;
	$vars{'episode'} = $episode ;
	$vars{'series'} = $series ;
	
$opts_href->{'app'}->prt_data("Series::get_vars() - final vars=", \%vars) if $debug ;
	
	return \%vars ;
}




#---------------------------------------------------------------------
# Expand the program's pathspec into a valid path 
# [Call's cleanpath() to remove invalid chars/spaces]
sub expand_pathspec
{
	my ($rec_href) = @_ ;

my $path_debug=$Linux::DVB::DVBT::Apps::QuartzPVR::Path::debug ;
$Linux::DVB::DVBT::Apps::QuartzPVR::Path::debug = $debug ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "expand_pathspec($rec_href->{'pathspec'})") ;

	# get pathspec
	my $pathspec = $rec_href->{'pathspec'} || default_pathspec($rec_href) ;
	
$opts_href->{'app'}->prt_data("Series::expand_pathspec($pathspec) - prog=", $rec_href) if $debug ;

	# set up vars
	my $vars_href = get_vars($rec_href) ;
	
	# expand
	my $path = Linux::DVB::DVBT::Apps::QuartzPVR::Path::cleanpath($pathspec, $vars_href) ;
	
	# fix filename (removes any empty elements / dirs)
	my ($dir, $file, $suffix) = Linux::DVB::DVBT::Apps::QuartzPVR::Path::parse($path) ;
	$file = Linux::DVB::DVBT::Apps::QuartzPVR::Path::sanitise($file) ;
	$path = Linux::DVB::DVBT::Apps::QuartzPVR::Path::unparse($dir, $file, $suffix) ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "expand_pathspec() : path=$path") ;

print "Series::expand_pathspec() - path=$path\n" if $debug ;

$Linux::DVB::DVBT::Apps::QuartzPVR::Path::debug = $path_debug ;
	
	return $path ; 
}	


#---------------------------------------------------------------------
# filename including directories
# [Call's expand_pathspec() -> cleanpath() to remove invalid chars/spaces]
sub get_filename
{
	my ($rec_href) = @_ ;
	
	my $title = $rec_href->{'title'} ; 
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_filename() : title=\"$title\"") ;

	## Get full path
	my $file_path = expand_pathspec($rec_href) ;	
	
	## Split
	my ($dir, $fname, $ext) = Linux::DVB::DVBT::Apps::QuartzPVR::Path::parse($file_path) ;
	my $file = "$fname$ext" ;
	
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::add_rec($rec_href, "get_filename() : final filename=\"$file_path\"") ;
	
	return wantarray ? ($dir, $file) : $file_path ;
}



#---------------------------------------------------------------------------------------------------
# Is this a valid series
sub is_series
{
	my ($rec_href) = @_ ;
	my $series = 0 ;
	if ($rec_href->{'tva_series'} =~ m%^/%)
	{
		++$series ;
	}
	return $series ;
}

#---------------------------------------------------------------------------------------------------
# Convert TV Anytime ID into text
sub tva_text
{
	my ($tva_id) = @_ ;
	
	# strip out '/'
	$tva_id =~ s%[/\s]+%%g ;
	
	return $tva_id ;
}

#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

__END__


