package Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf - TVGuide debug profile

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Schedule ;


=head1 DESCRIPTION

Profile program execution

Profile HASH is of the form:

	'fns'	=> [							# Trace of all the record IDs
		
		{						# info for this function
			'fn'	=> $name
			'start'	=> $time,			# start time
			'end'	=> $time,			# end time
			'fns'	=> [ .. ]
				...	
		},
		...
	],

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
use Data::Dumper ;
use Time::HiRes qw/time/ ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================

#============================================================================================
# GLOBALS
#============================================================================================

our $debug=0;
our $profile_flag ;
our %profile ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

BEGIN
{
	$profile_flag = 0 ;
	%profile = (
		'state'	=> {
			'fn_stack'	=> [],		# keeps track of which function list we're adding to
		},
		'fns'	=> [],
	) ;
}



#============================================================================================
# OBJECT DATA METHODS 
#============================================================================================

#-----------------------------------------------------------------------------

=item C<profile_flag($profile_flag)>

Set of clear the trace flag

=cut

sub profile_flag
{
	my ($flag) = @_ ;
	
	$profile_flag = $flag if (defined($flag)) ;
	
	return $profile_flag ;
}
	

#============================================================================================
# OBJECT METHODS 
#============================================================================================


#---------------------------------------------------------------------------------------------------
# In new function
sub startfn
{
	my ($msg) = @_ ;
	my ($fn) = (caller(1))[3] ;
	
	my $now = time ;
	
print "startfn($fn) flag=$profile_flag : time=$now\n" if $debug ;
#print "profiles=" . Data::Dumper->Dump([\%profile]) if $debug ;

	return unless $profile_flag ;
	
	my $fn_href = {
		'fn'	=> $fn,
		'msg'	=> $msg||"",
		'start'	=> $now,
		'end'	=> undef,
		'way'	=> [],
		'fns'	=> [],
	} ;
	
	# add this function to it's parent's list
	if (scalar(@{$profile{'state'}{'fn_stack'}}))
	{
		my $parent_fn_href = $profile{'state'}{'fn_stack'}[-1] ;
		push @{$parent_fn_href->{'fns'}}, $fn_href ;
	}
	else
	{
		push @{$profile{'fns'}}, $fn_href ;
	}
	
	# point at this function so subsequent function calls will be added to this one's
	push @{$profile{'state'}{'fn_stack'}}, $fn_href ;
	
	return $fn_href ;	
}

#---------------------------------------------------------------------------------------------------
# Add a waypoint
sub waypoint
{
	my ($msg) = @_ ;
	my ($fn) = (caller(1))[3] ;
	
	my $now = time ;
	
print "waypoint($msg) flag=$profile_flag : time=$now\n" if $debug ;

	return unless $profile_flag ;
	
	# add this waypoint to it's function's list
	if (scalar(@{$profile{'state'}{'fn_stack'}}))
	{
		my $fn_href = $profile{'state'}{'fn_stack'}[-1] ;
		my $start = $fn_href->{'start'} ;
		if (scalar(@{$fn_href->{'way'}}))
		{
			my $prev_way_href = $fn_href->{'way'}[-1] ;
			$start = $prev_way_href->{'end'} ;
		}
		
		my $way_href = {
			'msg'	=> $msg||"",
			'start'	=> $start,
			'end'	=> $now,
		} ;
		
		push @{$fn_href->{'way'}}, $way_href ;
	}
	
}

#---------------------------------------------------------------------------------------------------
# End of function
sub endfn
{
	my ($msg) = @_ ;
	my ($fn) = (caller(1))[3] ;

	my $now = time ;

print "endfn($fn) flag=$profile_flag : time=$now\n" if $debug ;

	return unless $profile_flag ;
	
	my $fn_href = $profile{'state'}{'fn_stack'}[-1] ;
	$fn_href->{'end'} = $now ;
	
	# point at this function's parent to finish
	pop @{$profile{'state'}{'fn_stack'}} ;

	return $fn_href ;	
}



#---------------------------------------------------------------------------------------------------
# Format profile
sub _format
{
	my ($fn_href, $level) = @_ ;
	my @lines ;

#print "_format($fn_href->{'fn'}, level=$level)\n" ;
	
	## this function's info
	my $duration = 0.0 ;
	if ($fn_href->{'start'} && $fn_href->{'end'})
	{
		$duration = $fn_href->{'end'} - $fn_href->{'start'} ;
printf(" start=%f end=%f : duration=%f\n", $fn_href->{'start'}, $fn_href->{'end'}, $duration) if $debug ;		
	}
	my $indent = "  "x$level ;
	my $info = sprintf "%-30s : %f ",  "$indent$fn_href->{'fn'}", $duration ;
	$info .= " # $fn_href->{'msg'}" if $fn_href->{'msg'} ;
	push @lines, $info ;

	## Any waypoints
	foreach my $way_href (@{$fn_href->{'way'}})
	{
		$duration = 0.0 ;
		if ($way_href->{'start'} && $way_href->{'end'})
		{
			$duration = $way_href->{'end'} - $way_href->{'start'} ;
		}
		$info = sprintf "%-30s : %f ",  "${indent}* $way_href->{'msg'}", $duration ;
		push @lines, $info ;
	}
	
	
	## it's calls
	foreach my $sub_fn_href (@{$fn_href->{'fns'}})
	{
		push @lines, _format($sub_fn_href, $level+1) ;
	}

#print "_format($fn_href->{'fn'}, level=$level) - END\n" ;
	
	return @lines ;
}

#---------------------------------------------------------------------------------------------------
# Format profile
sub format_prof
{
	my @lines = () ;
	return @lines unless $profile_flag ;

	foreach my $fn_href (@{$profile{'fns'}})
	{
		push @lines, _format($fn_href, 0) ;
	}
	
	return @lines ;
}



#---------------------------------------------------------------------------------------------------
# Display profile
sub display
{
	return unless $profile_flag ;
	
	my @lines = format_prof() ;
	foreach (@lines)
	{
		print "$_\n" ;
	}
}



#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE
1;

__END__
