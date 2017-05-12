package Linux::DVB::DVBT::Apps::QuartzPVR::DVB ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::DVB - DVB-T utils

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::DVB ;


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
use Linux::DVB::DVBT ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Time ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Series ;

#============================================================================================
# GLOBALS
#============================================================================================

our $debug = 0 ;
our $tuning_href ;
our $channels_aref ;
our %chan_to_tsid ;
our %tsid_chans ;

our $all_devices_aref ;
our $used_devices_aref ;

our %adapter_lookup ;
our %index_lookup ;


#============================================================================================
# FUNCTIONS
#============================================================================================

#---------------------------------------------------------------------
sub lookup_channel
{
	my ($channel_name, $tuning_href) = @_ ;
	
	$channel_name = _channel_alias($channel_name, $tuning_href->{'aliases'}) ;
	my $found_channel_name = _channel_search($channel_name, $tuning_href->{'pr'}) ;	
	
	return $found_channel_name ;
}

#---------------------------------------------------------------------
# Given a channel name, find the multiplex that the channel belongs to 
# and return a list of ALL the channels in the multiplex
sub multiplex_channels
{
	my ($chan) = @_ ;
	my %channels = () ;
	
	if (exists($chan_to_tsid{$chan}))
	{
		my $tsid = $chan_to_tsid{$chan} ;
		my $chans_aref = $tsid_chans{$tsid} ;
		
		%channels = map { $_ => $tsid } @$chans_aref ;
	}
	
	return %channels ;
}

#---------------------------------------------------------------------
# Given a space/comma separated string, set the list of useable adapters
# complain about any invalid settings
sub set_useable_adapters
{
	my ($adapter_string) = @_ ;
	
	## if no spec specified, just return default set
	if (!$adapter_string)
	{
		return @$used_devices_aref ;
	}
	
	# reset
	$used_devices_aref = [] ;
	
	my @spec = split(/[\s,]+/, $adapter_string) ;
	foreach my $spec (@spec)
	{
		# each entry may be of the form <adapter>:<frontend>
		my ($adap, $fe) = split(/:/, $spec) ;
		foreach my $device_href (@$all_devices_aref)
		{
			if ($adap == $device_href->{'adapter_num'})
			{
				my $ok = 0 ;
				if (!defined($fe))
				{
					++$ok ;
				}
				elsif ($fe == $device_href->{'frontend_num'})
				{
					++$ok ;
				}


				if ($ok)
				{
					push @$used_devices_aref, $device_href ;
					last ;
				}
			}
		}
	}
	
	# ensure adapters are sorted 
	@$used_devices_aref = sort {
		$a->{'adapter_num'} <=> $b->{'adapter_num'}
		||
		$a->{'frontend_num'} <=> $b->{'frontend_num'}
	} @$used_devices_aref ;
	
	# re-create the adapter lookup table
	_update_adapter_lookup() ;
	
	return @$used_devices_aref ;
}


#---------------------------------------------------------------------
# Given device HASH ref, convert into <adapter>:<frontend> format using the useable_devices
# list
sub device2adapter
{
	my ($device_href) = @_ ;
	my $adapter = sprintf "%d:%d", $device_href->{'adapter_num'}, $device_href->{'frontend_num'} ; 
	return $adapter ;
}




#---------------------------------------------------------------------
# Given an adapter index, convert into <adapter>:<frontend> format using the useable_devices
# list
sub _index2adapter
{
	my ($idx) = @_ ;
	my $adapter = "" ;
	if ($idx < scalar(@$used_devices_aref))
	{
		my $devices_href = $used_devices_aref->[$idx] ;
		$adapter = device2adapter($devices_href) ; 
	}
	return $adapter ;
}


#---------------------------------------------------------------------
# Create a lookup HASH that converts the adapter name into an index into the
# useable devices list
sub _update_adapter_lookup
{
	%adapter_lookup = () ;
	%index_lookup = () ;

	for (my $idx=0; $idx < scalar(@$used_devices_aref); ++$idx)
	{
		my $devices_href = $used_devices_aref->[$idx] ;
		my $adapter = _index2adapter($idx) ;
		
		$adapter_lookup{$idx} = $adapter ;
		$index_lookup{$adapter} = $idx ;
	}
}


#---------------------------------------------------------------------
# Given an adapter in <adapter>:<frontend> format, convert to index using the useable_devices
# list
sub adapter2index
{
	my ($adapter) = @_ ;
	my $idx = -1 ;
	
	if (exists($index_lookup{$adapter}))
	{
		$idx = $index_lookup{$adapter} ;
	}
	return $idx ;
}

#---------------------------------------------------------------------
# Given an adapter index, convert into <adapter>:<frontend> format using the useable_devices
# list
sub index2adapter
{
	my ($idx) = @_ ;
	my $adapter = "" ;
	if (exists($adapter_lookup{$idx}))
	{
		$adapter = $adapter_lookup{$idx} ;
	}
	return $adapter ;
}

#---------------------------------------------------------------------
# Given an adapter index, convert into DVBnnn format using the useable_devices
# list
sub index2dvb
{
	my ($idx) = @_ ;
	my $dvb = "DVB-UNKNOWN" ;
	my $adapter = index2adapter($idx) ;
	if ($adapter)
	{
		$dvb = "DVB$adapter" ; 
	}
	return $dvb ;
}


#============================================================================================
# BEGIN
#============================================================================================
#

BEGIN {
	my $dvb = Linux::DVB::DVBT->new('errmode' => 'return') ;
	
	$all_devices_aref = [ $dvb->device_list() ] ;
	$used_devices_aref = [] ;
	if (@$all_devices_aref >= 1)
	{
		# get list of real adapters (exclude symlinks)
		foreach my $device_href (@$all_devices_aref)
		{
			next if exists($device_href->{'symlink'}) ;
			
			# default use list to the real set of adapters
			push @$used_devices_aref, $device_href ;
		}
		
		
		# get tuning/channel info
		$tuning_href = $dvb->get_tuning_info() ;
		$channels_aref = $dvb->get_channel_list() ;
	
		foreach my $chan_href (@$channels_aref)
		{
			my $channel_name = $chan_href->{'channel'} ;
			my $tsid = $tuning_href->{'pr'}{$channel_name}{'tsid'} ;
	
			# store lookup info
			$chan_to_tsid{$channel_name} = $tsid ;
			$tsid_chans{$tsid} ||= [] ;
			push @{$tsid_chans{$tsid}}, $channel_name ;
		}
	}

	# create the adapter lookup table
	_update_adapter_lookup() ;
	
	
	$dvb->dvb_close() ;
}




# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

__END__


