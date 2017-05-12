package Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace - TVGuide debug trace

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Schedule ;


=head1 DESCRIPTION

Trace through the recording IDs (RIDs) and each of the processing steps that are taken for them. This allows me to see
where/why a recording request does not make it into the cron job.

Trace HASH is of the form:

	'state'	=> {							# Useful (?) state info
		
		'fn'		=> current function name
	},
	
	'rids'	=> {							# Trace of all the record IDs
		
		$rid	=> {						# info for this rid
			'info'	=> $record_href,		# HASH ref for this recording
			'trace'	=> [					# Trace details for each function
			
				{							# A HASH entry for function call
					'fn'	=> $fn,
					'info'	=> [			# List of information for this function
						{ ... },
						{ ... },
					],
				},
				...		
			],
			
		},
		...
	},

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

our $VERSION = "1.002" ;

#============================================================================================
# USES
#============================================================================================
use Data::Dumper ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants ;

#============================================================================================
# OBJECT HIERARCHY
#============================================================================================

#============================================================================================
# GLOBALS
#============================================================================================

our $debug=0;
our $trace_flag ;
our %dbgtrace ;


#============================================================================================
# CONSTRUCTOR 
#============================================================================================

BEGIN
{
	$trace_flag = 0 ;
	%dbgtrace = () ;
}



#============================================================================================
# OBJECT DATA METHODS 
#============================================================================================

#-----------------------------------------------------------------------------

=item C<trace_flag($trace_flag)>

Set of clear the trace flag

=cut

sub trace_flag
{
	my ($flag) = @_ ;
	
	$trace_flag = $flag if (defined($flag)) ;
	
	return $trace_flag ;
}
	

#============================================================================================
# OBJECT METHODS 
#============================================================================================

#---------------------------------------------------------------------------------------------------
# Display all recordings
sub dbg_rids
{
	my ($recording_aref) = @_ ;
	
	foreach my $record_href (@$recording_aref)
	{
		printf "%5d : %s\n", 
			$record_href->{'rid'},
			format_rec($record_href) ;
	}

}

#---------------------------------------------------------------------------------------------------
# Clear out all entries
sub trace_clear
{
print "trace_clear() flag=$trace_flag\n" if $debug ;
	return unless $trace_flag ;
	
	$dbgtrace{'state'} = {
		'fn'	=> undef,
	} ;
	$dbgtrace{'rids'} = {
	} ;
}


#---------------------------------------------------------------------------------------------------
# Create entries for all recordings
sub trace_init
{
	my ($recording_aref) = @_ ;
	
print "trace_init() flag=$trace_flag\n" if $debug ;
	return unless $trace_flag ;
	
#	$dbgtrace{'state'} = {
#		'fn'	=> undef,
#	} ;
#	$dbgtrace{'rids'} = {
#	} ;

	foreach my $record_href (@$recording_aref)
	{
		new_rid($record_href->{'rid'}, $record_href) ;
	}

}


#---------------------------------------------------------------------------------------------------
# Create new rid entry
sub new_rid
{
	my ( $rid, $record_href) = @_ ;

print "new_rid(rid=$rid) flag=$trace_flag\n" if $debug ;
	return unless $trace_flag ;
	
	$dbgtrace{'rids'}{$rid} = {
		'info'	=> $record_href,
		'trace'	=> [],
	} ;

}

#---------------------------------------------------------------------------------------------------
# In new function
sub startfn
{
	my ($fn) = @_ ;

print "startfn($fn) flag=$trace_flag\n" if $debug ;

	return unless $trace_flag ;
	
	$dbgtrace{'state'}{'fn'} = $fn ;

	foreach my $rid (keys %{$dbgtrace{'rids'}})
	{
		push @{$dbgtrace{'rids'}{$rid}{'trace'}}, {
			'fn'	=> $fn,
			'info'	=> [],
		} ;
	}
}

#---------------------------------------------------------------------------------------------------
# Add some more trace info
sub add_trace
{
	my ($rid, $info) = @_ ;

print "add_trace($rid, $info) flag=$trace_flag\n" if $debug ;

	return unless $trace_flag ;
	
	if (exists($dbgtrace{'rids'}{$rid}))
	{
print "Trace[rid=$rid] " . Data::Dumper->Dump([$dbgtrace{'rids'}{$rid}{'trace'}]) if $debug ;
		#? does trace have any entries ?.....
		push @{$dbgtrace{'rids'}{$rid}{'trace'}[-1]{'info'}}, $info ;
	}
	else
	{
print "rid=$rid does not exist\n" if $debug ;
print "RIDS= " . Data::Dumper->Dump([$dbgtrace{'rids'}]) if $debug ;
		
	}
}

#---------------------------------------------------------------------------------------------------
# Add some more trace info using the recording HASH
sub add_rec
{
	my ($rec_href, $info) = @_ ;

	# Treat text as a message
	if (! ref($info) )
	{
		
		$info = {
			'msg'	=> $info,
		} ;
	}

	# Add this recording to the info if we can
	if (ref($info) eq 'HASH')
	{
		$info->{'recording'} = $rec_href ;
	}
	add_trace($rec_href->{'rid'}, $info) ;
}

#---------------------------------------------------------------------------------------------------
# Create trace
sub create_trace_report
{
	my $trace = "" ;
	return $trace unless $trace_flag ;
	
	my $now_string = localtime;
	
	foreach my $rid (keys %{$dbgtrace{'rids'}})
	{
		if ( ($trace_flag eq 'all') || ($trace_flag == $rid) )
		{
			$trace .= sprintf "\n\n== RID %5d : %s '%s' [%s] ==\n", 
				$rid,
				$dbgtrace{'rids'}{$rid}{'info'}{'channel'},
				$dbgtrace{'rids'}{$rid}{'info'}{'title'},
				Linux::DVB::DVBT::Apps::QuartzPVR::Base::Constants::record_types($dbgtrace{'rids'}{$rid}{'info'}{'record'}) ;
			
			# show each function call in turn
			foreach my $trace_href (@{$dbgtrace{'rids'}{$rid}{'trace'}})
			{
				# check we've got some entries
				if (scalar(@{$trace_href->{'info'}}))
				{
					# function
					$trace .= "\n  -- $trace_href->{'fn'} --\n" ;
					
					# entries
					my %grouped ;
					foreach my $info_href (@{$trace_href->{'info'}})
					{
						my $reckey ;
						if (exists($info_href->{'recording'}))
						{
							# Handle recording - save for later
							$reckey = sprintf "rid %5d : %s ", 
								$info_href->{'recording'}{'rid'},
								format_rec($info_href->{'recording'}) ;
							$grouped{$reckey} ||= [] ;
							if (exists($info_href->{'msg'}))
							{
								push @{$grouped{$reckey}}, $info_href->{'msg'} ;
							}
						}
						else
						{
							# Immediately show key/value
							foreach my $key (sort keys %$info_href)
							{
								$trace .=  "     " ;
								if ($key eq 'msg')
								{
									$trace .= "# $info_href->{'msg'}" ;
								}
								elsif ($key eq 'listings')
								{
									$trace .= "Listings:" ;
									foreach my $list_href (@{$info_href->{'listings'}})
									{
										$trace .= sprintf  "\n       pid %s : %s",
											 $list_href->{'pid'},
											 format_rec($list_href) ;
									}
								}
								else
								{
									if (ref($info_href->{$key}) eq 'HASH')
									{
										#????	
									}
									elsif (ref($info_href->{$key}) eq 'ARRAY')
									{
										#????	
									}
									elsif (ref($info_href->{$key}) eq 'SCALAR')
									{
										$trace .= "%key => ${$info_href->{$key}}" ;	
									}
									else
									{
										$trace .= "%key = $info_href->{$key}" ;	
									}
								}	
								$trace .= "\n" ;
							}
						}
					}

					# show grouped info
					foreach my $reckey (sort keys %grouped)
					{
						$trace .=  "     $reckey\n" ;
						foreach my $msg (@{$grouped{$reckey}})
						{
							$trace .=  "         # $msg\n" ;
						}
					}
				}	
			}	
		}
	}

	$trace .= "\n\n" ;

	return $trace ;
}


#---------------------------------------------------------------------------------------------------
# Display trace
sub display
{
	return unless $trace_flag ;
	
	my $trace = create_trace_report() ;
	print $trace ;
}


#---------------------------------------------------------------------------------------------------
# Display all recordings
sub format_rec
{
	my ($record_href) = @_ ;
	
	return sprintf "%s '%s' @ %s %s .. %s (pid %s)", 
		$record_href->{'channel'}, 
		$record_href->{'title'}, 
		$record_href->{'date'},
		$record_href->{'start'},
		$record_href->{'end'},
		$record_href->{'pid'} ;

}



#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE
1;

__END__


