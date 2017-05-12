package Linux::DVB::DVBT::Apps::QuartzPVR::Path ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Path - path utils

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Path ;


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

our $VERSION = "1.001" ;

#============================================================================================
# USES
#============================================================================================
use Data::Dumper ;
use File::Basename ;
use File::Path qw/mkpath/ ;


#============================================================================================
# GLOBALS
#============================================================================================

our $debug = 0 ;

#============================================================================================
# OBJECT METHODS 
#============================================================================================


#---------------------------------------------------------------------------------------------------
# Create an "episode" string
sub episode_string
{
	my ($rec_href) = @_ ;
	
	my $episode = $rec_href->{'episode'} ? sprintf "Episode %02d", $rec_href->{'episode'} : "" ;
	my $subtitle = $rec_href->{'subtitle'} ? $rec_href->{'subtitle'} : "" ;
	
	if ($episode && $subtitle)
	{
		$episode .= " - " ;
	}
	
	my $string = "$episode$subtitle" ;
	
	return $string ;
}


#---------------------------------------------------------------------------------------------------
# Expands '~' and any environment vars
sub expand_path
{
	my ($pathspec, $vars_href) = @_ ;
	
	$vars_href ||= { %ENV } ;
	
	# Expand ~
	$pathspec =~ s/~/$ENV{'HOME'}/g ;
	
	# Expand vars
	$pathspec =~ s/\$(\w+)/$vars_href->{$1}/ge ;
	
	return $pathspec ;
}


#---------------------------------------------------------------------------------------------------
# Clean up the filename path so that it makes a valid/usable pathname. Also expands '~' and any 
# environment vars
sub cleanpath
{
	my ($pathspec, $vars_href) = @_ ;
	
	print "cleanpath($pathspec)\n" if $debug ;
	
	# Expand variables
	$pathspec = expand_path($pathspec, $vars_href) ;
	
	print " + after expand: $pathspec\n" if $debug ;

	# Strip out certain chars
	$pathspec =~ s/[\'\"]//g ;
	
	# Replace other chars with 'space'
	$pathspec =~ s/[\:]/-/g ;

	# Replace multiple spaces with single 'space'
	$pathspec =~ s/\s+/ /g ;
	$pathspec =~ s/[-]+/-/g ;
	$pathspec =~ s/\s*\-\s+/-/g ;

	# Replace multiple //
	$pathspec =~ s%//%/%g ;
	$pathspec =~ s%/[-]+/%/%g ;
	
	print " + FINAL: $pathspec\n" if $debug ;

	return $pathspec ;
}


#---------------------------------------------------------------------------------------------------
sub parse
{
	my ($path) = @_ ;
	
	my ($file, $dir, $suffix) = fileparse($path, qr/\.[^.]*/);
	return wantarray ? ($dir, $file, $suffix) : $file ;	
}

#---------------------------------------------------------------------------------------------------
sub unparse
{
	my ($dir, $file, $suffix) = @_ ;

	return "$dir$file$suffix" ;	
}

#---------------------------------------------------------------------------------------------------
# Clean up the filename (based from a program title) so that it makes a valid/usable filename
# $fname does not include dirs OR extension
sub sanitise
{
	my ($fname) = @_ ;
	
	# Strip out certain chars
	$fname =~ s/[\'\"\.\/]//g ;
	
	# Replace other chars with '-'
	$fname =~ s/[\:]/-/g ;

	# Replace multiple spaces with single space
	$fname =~ s/\s+/ /g ;
	$fname =~ s/[-]+/-/g ;
	$fname =~ s/\s*\-\s+/-/g ;
	
	return $fname ;
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


