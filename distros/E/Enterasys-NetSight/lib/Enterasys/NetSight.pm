package Enterasys::NetSight;
{
  $Enterasys::NetSight::VERSION = '1.2';
}
use strict;

use SOAP::Lite;
use Socket;
use Carp;

# On some systems Crypt::SSLeay tries to use IO::Socket::SSL and breaks,
# This forces it to use Net::SSL just in case.
$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS}="Net::SSL";
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;
$ENV{https_proxy}="";

sub new
{
	my ($class, $args)=@_;
	my $self= 
	{
		host 	=> _resolv($args->{host}) || undef,
		port	=> $args->{port} || 8443,
		user	=> $args->{user} || undef,
		pass	=> $args->{pass} || undef,
	};

	if(!$self->{host})
		{ carp("You must specify a host for new method") && return undef }
	elsif(!$self->{user})
		{ carp("You must specify a user for new method") && return undef }
	elsif(!$self->{pass})
		{ carp("You must specify a password for new method") && return undef }

	$self->{proxy}="https://".$self->{user}.":".$self->{pass}."@".$self->{host}.":".$self->{port}."/axis/services/NetSightDeviceWebService";
	$self->{uri}="http://ws.web.server.netsight.enterasys.com";

	$self->{soap}=SOAP::Lite->new(
			uri		=> $self->{uri},
			proxy	=> $self->{proxy},
		);
	# Try one API-Call to check if the API responds properly. On errors
	# (wrong username or password, etc.) the SOAP-Module prints the
	# API-Errorcode and exits the process.
	$self->{soap}->isIpV6Enabled();
	return bless($self, $class);
}

# Shortcut methods for getting and parsing method returns
sub getAllDevices
{
	# Returns a hash table with IP Addresses for keys
	# and a hash reference value containing device information
	# associated with the IP address

	my ($self)=@_;
	my %devices=();

	my $call=$self->{soap}->getAllDevices;

	if($call->fault) 
		{ carp($call->faultstring) && return undef }

	# Grab IP out of each WsDeviceListResult
	while(my($key,$value)=each($call->result->{data} || return undef))
		{ $devices{$value->{ip}}=$value }

	return \%devices;
}
sub getDevice
{
	# Returns a WsDevice table for a given IP address
	my ($self, $args)=@_;

	if(!defined $args->{host})
		{ carp("You must specify a host for getDevice method") && return undef }

	$args->{host}=_resolv($args->{host});

	my $call=$self->{soap}->getDeviceByIpAddressEx($args->{host}) || return undef;

	if($call->fault) 
		{ carp($call->faultstring) && return undef }

	return $call->result->{data};
}
sub getSnmp
{
	# Returns a hash reference with SNMP credentials
	# The format of this hash can be used to create a 
	# new SNMP::Session with the Net-SNMP module

	my ($self, $args)=@_;
	my (%snmp, %temp)=();

	if(!defined $args->{host})
		{ carp("You must specify a host for getSnmp method") && return undef }
	if(defined $args->{level} && $args->{level} ne "su" && $args->{level} ne "rw" && $args->{level} ne "ro")
		{ carp("Invalid privilege level specified. Valid options are su, rw, or ro") && return undef }

	$args->{host}=_resolv($args->{host});

	my $call=$self->{soap}->getSnmpCredentialAsNgf($args->{host});

	if($call->fault) 
		{ carp($call->faultstring) && return undef }

	# Parse NGF SNMP string into hash table
	foreach my $attribute(split(" ",$call->result() || return undef))
	{
		if((my @keyval=split("=",$attribute))==2)
			{ $temp{$keyval[0]}=$keyval[1] }
	}

	# Format hash for Net-SNMP
	my $auth="";	# Use to build Net-SNMP SecLevel param

	$snmp{DestHost}=$args->{host};
	$snmp{Version}=substr($temp{snmp},1,1);

	if($snmp{Version}==3)
	{
		$snmp{SecName}=$temp{user};
		if($temp{authtype} ne "None")
		{
			$temp{authtype}=~s/SHA\d+/SHA/;
			$snmp{AuthProto}=$temp{authtype};
			$snmp{AuthPass}=$temp{authpwd};
			$auth="auth";
		}
		else
		{
			$auth="noAuth";
		}

		if($temp{privtype} ne "None")
		{
			$snmp{PrivProto}=$temp{privtype};
			$snmp{PrivPass}=$temp{privpwd};	
			$auth.="Priv";
		}
		else
		{
			$auth.="NoPriv";
		}
		$snmp{SecLevel}=$auth;
	}
	else
	{
		# Attempts to get highest privilage community string if no level specified
		if(defined $args->{level})
			{ $snmp{Community}=$temp{$args->{level}} or return undef }
		elsif($temp{su})
			{ $snmp{Community}=$temp{su} }
		elsif($temp{rw}) 
			{ $snmp{Community}=$temp{rw} }
		elsif($temp{ro})
			{ $snmp{Community}=$temp{ro} }
		else
			{ return undef }
	}

	return \%snmp;
}
sub getAuth
{
	# Runs the 'exportDevices' method if $self->{devices} hash ref is undefined
	# and uses that to parse Cli credentials for all other calls.
	my ($self, $args)=@_;

	if(!defined $args->{host})
		{ carp("You must specify a host for getAuth method") && return undef }
	if($args->{refresh})
		{ $self->{devices}=undef }
	if(!defined $self->{devices})
		{ $self->{devices}={exportDevices($self)}};

	$args->{host}=_resolv($args->{host});

	my %creds=();
	my $device=$self->{devices}->{$args->{host}};

	$creds{host}=$device->{dev} || return undef;
	$creds{user}=$device->{cliUsername};
	$creds{pass}=$device->{cliLogin};
	
	return \%creds;
}
sub exportDevices
{
	# Gets credentials for all devices in NetSight as an NGF string and
	# parses it into a hash table
	my ($self)=@_;
	my %table=();

	my $call=$self->{soap}->exportDevicesAsNgf;

	if($call->fault)
		{ carp($call->faultstring) && return undef }

	foreach my $line(split("\n",$call->result))
	{
		my %temp=();
		foreach my $attribute(split(" ",$line))
		{
			if((my @keyval=split("=",$attribute))==2)
				{ $temp{$keyval[0]}=$keyval[1] }
			else
				{ $temp{$keyval[0]}=undef }
		}
		$table{$temp{dev}}=\%temp;
	}

	return $call->result eq ""?undef:\%table;
}
sub ipV6Enabled
{
	my ($self)=@_;
	my $call=$self->{soap}->isIpV6Enabled;

	if($call->fault) 
		{ carp($call->faultstring) && return undef }

	return $call->result eq "true"?1:0;
}
sub netSnmpEnabled
{
	my ($self)=@_;
	my $call=$self->{soap}->isNetSnmpEnabled;

	if($call->fault) 
		{ carp($call->faultstring) && return undef }

	return $call->result eq "true"?1:0;
}

# Methods for adding device data
sub addAuth
{
	my ($self, $args)=@_;
	my @params=qw(username description loginPassword enablePassword configurationPassword type);
	return _call($self, 'addAuthCredentialEx', \@params, $args);
}
sub addSnmp
{
	my ($self, $args)=@_;
	my @params=qw(name snmpVersion communityName userName authPassword authType privPassword privType);
	return _call($self, 'addCredentialEx', \@params, $args);
}
sub addDevice
{
	my ($self, $args)=@_;
	my @params=qw(ipAddress profileName snmpContext nickName);
	return _call($self, 'addDeviceEx', \@params, $args);
}
sub addProfile
{
	my ($self, $args)=@_;
	my @params=qw(name snmpVersion read write maxAccess auth);
	return _call($self, 'addProfileEx', \@params, $args);
}

# Methods for updating
sub updateAuth
{
	my ($self, $args)=@_;
	my @params=qw(username description loginPassword enablePassword configurationPassword type);
	return _call($self, 'updateAuthCredentialEx', \@params, $args);
}
sub updateSnmp
{
	my ($self, $args)=@_;
	my @params=qw(name communityName userName authPassword authType privPassword privType);
	return _call($self, 'updateCredentialEx', \@params, $args);
}
sub updateProfile
{
	my ($self, $args)=@_;
	my @params=qw(name read write maxAccess authCredName);
	return _call($self, 'updateProfileEx', \@params, $args);
}

# Methods for deleting
sub deleteDevice
{
	my ($self, $args)=@_;
	
	if(!defined $args->{host})
		{ carp("You must specify a host for deleteDevice method") && return undef }
	$args->{host}=_resolv($args->{host});
	
	my $call=$self->{soap}->deleteDeviceByIpEx($args->{host});

	if($call->fault)
		{ carp($call->faultstring) && return undef }

	if(_wsresult_error($call->result))
		{ return undef }
	else
		{ return $call->result }
}

# Private
sub _call
{
	# Internal method for making calls with multiple arguments
	# Arguments must be in the correct order and unused arguments
	# must be present but blank. The order of all args needed is specified
	# in $params array and the args specified is in the $args table
	my ($self, $method, $params, $args)=@_;
	my @data;

	foreach my $param(@$params)
		{ push(@data, SOAP::Data->name($param => $args->{$param} || "")) }

	my $call=$self->{soap}->$method(SOAP::Data->value(@data));

	if($call->fault) 
		{ carp($call->faultstring) && return undef }

	if(_wsresult_error($call->result))
		{ return undef }
	else
		{ return $call->result }
}
sub _resolv
{
	# Resolve IP for a hostname
	my ($host)=@_;
	if(eval{$host=inet_ntoa(inet_aton($host))})
		{ return $host }
	else
		{ carp("Unable to resolve host: $host") && return undef }
}
sub _wsresult_error
{
	# Check error code of a WsResult structure, returns 1 on error
	my ($result) = @_;

	if(eval{defined($result->{success})})
	{
		if($result->{success} eq "false")
			{ carp("Error ".$result->{errorCode}.": ".$result->{errorMessage}) && return 1 }
	}
	return 0;
}
1;

# ABSTRACT: Provides an abstraction layer between SOAP::Lite and the Netsight Device WebService.


__END__
=pod

=head1 NAME

Enterasys::NetSight - Provides an abstraction layer between SOAP::Lite and the Netsight Device WebService.

=head1 VERSION

version 1.2

=head1 SYNOPSIS

	use Enterasys::NetSight;
	use Data::Dumper;

	my $netsight = Enterasys::NetSight->new({
				host	=> $ip,
				port	=> $port,
				user	=> $username,
				pass	=> $password,
			}) or die $!;

This module provides wrapper methods for raw API method calls. These methods typically parse the response and return a perl friedly hash table.

You can make any raw API call through the SOAP::Lite object accessable with $netsight->{soap}.
For example the following would print a NetSight Generated Format string containing SNMP credentials,

	print $netsight->{soap}->getSnmpCredentialAsNgf($ip)->result(),"\n";

However using the getSnmp wrapper method will parse the NGF string into a hash table,

	print Dumper $netsight->getSnmp({host=>$ip});

Used with the perl SNMP module you can use the return of that method to create a new SNMP session object,

	my $session=SNMP::Session->new(%{$netsight->getSnmp({host=>$ip})});

Which you could then use to query a mib,

	print $session->get('sysDescr.0');

More examples

Building a profile up

	$netsight->addAuth({
		type		=> 'SSH',
		description	=> 'cli',
		username	=> 'foo',
		loginPassword	=> 'password'
	});
	
	$netsight->addSnmp({
		name		=> 'readonly',
		snmpVersion	=> '3',
		userName	=> 'ro',
		authPassword	=> 'foo',
		authType	=> 'SHA1'
	});
	
	$netsight->addSnmp({
		name		=> 'readwrite',
		snmpVersion	=> '3',
		userName	=> 'rw',
		authPassword	=> 'bar',
		authType	=> 'SHA1'
	});
	
	$netsight->addProfile({
		name		=> 'foo',
		snmpVersion	=> '3',
		read		=> 'readonly',
		write		=> 'readwrite',
		maxAccess	=> 'readwrite',
		auth		=> 'cli'
	});
	
	$netsight->addDevice({
		ipAddress	=> '127.0.0.1',
		profileName	=> 'TestDevice',
		nickName	=> 'Testing'
	});

Getting info about a profile

	print Dumper $netsight->getAuth({host=>127.0.0.1, refresh=>1});
	print Dumper $netsight->getSnmp({host=>'127.0.0.1', level=> ro});
	print Dumper $netsight->getDevice({host=>$ip});

=head1 METHODS

See OF-Connect-WebServices.pdf for details about API calls and complex data types referenced in this doc.

=over

=item new()

Returns a new Enterasys::Netsight object or undef if invalid parameters were specified.

=over

=item host

IP address or hostname of the NetSight server.

=item user

Username with API access.

=item pass

Password for the user.

=item port

Optional port, defaults to NetSight's default port 8443.

=back

=item getSnmp()

Returns a hash table which can be passed as an argument to make a new SNMP::Session with the perl SNMP module. Returns undef if no SNMP creds found.

=over

=item host

IP address or hostname of a target device.

=item level

Optional, defaults to highest privilage level available. Options are su, rw, ro (super user, read/write, read only). If specified privilage does not exist method returns undef. This parameter is ignored if the device has SNMP v3 credentials.

=back

=item getAuth()

Returns a hash table containing CLI credentials: host, user, and pass. Because there is no API call to get a single CLI cred, similar to getSnmpCredentialAsNgf, this method runs the "exportDevices" method once and keeps the device information in memory.

=over

=item host

IP address or hostname of a target device.

=item refresh

Exports devices from the NetSight server and stores an updated copy in memory when set true.

=back

=item getDevice()

Returns a WsDevice hash table containing device information. Shortcut for $netsight->{soap}->getDeviceByIpAddressEx($ip)->result()->{data}. This method will check the return status for errors. Returns undef if no device details found.

=over

=item host

IP address or hostname of a target device.

=back

=item getAllDevices()

Returns a hash table with device IP address keys and hash reference values pointing to
a WsDevice table containing device information. Returns undef on error.

=item exportDevices()

Returns a hash table with device IP address keys and a hash reference to a table containing both
SNMP and/or CLI credentials. This method parses the NetSight Generated Format (NGF) strings returned
from the 'exportDevicesAsNgf' API call. Returns undef on error.

=item addAuth()

Add telnet/SSH authentication credential. Returns undef on error or a NsWsResult object indicating success.

=over

=item username

Username for telnet/SSH access.

=item description

Textual description of the profile (64 char limit).

=item loginPassword

Login password for a telnet/SSH session.

=item enablePassword

Password to access enable mode.

=item configurationPassword

Password to enable configuration mode.

=item type

Type of protocol to use for CLI access, either telnet/SSH.

=back

=item addSnmp()

Add SNMP authentication credential. Returns undef on error or a NsWsResult object indicating success.

=over

=item name

Name for the credential set.

=item snmpVersion

Integer specifying SNMP version 1, 2, or 3.

=item communityName

Community name if SNMP v1/2c is being used.

=item userName

Username if SNMP v3 is being used.

=item authPassword

Authentication password if SNMPv3 is being used.

=item authType

Authentication type if SNMPv3 is being used, either MD5 or SHA1.

=item privPassword

SNMPv3 privacy password if SNMPv3 is being used.

=item privType

Privacy type if SNMPv3 is being used, either DES or AES.

=back

=item addProfile()

Add an access profile. Returns undef on error or a NsWsResult object indicating success. 

=over

=item name

Name for the profile.

=item snmpVersion

Integer specifying SNMP version 1, 2, or 3.

=item read

SNMP read configuration credentials name as created by addSnmp.

=item write

SNMP write configuration credentials name as created by addSnmp.

=item maxAccess

Credentials configuration to use maximum access mode to the device. Name as created by addSnmp.

=item auth

Telnet/SSH authentication credentials used in this profile. Name as created by addAuth.

=back

=item addDevice()

Add a device to the NetSight database. Returns undef on error or a NsWsResult object indicating success.

=over

=item ipAddress

IP address of the device to add.

=item profileName

Name of the access profile used to poll the device.

=item snmpContext

An SNMP context is a collection of MIB objects, often associated with a network entity. The SNMP context lets you access a subset of MIB objects related to that context. Console lets you specify a SNMP Context for both SNMPv1/v2 and SNMPv3. Or empty for no Context.

=item nickName

Common name to use for the device. Empty for no name.

=back

=item updateAuth()

Update existing telnet/SSH credentials. Returns undef on error or a NsWsResult object indicating success.

=over

=item username

Username for telnet/SSH access.

=item description

Textual description of the profile (64 char limit).

=item loginPassword

Login password for a telnet/SSH session.

=item enablePassword

Password to access enable mode.

=item configurationPassword

Password to enable configuration mode.

=item type

Type of protocol to use for CLI access, either telnet/SSH.

=back

=item updateSnmp()

Update existing SNMP credentials. Returns undef on error or a NsWsResult object indicating success.

=over

=item name

Name for the credential set.

=item communityName

Community name if SNMP v1/2c is being used.

=item userName

Username if SNMP v3 is being used.

=item authPassword

Authentication type if SNMPv3 is being used.

=item authType

Authentication type if SNMPv3 is being used, either MD5 or SHA1.

=item privPassword

SNMPv3 privacy password if SNMPv3 is being used.

=item privType

Privacy type if SNMPv3 is being used, either DES or AES.

=back

=item updateProfile()

Update existing access profile. Returns undef on error or a NsWsResult object indicating success.

=over

=item name

Name for the profile.

=item read

SNMP read configuration credentials name as created by addSnmp.

=item write

SNMP write configuration credentials name as created by addSnmp.

=item maxAccess

Credentials configuration to use maximum access mode to the device. Name as created by addSnmp.

=item authCredName

Telnet/SSH authentication credentials used in this profile. Name as created by addAuth.

=back

=item ipV6Enabled()

Returns 1 if NetSight is configured for IPv6, 0 if not, undef on error. Shortcut for $netsight->{soap}->isNetSnmpEnabled.

=item netSnmpEnabled()

Returns 1 if NetSight is using the Net-SNMP stack, 0 if not, undef on error. Shortcut for $netsight->{soap}->netSnmpEnabled.

=back

=head1 AUTHOR

Chris Handwerker <chandwer@enterasys.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Handwerker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

