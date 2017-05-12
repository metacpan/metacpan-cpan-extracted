package Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants - constants for TVGuide

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

our $VERSION = "1.000" ;

#============================================================================================
# USES
#============================================================================================

#============================================================================================
# GLOBALS
#============================================================================================

our %QUERY_NAME ;
our %RECORD_TYPES ;
our %RECORD_TYPES_LOOKUP ;
our $MAX_RECORD_TYPES ;

# Number of minutes in a day
our $DAY_MINS ;

# Tag new recordings
our $NEW_RID ;

# Default priority
our $DEFAULT_PRIORITY ;

## Recording levels
our %REC_GROUPS ;
our %REC_GROUPS_LOOKUP ;
our $REC_MASK ;
our $REC_GROUP_MASK ;

# Special properties of a dummy "fuzzy" recording
our $FUZZY_PID ;
our $FUZZY_TIME ;
our $FUZZY_DURATION ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

BEGIN
{
	# Maximum value of record:
	%RECORD_TYPES = (
		0		=> 'none',
		1		=> 'once',
		2		=> 'weekly',
		3		=> 'daily',
		4		=> 'multi',
		5		=> 'all',
		6		=> 'series',
		
		7		=> 'MAX',
	) ;

	# Map from record type to a query
	foreach my $rec (keys %RECORD_TYPES)
	{
		$QUERY_NAME{$rec} = "select_$RECORD_TYPES{$rec}" ;
	}

	%RECORD_TYPES_LOOKUP = map { $RECORD_TYPES{$_} => $_ } keys %RECORD_TYPES ;
	$MAX_RECORD_TYPES = $RECORD_TYPES_LOOKUP{'MAX'} ;
	
	
	# Number of minutes in a day
	$DAY_MINS = 24*60 ;
	
	# Tag new recordings
	$NEW_RID = -1 ;
	
	# Default priority
	$DEFAULT_PRIORITY = 50 ;
	
	## Recording levels
	%REC_GROUPS = (
		'DVBT'			=> 0x00,	
		'FUZZY'			=> 0x20,	
		'DVBT_IPLAY'	=> 0xC0,
		'IPLAY'			=> 0xE0
	) ;
	%REC_GROUPS_LOOKUP = map { $REC_GROUPS{$_} => $_ } keys %REC_GROUPS ;
	
	$REC_MASK = 0x1f ;
	$REC_GROUP_MASK = 0xE0 ;
	
	## Fuzzy settings
	$FUZZY_PID = "9-9-9" ;
	$FUZZY_TIME = "04:00" ;
	$FUZZY_DURATION = "00:00:01" ;
	
}




#============================================================================================
# OBJECT METHODS 
#============================================================================================

#---------------------------------------------------------------------
sub query_name
{
	my ($rec) = @_ ;

	my $rec_type = record_base($rec) ;
##print "query_name($rec) rec_type=$rec_type\n" ;
	
	my $query_name = 'select_multi' ;
	if (exists($QUERY_NAME{$rec_type}))
	{
		$query_name = $QUERY_NAME{$rec_type}  ;
##print " + found query_name\n" ;
	}

##print "query_name=$query_name\n" ;
	return $query_name ;
}

#---------------------------------------------------------------------
sub record_types
{
	my ($rec) = @_ ;

	return $RECORD_TYPES{record_base($rec)} ;
}

#---------------------------------------------------------------------
sub record_types_lookup
{
	my ($name) = @_ ;

	return $RECORD_TYPES_LOOKUP{$name} || 0 ;
}

#---------------------------------------------------------------------
# Removes the recording "group" bits, leaving just the setting (i.e. once, daily etc)
#
sub record_base
{
	my ($record) = @_ ;
	
	return $record & $REC_MASK ;
}

#---------------------------------------------------------------------
# Returns the group name (i.e. 'DVBT', 'IPLAY' etc)
#
sub record_group
{
	my ($record) = @_ ;
	
	return $REC_GROUPS_LOOKUP{$record & $REC_GROUP_MASK} ;
}


#---------------------------------------------------------------------
# Returns true if recording has an IPLAY component
#
sub has_iplay
{
	my ($record) = @_ ;
	
	return $record >= $REC_GROUPS{'DVBT_IPLAY'} ;
}

#---------------------------------------------------------------------
# Returns true if recording has an DVBT component
#
sub has_dvbt
{
	my ($record) = @_ ;
	
	return $record < $REC_GROUPS{'IPLAY'} ;
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


