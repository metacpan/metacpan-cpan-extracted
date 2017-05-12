#!/usr/bin/perl

#######################################################################
# Created on:  Dec 2, 2005
# Package:     HoneyClient::Manager::FW
# File:        FW.pm
# Description: A SOAP server that provides a way to remotely and dynamically configure iptables rules for all honeyclients.
#
# @author(s) durick, kindlund, xkovah
#
# SVN: $Id: FW.pm 796 2007-08-07 16:36:16Z kindlund $
#
# Copyright (C) 2007 The MITRE Corporation.  All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, using version 2
# of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#
#######################################################################

=pod

=head1 NAME

HoneyClient::Manager::FW - Perl module to remotely handle firewall rule/chain creation and deletion
which will provide network connectivity for the honeyclients during crawling.  Additionally,
it will provide protection when the honeyclients become compromised by enabling static rate limiting(tcp/udp/icmp)
and MAC address filtering.

=head1 VERSION

This documentation refers to HoneyClient::Manager::FW version 0.99.

=head1 SYNOPSIS

=head2 CREATING THE SOAP SERVER

  # Make sure HoneyClient::Util::Config loads properly
use HoneyClient::Util::Config qw(getVar);

# Make sure IPTables::IPv4 loads
use IPTables::IPv4;

# Make sure HoneyClient::Manager::FW can load
use HoneyClient::Manager::Firewall::FW;

# Make sure HoneyClient::Util::SOAP loads properly
require_ok('HoneyClient::Util::SOAP');

package HoneyClient::Manager::Firewall::FW;
use HoneyClient::Util::SOAP qw(getClientHandle getServerHandle);
my $daemon = getServerHandle();
$daemon->handle;

The SOAP firewall server will  boot up when the honeywall is started by the HoneyClient manager.  The main
directory that holds all the listener code is the /hc directory.  startFWListener.pl is located in the /etc/rc.d/rc3.d directory and
will boot up when the honeywall starts up in run level three.  After start up, the firewall listener will await calls from the HoneyClient
manager so that the firewall may be configured properly and dynamically updated when crawling begins.

Steps to get honeyclient listening:

1.  Boot up honeyclient honeywall vmware image.
2.  Start up our SOAP firewall and SOAP log listener
/usr/bin/perl /hc/startFWListener.pl > /dev/null 2> /dev/null &
These will start upon boot of the honeywall so you will not have to do anything except boot the image.
3.  Now the firewall is listening for all SOAP client calls
4.  Do a "ps -xf" to confirm that your firewall is listening
    It should show something like:
    7580 pts/0    S      0:01 /usr/bin/perl /hc/startFWListener.pl
5.  Make your FW calls now from honeyclient-client.pl.

=head2 INTERACTING WITH SOAP SERVER

 use HoneyClient::Util::SOAP qw(getClientHandle);
 use HoneyClient::Util::Config qw(getVar);

After the honeywall boots up, startFWListerner.pl will be executed and begin listening.  From
here we want to start interacting with our SOAP FW server.

 # Create a new SOAP client, to talk to the HoneyClient::Manager::FW module
 # @initlist will contain all the return values sent back from the server (PID of startFWListerner.pl on server and status message)
 #  Lets set our default honeyclient ruleset:
  my $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
  my $som = $stub->fwInit();
  my @initlist = $som->paramsall;
  print "$_\n" foreach (@initlist);

 # To dynamically append new rules to the iptables ruleset, do the following
$hashref = this data structure will be passed from the manager to the HoneyClient::Manager::FW

 $som = $stub->addRule( $hashref );
 print $stub->result;
 print "\n";

# To dynamically delete rules, all you need to do is delete the user-defined chain that was originally created.

$som = $stub->deleteChain( $hashref );
print $stub->result;
print "\n";

# To get the status of the current iptables ruleset, this function prints to hard disk the working iptables ruleset
$som = $stub->getStatus();
print $stub->result;
print "\n";

# For all new VM's that we plan to add later on, we will have to add new VM chains:
$som = $stub->addChain( $hashref);
print $stub->result;
print "\n";

 # To shutdown the Firewall SOAP listner on the Honeywall
$som = $stub->FWShutdown();
print $stub->result;
print "\n";

=head1 DESCRIPTION

Once created, the daemon acts as a stand-alone SOAP server,
processing individual requests from the  HoneyClient manager
and manipulating the IPTables ruleset on the transparent
virtual honeywall.

=cut

package HoneyClient::Manager::FW;
require Exporter;    #  packages allow a program to be partitioned into separate namespaces

# Include HoneyClient libraries
use HoneyClient::Util::Config qw(getVar);
use HoneyClient::Util::SOAP qw(getServerHandle getClientHandle);

#use HoneyClient::Manager::FW::Argus;
#use HoneyClient::Manager::FW::Tcpdump;
#use HoneyClient::Manager::FW::Integrity;

# Include logging library
use Log::Log4perl qw(get_logger);

# Threading libraries
use threads;
use threads::shared;

# Additional libraries needed
use FileHandle;
use IO::File;
use IPTables::IPv4;
use Config::General;
use Data::Dumper;
use POSIX qw( WIFEXITED );
use English '-no_match_vars';

# set our configuration file location
my $config_file = getVar(name => "config_file");

# starting up the logging mechanism
Log::Log4perl->init($config_file);

=begin testing

diag("Beginning of HoneyClient::Manager::FW testing.");
diag("Making sure all Modules are present");

# Make sure Log::Log4perl loads.
BEGIN { use_ok('Log::Log4perl') or diag("Can't load Log::Log4perl package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Log::Log4perl');
use Log::Log4perl;

# Make sure Filehandle loads.
BEGIN { use_ok('FileHandle') or diag("Can't load FileHandle package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('FileHandle');
use FileHandle;

# Make sure IO::File loads.
BEGIN { use_ok('IO::File') or diag("Can't load IO::File package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('IO::File');
use IO::File;

# Make sure IPTables::IPv4 loads.
BEGIN { use_ok('IPTables::IPv4') or diag("Can't load IPTables::IPv4 package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('IPTables::IPv4');
use IPTables::IPv4;

# Make sure Config::General loads.
BEGIN { use_ok('Config::General') or diag("Can't load Config::General package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Config::General');
use Config::General;

# Make sure use Data::Dumper loads.
BEGIN { use_ok('Data::Dumper') or diag("Can't load use Data::Dumper package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure use Net::DNS::Resolver loads.
BEGIN { use_ok('Net::DNS::Resolver') or diag("Can't load use Net::DNS::Resolver package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Net::DNS::Resolver');
use Net::DNS::Resolver;

# Make sure use Time::HiRes loads.
BEGIN { use_ok('Time::HiRes', qw(gettimeofday)) or diag("Can't load use Time::HiRes package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Time::HiRes');
can_ok('Time::HiRes', 'gettimeofday');
use Time::HiRes qw(gettimeofday);

# Make sure use English loads.
BEGIN { use_ok('English') or diag("Can't load use English package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('English');
use English '-no_match_vars';

# Make sure use threads loads.
BEGIN { use_ok('threads') or diag("Can't load use threads package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('threads');
use threads;

# Make sure HoneyClient::Util::Config loads.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar)) or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
use HoneyClient::Util::Config qw(getVar);

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Manager::FW', qw(init_fw destroy_fw _getVMName)) or diag("Can't load HoneyClient::Manager:VM package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Manager::FW');
can_ok('HoneyClient::Manager::FW', 'init_fw');
can_ok('HoneyClient::Manager::FW', 'destroy_fw');
can_ok('HoneyClient::Manager::FW', '_getVMName');
use HoneyClient::Manager::FW qw(init_fw destroy_fw _getVMName);

# Make sure HoneyClient::Util::SOAP loads.
BEGIN { use_ok('HoneyClient::Util::SOAP', qw(getServerHandle getClientHandle)) or diag("Can't load HoneyClient::Util::SOAP package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::SOAP');
can_ok('HoneyClient::Util::SOAP', 'getServerHandle');
can_ok('HoneyClient::Util::SOAP', 'getClientHandle');
use HoneyClient::Util::SOAP qw(getServerHandle getClientHandle);

# Make sure use Proc::ProcessTable loads.
BEGIN { use_ok('Proc::ProcessTable') or diag("Can't load use Proc::ProcessTable package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Proc::ProcessTable');
use Proc::ProcessTable;

diag("Making sure perl and shell scripts exist.\n");
ok( "-f /hc/startFWListener.pl", '/hc/startFWListener.pl is present' );
ok( "-f /hc/startLogListener.pl", '/hc/startLogListener.pl is present' );
ok( "-f /hc/startFWListener.sh", '/hc/startFWListener.sh is present' );
ok( "-f /hc/startLogListener.sh", '/hc/startLogListener.sh is present' );
ok( "-f  /etc/honeylog.conf", '/etc/honeylog.conf is present' );
ok("-f  /etc/honeyclient.conf", '/etc/honeyclient.conf exists');
#ok( -f , "/proc/sys/net/ipv4/ip_forward", '/proc/sys/net/ipv4/ip_forward does exist');
ok(" -f /etc/resolv.conf", '/etc/resolv.conf file does exist');
ok(" -f /etc/syslog.conf", '/etc/syslog.conf file does exist');
ok( "-f /usr/bin/uptime", '/usr/bin/uptime is present' );
ok(" -f /bin/uname", '/bin/uname exists');
ok(" -f /bin/mail", 'mail() exists');
ok(" -f /sbin/iptables", 'IPTables binary does exist');
diag("Enabling test hash reference here");
my $hashref = {

    'foo' => {
        'targets' => {
            'rcf.mitre.org'   => { 'tcp' => [ 80 ], },
        },

        'resources' => {
            'http://www.mitre.org' => 1,
        },
        'sources' => {

            '00:0C:29:94:B9:15' => {
                '10.0.0.128' => {
                    'tcp' => undef,
                    'udp' => [ 23, 53, '80:1024', ],
                },
            },
        },
    },
};

#my $hwall = getVar(name => "address");
#my $port = getVar(name => "port");

diag("Beginning our function testing now...");
$URL = HoneyClient::Manager::FW->init_fw();
is($URL, "http://192.168.0.129:8083/", "testing init_fw(), creation of the firewall server") or diag("Failed to start up the FW SOAP server.  Check to see if any other daemon is listening on TCP port $PORT.");
sleep 3;
is(HoneyClient::Manager::FW->destroy_fw(), 1, "destroy_fw(), destruction of the firewall server") or diag("Unable to terminate FW");
sleep 1;

=end testing

# This package name.
our $PACKAGE = __PACKAGE__;
our $DAEMON_PID : shared = undef;
# Complete URL of SOAP server, when initialized.
our $URL_BASE;
our $URL;
our $UPTIME = "/usr/bin/uptime";


BEGIN {

	# Defines which functions can be called externally.
	require Exporter;
	our ( @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION );

	# Set our package version.
	$VERSION = 0.99;

	@ISA = qw(Exporter);

	# Symbols to export automatically
	@EXPORT =
	  qw( _parseHash _validateInit init_fw destroy_fw _doFullBackup _flushChains _setAcceptPolicy _setDefaultDeny _set_log_rules _setstaticrate _setDefaultRules _remoteConnection _set_ip_forwarding _getpid);

	# Items to export into callers namespace by default. Note: do not export
	# names by default without a very good reason. Use EXPORT_OK instead.
	# Do not simply export all your public functions/methods/constants.

	# This allows declaration use HoneyClient::Manager::FW ':all';
	# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
	# will save memory.

	%EXPORT_TAGS = ( 'all' => [qw(init_fw destroy_fw)], );

	# Symbols to autoexport (when qw(:all) tag is used)
	@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

	$SIG{PIPE} = 'IGNORE';    # Do not exit on broken pipes.
}


=pod

=head1 EXTERNAL SOAP FUNCTIONS

=over 4

=item *

fwInit()

The fwInit function awaits a call from the Honeyclient manager, once a call is made the function performs numerous subfunctions but
mainly handles creation of the default iptables ruleset for the honeyclient network.
IPTables ruleset:
Since we are using our honeywall to do transparent packet forwarding, forwarded packets will be traversing the
IPTables FORWARD chain, which is associated with the filter table.  By adding rules to the FORWARD chain, you
can control the flow of traffic between our two networks (honeyclient and external network).
Instead of using a single, built-in chain for all protocols, we use a user-defined chain to determine the protocol type,
then hand off the actual final processing to our user-defined chain in the filter table.


I<Inputs>: nothing - No specific input
I<Output>: Success if default ruleset was created, failure if not

#=back

=begin testing

eval{
	diag("Testing fwInit()...");
    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep(1);
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    $som = $stub->fwInit($hashref);
    $som = $stub->_validateInit();
    is($som->result, 24, "fwInit current has set up 28 rules")   or diag("The fwInit() call failed.");
    $som = $stub->_setAcceptPolicy();
    $som = $stub->_flushChains();

};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep(1);

# Report any failure found.
if ($@) {
    fail($@);
}

=end testing

=cut

sub fwInit {
	my ($class) = shift();
	my ($systempid, $f_success, $del_success, $acceptsuccess, $denysuccess,
		$chain)
	  = q{};
	my @default_chains = qw(INPUT OUTPUT FORWARD);
	my $outputdir      = getVar(name => "outputdir");
	my $processname    = "startFWListener.pl";
	my $table          = IPTables::IPv4::init('filter');


	#$systempid = _getpid($processname);
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering fwInit(), starting Firewall initialization...");

	# Could not connect to iptables
	if (!defined($table)) {
		$log->error_die("Error, could not connect to IPTABLES interface: $!");
		return(0);
	} else {
		$log->info("table is defined");
		# lets check for root access, the honeyclient can only be run as root
		my $root = _checkRoot();
		if (!$root) {
			$log->error_die("Error, you must be root to run this program: $!");
		}

# loads the interfaces in the /etc/interfaces.conf file - might be used later???
#	_load_interfaces();
# Peform a full backup of the existing rules
# TODO: Uncomment and resolve this, eventually.
# It has been disabled for now, since it was filling up system space on the
# Honeywall VM.
#       _doFullBackup($outputdir);

# set ip forwarding to 0.  The script initially turns all forwarding off while it loads the firewall policy.
# Then, right before the script exits, the script turns forwarding back on.
		_set_ip_forwarding(0);

		# Sets accept all policy, return $acceptsuccess code
		_setAcceptPolicy();

		# flush and delete all existing chains/rules - starting clean
		_flushChains();

# Now lets set our default deny all policy, this drops all traffic for INPUT, FORWARD, and OUTPUT
		_setDefaultDeny();


		#  Create a Drop_Log_* user-defined chain, for logging packets before dropping them
		_createDropLog("Drop_Log_In", "INPUT: ");
		_createDropLog("Drop_Log_Out", "OUTPUT: ");
		_createDropLog("Drop_Log_Fwd", "FORWARD: ");

		# Now creating all rules for INPUT/OUTPUT/FORWARD chains
		_setDefaultRules();

# Creates a nat rule in the POSTROUTING chain.  The nat POSTROUTING chain performs
# source network address translation and masquerading.  The chain can contain rules that modify
# the source IP address or source port of packets that traverse it.  We do not use this chain for
# any filtering.
		_createNat();

		# sets up ip forwarding to active
		_set_ip_forwarding(1);
		my $totalRules = _validateInit();
		return $totalRules;
	}
}    # end of setup subroutine

=pod

=item *

_validateInit() is another helper function

I<Inputs>:  no input
I<Output>: total number of rules across all chains (Default and user-defined)

=cut

sub _validateInit {
	my $table     = IPTables::IPv4::init('filter');
	my $natTable  = IPTables::IPv4::init('nat');
	my @chainList = qw(INPUT OUTPUT FORWARD Drop_Log);
	my @natChains = qw(PREROUTING POSTROUTING);
	my (@ruleList, @natList) = ();
	my ($numRules, $natRules, $totalRules) = q{};
	foreach my $chain (@chainList) {
		if (!$table->is_chain($chain)) {
			my $filter = 0;
		} else {
			@ruleList = $table->list_rules($chain);
			$numRules = scalar(@ruleList);
			print "Number of rules in $chain:  $numRules\n";
			$totalRules += $numRules;
		}
	}
	foreach my $natChain (@natChains) {
		if (!$natTable->is_chain($natChain)) {
			my $nat = 0;
		} else {
			@natList  = $natTable->list_rules($natChain);
			$natRules = scalar(@natList);
			print "Number of rules in $natChain:  $natRules\n";
			$totalRules += $natRules;
		}
	}
	return $totalRules;
}

=pod

=item *

_parseHash() is another helper function that takes in a hash reference from the honeyclient
manager and parses the data structure thus producing usable values to generate our firewall rules.

I<Inputs>:  Requires hash reference (hohohohoh).
I<Output>: returns hash of a hash to be used during  the addRule() function for rule generation.

=cut

sub _parseHash {
	my @temp = ();
	my %HoH  = ();

	# Extract arguments.
	my ($hashref) = @_;

	# Get the VM identifier.
	foreach $vm_ID (keys %{$hashref}) {

		# Get the VM's source MAC address.
		foreach $src_MAC_addr (keys %{ $hashref->{$vm_ID}->{'sources'} }) {

			# Get the VM's source IP address.
			foreach $src_IP_addr (
					 keys %{ $hashref->{$vm_ID}->{'sources'}->{$src_MAC_addr} })
			{

				# Get the VM's source protocol.
				foreach $src_IP_proto (
							keys %{
								$hashref->{$vm_ID}->{'sources'}->{$src_MAC_addr}
								  ->{$src_IP_addr}
							}
				  )
				{

		  # Get the VM's source ports.
		  # For this case, we can't use foreach, since we have to also factor in
		  # cases where the array of ports is 'undef'.
		  # Get the list of ports.
					my @src_ports = ();
					if (
						defined(
								$hashref->{$vm_ID}->{'sources'}->{$src_MAC_addr}
								  ->{$src_IP_addr}->{$src_IP_proto}
						)
					  )
					{
						@src_ports =
						  @{ $hashref->{$vm_ID}->{'sources'}->{$src_MAC_addr}
							  ->{$src_IP_addr}->{$src_IP_proto} };
					}

					# Figure out how big the array is.
					my $num_of_src_ports = scalar(@src_ports);
					my $src_port_counter = 0;
					my $src_port         = undef;
					do {

						# We check to see if our source port array
						# is empty.
						if ($num_of_src_ports <= 0) {
							$src_port = "*";
						} else {
							$src_port = $src_ports[$src_port_counter];
						}

						# Get the target hosts.
						foreach $dst_host (
									  keys %{ $hashref->{$vm_ID}->{'targets'} })
						{

							# Get the target IPs.
							foreach $dst_IP_addr (_resolveHost($dst_host)) {

								# Get the target protocol.
								foreach $dst_IP_proto (
											 keys %{
												 $hashref->{$vm_ID}->{'targets'}
												   ->{$dst_host}
											 }
								  )
								{

		 #print STDERR "Destination Protocol: " . $dst_IP_proto . "\n";
		 # We skip over combinations, where the source and destination protocols
		 # are different.
									next
									  unless $src_IP_proto eq $dst_IP_proto;

		  # Get the target ports.
		  # For this case, we can't use foreach, since we have to also factor in
		  # cases where the array of ports is 'undef'.
		  # Get the list of ports.
									my @dst_ports = ();
									if (
										defined(
												$hashref->{$vm_ID}->{'targets'}
												  ->{$dst_host}->{$dst_IP_proto}
										)
									  )
									{
										@dst_ports =
										  @{ $hashref->{$vm_ID}->{'targets'}
											  ->{$dst_host}->{$dst_IP_proto} };
									}

									# Figure out how big the array is.
									my $num_of_dst_ports = scalar(@dst_ports);
									my $dst_port_counter = 0;
									my $dst_port         = undef;
									do {

								 # We check to see if our destination port array
								 # is empty.
										if ($num_of_dst_ports <= 0) {
											$dst_port = "*";
										} else {
											$dst_port =
											  $dst_ports[$dst_port_counter];
										}

		   # generate our rules here into a %HoH based on destination ip address
										$HoH{$dst_IP_addr} = {
											"chain"       => "$vm_ID",
											"source-mac"  => "$src_MAC_addr",
											"source"      => "$src_IP_addr",
											"protocol"    => "$src_IP_proto",
											"source-port" => "$src_port",
											"destination-domain" => "$dst_host",
											"destination" => "$dst_IP_addr",
											"dest-proto"  => "$dst_IP_proto",
											"destination-port" => "$dst_port",
											"jump"             => "ACCEPT",
											"matches"          => ['mac']
										};
										$dst_port_counter++;
									  } until (
										$dst_port_counter >= $num_of_dst_ports);
								}
							}
						}
						$src_port_counter++;
					} until ($src_port_counter >= $num_of_src_ports);
				}
			}
		}
	}
	return %HoH;
}

=pod

=item *

addChain();

add_vm_chain adds the user-defined chain based on manager client parameters.

I<Inputs>:
B<$class>is the package name
B<$hashref> - hash reference that will be sent over from HoneyClient::Agent.  It will then be parsed by get_vm_from_hash()
and give me an array of VM names that will be added from the iptables chain list.  The reason we have broken
add_vm_chain() up and made it its separate subroutine is because when we add a rule to the iptables ruleset, we
must first have a user-defined chain in place.  A commit must occur which writes it to the kernel-level netfilter subsystem, then
the rule must be added after that has occurred.

I<Output>: returns true if VM chain was deleted, returns false if not

#=back

=begin testing

eval{
	diag("Testing addChain()...");
    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep 1;
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    $som = $stub->addChain($hashref);
    ok($som->result, "addChain() successfully passed.")   or diag("The addChain() call failed.");
    $som = $stub->_setAcceptPolicy();
    $som = $stub->_flushChains();
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep 1;

# Report any failure found.
if ($@) {
    fail($@);
	}

=end testing

=cut

sub addChain {
	my ($class) = shift;    # pass in package name
	my $hashref =
	  shift;    # pass in hash reference which is sent from HoneyClient::Agent
	my $log   = get_logger("HoneyClient::Manager::FW");
	my $table = IPTables::IPv4::init('filter');
	my ($vmlistin, $vmlistout, $vinret, $voutret) = q{};

# get_vm_from_hash() returns the VM name of the hash reference.  For now, one VM md5sum value
# will be passed in one hashref.
	$vmname = _getVMName($hashref);

	# lets modify the vmnames to apply to "-IN" and "-OUT" flows
	my $vin  = $vmname . "-IN";
	my $vout = $vmname . "-OUT";

  # Lets loop through the array contain all "-in" VM chain names and create them
	if ($table->is_chain($vin)) {
		$log->info("Sorry, $vin already exists - no chain was created");
		$vinret = 0;
	} else {
		$log->info("$vin was not found and created");
		$table->create_chain($vin) or
            die ("Error: Unable to create chain $vin");

		# the entry will be inserted to the head of the FORWARD chain (0)
		$table->insert_entry("FORWARD", { 'protocol' => "tcp", jump => $vin },
							 0) or
            die ("Error: Unable to insert entry into chain FORWARD");
		$log->info("Inserting rule in FORWARD chain to point to $vin");
		$vinret = 1;
	}

 # Lets loop through the array contain all "-out" VM chain names and create them
	if ($table->is_chain($vout)) {
		$log->info("Sorry, $vout already exists and was not created");
		$voutret = 0;
	} else {
		$log->info("$vout chain was was not found and created");
		$table->create_chain($vout) or
            die ("Error: Unable to create chain $vout");

		# the entry will be inserted to the head of the FORWARD chain (0)
		$table->insert_entry("FORWARD", { 'protocol' => "tcp", jump => $vout },
							 0) or
            die ("Error: Unable to insert entry into chain FORWARD");
		$voutret = 1;
	}

	# write to the iptables ruleset
	$log->info("Commiting all rules in addChain() function");
	$table->commit() or die ("Error: Unable to commit changes to filter table");
	return ($vinret, $voutret);
}

=pod

=item *

deleteChain();

delete_vm_chain deletes the user-defined chain based on manager client parameters.

I<Inputs>:
B<$class>is the package name
B<$hashref> - hash reference that will be sent over from HoneyClient::Agent.  It will then be parsed by get_vm_from_hash()
and give me an array of VM names that will be deleted from the iptables chain list.

I<Output>: returns true if VM chain was deleted, returns false if not

=begin testing

eval{
	 diag("Testing deleteChain()...");
    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep 1;
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    $som = $stub->addChain($hashref);
    sleep 1;
    $som = $stub->deleteChain($hashref);
    ok($som->result, "deleteChain() successfully passed.")   or diag("The deleteChain() call failed.");
    $som = $stub->_setAcceptPolicy();
    $som = $stub->_flushChains();

};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep 1;

# Report any failure found.
if ($@) {
    fail($@);
	}

=end testing

=cut

sub deleteChain {
	my ($class)      = shift;
	my ($hashref)    = shift;
	my $table        = IPTables::IPv4::init('filter');
	my @forwardrules = $table->list_rules("FORWARD");
	my $vmname       = _getVMName($hashref);
	my @chainArray   = ();
	my $log   = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering deleteChain()...");

	# concatenate vm names to specify in and out chains
	my $vin  = $vmname . "-IN";
	my $vout = $vmname . "-OUT";
	push(@chainArray, $vin);
	push(@chainArray, $vout);

# Within this loop, we are deleting the rules within the FORWARD chain, since our chain is
# user-defined, we also has a rule within the FORWARD chain that points to the next chain but
# we need to delete this rule too.  This loop applies the user-defined "in" chain.
    $log->info("Starting to loop all the rules in the FORWARD chain");
	for (my $i = 0 ; $i <= $#forwardrules ; $i++) {

		# if there is a match, delete it
		if (   ($forwardrules[$i]->{'protocol'} eq "tcp")
			&& ($forwardrules[$i]->{'jump'} eq $vin))
		{
			$log->info("Deleting rule in FORWARD chain where jump is $vin");
			$table->delete_entry("FORWARD", $forwardrules[$i]) or
                die ("Error: Unable to delete entry in chain FORWARD");
			print "deleting $forwardrules[$i] in FORWARD chain\n";
		} else {
			print "No match with the rules, keep looking\n";
		}
	}

# Within this loop, we are deleting the rules within the FORWARD chain, since our chain is
# user-defined, we also has a rule within the FORWARD chain that points to the next chain but
# we need to delete this rule too.  This loop applies the user-defined "out" chain.
	for (my $j = 0 ; $j <= $#forwardrules ; $j++) {
		if (   ($forwardrules[$j]->{'protocol'} eq "tcp")
			&& ($forwardrules[$j]->{'jump'} eq $vout))
		{
			$log->info("Deleting rule in FORWARD chain where jump is $vout");
			$table->delete_entry("FORWARD", $forwardrules[$j]) or
                die ("Error: Unable to delete entry in chain FORWARD");
		} else {
			print "No match with the rules, keep looking\n";
		}
	}

# Flush the entry and delete the chain here
# This deletes all the rules within that chain first, then deletes the actual chain last.
$log->info("Flushing the entries and chains now...");
	foreach my $chainname (@chainArray) {
		$log->info("Flusing entries in $chainname");
		$table->flush_entries($chainname) or
            die ("Error: Unable to flush entries in chain $chainname");
		$log->info("Deleting $chainname");
		$table->delete_chain($chainname);
            die ("Error: Unable to delete chain $chainname");
	}
	$table->commit() or die ("Error: Unable to commit changes to filter table");
}

#Deletes the rules that it would have added for a given hashref in a given custom chain
sub deleteRules(){
my ($class)      = shift;
my ($hashref)    = shift;
my $vmname       = _getVMName($hashref);
my @chainArray   = ();
my $table        = IPTables::IPv4::init('filter');
my $result 		 = 0;

#	print Dumper($table)
	# concatenating chain name to handle "in" chain flow and "out" chain flow
	$vin  = $vmname . "-IN";
	$vout = $vmname . "-OUT";

	$result = $table->flush_entries($vin);
	if($result){
		print "flushed entries from $vin\n"
	}
	else{
        die ("Error: Unable to flush entries in chain $vin");
		print "flush on $vin failed\n";
		return $result;
	}

	$result = $table->flush_entries($vout);
	if($result){
		print "flushed entries from $vout\n";
	}
	else{
        die ("Error: Unable to flush entries in chain $vout");
		print "flush on $vout failed\n";
		return $result;
	}

	$table->commit() or die ("Error: Unable to commit changes to filter table");
	# Lets delete our PREROUTING logging
	$result = _deletePreroutingLogging($hashref, $vmname);
	print "got $result in deleteRules\n";
	return $result;
}

=pod

=item *

addRule($hashref)

addRule is a function that handles the addition of a new iptable rule into the existing IPTables ruleset which allow honeyclients functionality to crawl
the internet in search of malicious web sites.  FWPunch first checks for the existance of the user-defined chain before it
creates a new VM rule.  If the chain already exists, the rule can not be added since their is no corresponding chain.
If it does exist, the rule is added successfully.  All FWPunch calls are logged.

The addRule() function will recieve a $hashref which will be a muli-level hash table whose structure
will resemble the below data structure:

my $hashref = {

    '0d599f0ec05c3bda8c3b8a6' => {    # VM identifier.
        # You'll notice that we add a new layer to the table.
        # This is an MD5SUM that represents the unique identifier
        # of the VM *NAME*.  You can assume that this name will be
        # initially generated and used by HC::Manager::VM.

        # The next 2 keys contain the data from HC::Agent::Driver->next()
        'targets' => {    # This keyname used to be called 'servers'

            # The browser will contact 'www.mitre.org' at
            # TCP port 80.
            'www.mitre.org'   => { 'tcp' => [ 80 ], },
            'rcf.mitre.org'   => { 'tcp' => [ 80 ], },
            'blogs.mitre.org' => { 'tcp' => [ 80 ], },
            'www.cnn.com'     => { 'tcp' => [ 80, 8080 ], },
            'pool.ntp.org'    => { 'udp' => [ 123, ], },

            # General example:
            # The application will contact '192.168.1.1' at
            # some unknown TCP port.
            #
            # If the ports are unknown, the firewall
            # should allow outbound contact to all unprivileged
            # ports (1025-65535) on the specified server. (Yes, I
            # realize in reality, there's an upstream DMZ firewall
            # blocking this functionality; this is simply an
            # architectural design, for now.)
            #'192.168.1.1' => { 'tcp' => "undef", },

            # Or, more generically:
            #'hostname_or_IP' => {
            #    'protocol_type' => [ portnumbers_as_list ],
            #},

        },

        'resources' => {

            # This hashtable contains a list of key, value pairs
            # that reflect the list of resources that the driver
            # will contact next. For browsers, this means URLs.
            # The (1) value is simply a numerical
            # placeholder that serves no purpose, for now.
            'http://www.mitre.org' => 1,
        },

        # Now, we expect HC::Manager to add this next key.
        # This sub-hashtable contains all the source IPs, ports,
        # and protocols that the VM will use to make its outbound
        # connection to remote resources.
        'sources' => {

            '00:04:23:08:7d:54' => { # The VM's MAC address.

                '10.0.0.128' => {    # The VM's internal IP.

                    # In most cases, a VM will only _have_ one
                    # NAT-ted IP.  However, this format allows for the
                    # remote possibility that a VM may have multiple
                    # virtual NICs or multiple IP aliases, in which case
                    # the VM may have multiple source IPs.

                    'tcp' => undef,

                    # We use the same protocol => port syntax as described
                    # before.  Again, if the value is 'undef', then that
                    # indicates that the VM may use any unprivileged port
                    # locally inside its OS, when initiating outbound
                    # communication to the remote resource.

                    'udp' => [ 23, 53, '80:1024', ],
                },
            },
        },
    },
};

I<Inputs>:
B<$class> is the package name.
B<$hashref>

I<Output>: Return true if success or false if failure

=back

=begin testing

eval{
     diag("Testing addRule()...");
    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep 1;
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    my $som  = $stub->fwInit($hashref);
    $som = $stub->addChain($hashref);
    $som = $stub->addRule($hashref);
    ok($som->result, "addRule() successfully passed and added a new rule.")   or diag("The addRule() call failed.");
    $som = $stub->_setAcceptPolicy();
    $som = $stub->_flushChains();
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep 1;

# Report any failure found.
if ($@) {
    fail($@);
	}

=end testing

=cut

sub addRules {
	use Time::HiRes qw(gettimeofday);

	#	my ( $class, $dest, $port, $source, $protocol, $vmnum ) = @_;
	my ($class)   = shift;
	my ($hashref) = shift;
	my $table     = IPTables::IPv4::init('filter');
	my ($log, $vin, $vout) = q{};
	my $counter = 0;
	my %rules   = ();

 #start represents the time at which we starting to time our addChain() function
	my $start = gettimeofday();

	# debugging options, automatically logs to logfile for review later
	$log = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering addRule() function()");

	# getst the Chain name for which we will be inserting new rules on the fly
	$log->info("Getting VM name from _getVMName()");
	$vmname = _getVMName($hashref);

	# Lets create our PREROUTING logging
	_createPreroutingLogging($hashref, $vmname);

	# concatenating chain name to handle "in" chain flow and "out" chain flow
	$vin  = $vmname . "-IN";
	$vout = $vmname . "-OUT";

# testing to make sure the chain actaully exists before we starting inserting our rules
	if ($table->is_chain($vin) && $table->is_chain($vout)) {
		$log->info("Chain $vin and $vout exists");
		print "Chain $vin and $vout exists\n";

# pass back HoH specific to each destination ip address, from this hash we will create our rules
# for both "$vin" and "$vout"
#_parseHash is a helper function that parses the $hashref sent over from the HoneyClient::Agent
# to the Honeyclient manager.  The manager is the one actually sending the hashref from which we are
# parsing.
    	$log->info("[addRule]:  parsing hashref and returning %rules");
		my %rules = _parseHash($hashref);
		print Dumper(\%rules);

# creating the Drop_Log rule at the end of the new chain for both $vin and $vout
# There is an assumption that $vin and $vout have already been create and do exist
#		_installDroplog($vin);
#		_installDroplog($vout);
#my $state = [ 'ESTABLISHED', 'RELATED' ];
# start looping through our HoH
		for $destip (keys %rules) {

	   # inserting the firewall rules into the "out" chain here.
	   # The insertion will be at the head of the chain due to the "0" location.
			my $success =
			  $table->insert_entry(
					$vout,
					{
					  "protocol"         => $rules{$destip}{'protocol'},
					  "source"           => $rules{$destip}{'source'},
					  "destination"      => $rules{$destip}{'destination'},
					  "jump"             => $rules{$destip}{'jump'},
					  "mac-source"       => $rules{$destip}{'source-mac'},
					  "matches"          => $rules{$destip}{'matches'},
					  "destination-port" => $rules{$destip}{'destination-port'}
					},
					0
			  );
            if (!$success) {
                die ("Error: Unable to insert entry in chain $vout");
            }

			# inserting the firewall rules into the "in" chain here.
			$success =
			  $table->insert_entry(
								  $vin,
								  {
									"protocol" => $rules{$destip}{'protocol'},
									"source" => $rules{$destip}{'destination'},
									"destination" => $rules{$destip}{'source'},
									"jump"        => $rules{$destip}{'jump'}
								  },
								  0
			  );
            if (!$success) {
                die ("Error: Unable to insert entry in chain $vin");
            }
			$counter++;
		}
		$table->commit() or die ("Error: Unable to commit changes to filter table");
		my $end         = gettimeofday();
		my $addruletime = $end - $start;
		$addruletime = sprintf("%.4f seconds", $addruletime);
		$log->info("Total amount of time to add a rule:  $addruletime");
		print "duration of adding chains: $addruletime\n";
		$log->info("Total number of rules inserted:  $counter");
		print "Total number of rules inserted:  $counter\n";
	} else {
		$log->info("Chain $vin and $vout do not exist");
		print "Chain $vin and $vout do not exist\n";
	}
}

=pod

=item *

_getVMName($hashref);

This function extracts the VM name from the hash reference and will use it in the addChain() function later.

I<Inputs>:
B<$hashref>is the hash reference sent from the HoneyClient::Agent->HoneyClient::Manager->HoneyClient::Manager::FW

I<Output>: Returns the VM name.

=cut

sub _getVMName {

	# pass in the hashref here
	my $hashref = shift;

	# loop through the top key which will represent our VM name
	while (my ($key, $value) = each(%$hashref)) {

		# lets return our VM name now
        if (!defined($key)) {
            die ("Error: Unable to _getVMName");
        }
		return $key;
	}
}

=pod

=item *

init_fw()

The following init_fw() and destroy_fw() functions are the only direct
calls required to startup and shutdown the SOAP server.

I<Input>: $class, $localAddr, $localPort

I<Output>: n/a

=cut

sub init_fw {

	# Extract arguments.
	my ($class, $localAddr, $localPort) = @_;

	# Sanity check.  Make sure the daemon isn't already running.
	if (defined($DAEMON_PID)) {
		Carp::croak
		  "Error: $PACKAGE daemon is already running (PID = $DAEMON_PID)!\n";
	}
	if (!defined($localAddr)) {
		$localAddr = getVar(name => "address");
	}
	if (!defined($localPort)) {
		$localPort = getVar(name => "port");
	}
	$URL_BASE = "http://" . $localAddr . ":" . $localPort;
	$URL = $URL_BASE . "/" . join('/', split(/::/, $PACKAGE));
	if ($DAEMON_PID = fork()) {
		return $URL;
	} else {

		# Do not attempt to rejoin parent process tree,
		# if any type of termination signal is received.
		local $SIG{HUP}  = sub { exit; };
		local $SIG{INT}  = sub { exit; };
		local $SIG{QUIT} = sub { exit; };
		local $SIG{ABRT} = sub { exit; };
		local $SIG{PIPE} = sub { exit; };
		local $SIG{TERM} = sub { exit; };
		my $daemon = getServerHandle(address => $localAddr, port => $localPort);

		for (;;) {
			$daemon->handle();
		}
	}
}

=pod

=item *

destroy_fw()

Terminates the SOAP server within the child process.

=cut

sub destroy_fw {
	my $ret = undef;

	# Make sure the PID is defined and not
	# the parent process...
	if (defined($DAEMON_PID) && $DAEMON_PID) {
		$ret = kill("QUIT", $DAEMON_PID);
	}
	if ($ret) {
		$DAEMON_PID = undef;
	}
	return $ret;
}

=pod

=item *

_load_interfaces()

Loads the interfaces listed in the /etc/interfaces.conf file (function not active yet)

I<Input>: filename

I<Output>: n/a

=cut

sub _load_interfaces {
	my ($int, $name);
	my $interfaces = getVar(name => "interfacesConfig");
	local (*FILE);
	open(FILE, "$interfaces") or die ("Error: Unable to open file $interfaces");
	while (<FILE>) {
		chomp($_);
		if ($_ eq "") { next; }
		($name, $int) = split(/\s*=\s*/, $_);
		$interface{$name} = $int;
	}
}

=pod

=item *

_flushChains()

Gets the current list of chains within the IPTables ruleset and flushes all corresponding rules, then deletes the actual
chain.

I<Input>: No input

I<Output>: Return true if success for the flushing and deleting, returns false if unsuccessful

=cut

sub _flushChains {
	my ($class)  = @_;
	my $table    = IPTables::IPv4::init('filter');
	my $natTable = IPTables::IPv4::init('nat');
	my ($natChain, $chain,) = q{};

# grab logging configuration options specified in configuration file within our
# HoneyClient::Manager::FW package.  Additionally, we state basic informational messages
# throughout the function.
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Flushing iptables chains");

	# make sure $table object is defined
	if ((!defined($table)) || (!defined($natTable))) {
		die("Error, could not connect to IPTABLES interface: $!");
	} else {

#  grab the list of chains that are currently defined within our iptables ruleset and push them
# into @chains.  This method returns an array containing names of all existing chains in the table.
		my @chains    = $table->list_chains();
		my @natChains = $natTable->list_chains();

# Here we are deleting all the rules in all the chains found that currently exist.  Even though we are
# deleting INPUT, FORWARD, and OUTPUT in addtion to other user-defined chains, INPUT, FORWARD, and OUTPUT
# can never be deleted due to the fact that they are default chains.
		foreach $chain (@chains) {
			$log->info("Flushing $chain entry in filter table");
			unless ($table->flush_entries($chain)) {
                die ("Error: Could not flush entries on chain $chain in filter table!");
            }
            if (!$table->builtin($chain)) {
			    $log->info("Deleting $chain in filter table");
			    unless ($table->delete_chain($chain)) {
                    die ("Error: Could not delete chain $chain in filter table!");
                }
            }
		}

# Flushing the NAT table by looping through all the chains and flushing the rules
		foreach $natChain (@natChains) {
			$log->info("Flushing $natChain entry in nat table");
			unless ($natTable->flush_entries($natChain)) {
                die ("Error: Could not flush entries on chain $natChain in nat table!");
            }
            if (!$natTable->builtin($natChain)) {
			    $log->info("Deleting $natChain in nat table");
			    unless ($natTable->delete_chain($natChain)) {
                    die ("Error: Could not delete chain $natChain in nat table!");
                }
            }
		}

# This attempts to commit all changes made to the IP chains in the table that $table points
# to, and closes the connection to the kernel-level netfilter subsystem.
		unless ($table->commit()) {
            die ("Error: Unable to commit filter table!");
        }
		unless ($natTable->commit()) {
            die ("Error: Unable to commit nat table!");
        }
		sleep (1);
	}
}

=pod

=item *

_setAcceptPolicy()

Grabs the current list of chains within the IPTables ruleset and sets the policy to ACCEPT.

I<Input>: No input

I<Output>: Return true if the commit was successful, returns false if unsuccessful.  $table->commit() attempts to commit
all changes made to the IP chains in the table that $table points to, and closes the connection to the kernel-level netfilter subsystem.
If you wish to apply your changes back to the kernel, you must call this.

=cut

sub _setAcceptPolicy {
	my (@class)  = @_;
	my $table    = IPTables::IPv4::init('filter');
	my $natTable = IPTables::IPv4::init('nat');
	my ($success, $chain, $natChain) = q{};
	my (@chains, @natChains) = ();

# grab logging configuration options specified in configuration file within our
# HoneyClient::Manager::FW package.  Additionally, we state basic informational messages
# throughout the function.
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Setting all chains to ACCEPT policy");
	if ((!defined($table)) || (!defined($natTable))) {

		# not defined, log to log file
		$log->error_die("Error, could not connect to IPTABLES interface: $!");
	} else {

	   # get list of chains, loop through that list and set the policy to ACCEPT
		@chains    = $table->list_chains();
		@natChains = $natTable->list_chains();
		foreach $chain (@chains) {
			$log->info("Setting $chain to ACCEPT policy now");
            # TODO: Verify that this set_policy call works for user-defined
            # chains.
			# boolean value is returned from set_policy ($success)
			$table->set_policy($chain, "ACCEPT");
		}
		foreach $natChain (@natChains) {
			$log->info("Setting $natChain to ACCEPT policy now");
			$natTable->set_policy($natChain, "ACCEPT") or
                die "Unable to set_policy on chain $chain in natTable";
		}
		$table->commit() or die "Unable to commit table";
		$natTable->commit() or die "Unable to commit natTable";
	}
}

=pod

=item *

_setDefaultDeny()

Gets the current list of chains and sets the firewall policy to DROP.

I<Input>: No input

I<Output>: Return true if successful commit, returns false if unsuccessful commit

=cut

sub _setDefaultDeny {
	my $table = IPTables::IPv4::init('filter');
	my ($success, $chain) = qw{};

# grab logging configuration options specified in configuration file within our
# HoneyClient::Manager::FW package.  Additionally, we state basic informational messages
# throughout the function.
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Setting all chains to DROP policy");
	if (!defined($table)) {
		$log->error_die("Error, could not connect to IPTABLES interface: $!");
	} else {

		# get list of chains, loop through that list and set the policy to DROP
		my @chains = $table->list_chains();
		foreach $chain (@chains) {
            if ($table->builtin($chain)) {
			    $log->info("$chain is set to DROP policy");
			    unless ($table->set_policy($chain, "DROP")) {
                    die "Unable to set_policy on chain $chain in filter table";
                }
            }
            unless ($table->flush_entries($chain)) {
                die "Unable to flush chain $chain in filter table";
            }
		}
		unless($table->commit()) {
            die "Error: Unable to commit table";
        }
	}
}

=pod

=item *

_setDefaultRules()

This function parses the /etc/resolv.conf file and grabs the DNS settings, then creates iptables rules on the INPUT/FORWARD
and OUTPUT chains from thoses DNS settings.  Additionally, we create rules to allow the firewall to talk to itself via the localhost.

Additionally, at the end of the opendefault function are two rules:

"iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT"
"iptables -A FORWARD -i eth1 -o eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT"

These rules track state and  allow traffic to be forwarded in both directions.  It also only allows initiated
10.0.0.0/24 outbound traffic to be sent.  This is necessary since we only want our honeyclients to recieve traffic
that they initiated and no other.  For starters, our honeyclients will just be examining HTTP traffic but might be examining
other protocols in the future.  Either way, all established and initiated connections that match this rule and be allowed out.


I<Input>: No input

I<Output>: Return true if successful commit, returns false if unsuccessful commit

=cut

sub _setDefaultRules {

	# initialize variables
	my $table     = IPTables::IPv4::init('filter');
	my @chainlist = qw(INPUT OUTPUT);
	my ($keyword, $arg) = q{};
	my @dnslist   = _getdns();
	my $array_ref = \@dnslist;
	my $interface = "eth0";
	my $dnsport   = getVar(name => "dnsport");
	my $sshport   = getVar(name => "sshport");
    my $vmnet_nat_router_address = getVar(name => "vmnet_nat_router_address");

# grab logging configuration options specified in configuration file within our
# HoneyClient::Manager::FW package.  Additionally, we state basic informational messages
# throughout the function.
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Setting default rule in _setDefaultRules()");

# lets get the IP address of "eth0" on our honeywall
# the "eth2" interface is used mainly for DNS lookups when dynamically adding and deleting the rules
	my $IP = _getip($interface);
	print "ip address = $IP\n";

	# create logging entry into logfile (informational message)
	$log->info("Setting localhost entries");

# setting the localhost policy here, this is necessary so that the firewall can talk to itself
	foreach my $clist (@chainlist) {

		# match INPUT chain
		if ($clist =~ /INPUT/) {
            # Allow localhost traffic.
			$table->append_entry(
				$clist,
				{

		   #setting localhost policy, appending to iptables ruleset within INPUT
					"in-interface" => "lo",
					"source"       => "127.0.0.1",
					"jump"         => "ACCEPT"
				}
			) or die ("Error: Unable to append to chain $clist");

            # Allow traffic to the firewall IP address.
			$table->append_entry(
								 $clist,
								 {
									"source" => $IP,
									"jump"   => "ACCEPT"
								 }
			) or die ("Error: Unable to append to chain $clist");

            # Allow SSH traffic to the firewall IP address.
			$table->insert_entry(
								 $clist,
								 {
									protocol           => "tcp",
									"destination-port" => $sshport,
									jump               => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert into chain $clist");

            # Allow Agents to synchronize their time with the firewall.
			$table->insert_entry(
								 $clist,
								 {
									protocol           => "udp",
									#why is this not destination?
									'source'           => $vmnet_nat_router_address,
									"destination-port" => 123,
									jump               => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert into chain $clist");

            # Allow the Manager to contact the firewall's SOAP server.
			$table->insert_entry(
								 $clist,
								 {
									protocol           => "tcp",
									"destination-port" => "8080:8090",
									jump               => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert into chain $clist");
		}

		# match OUTPUT chain and set localhost policy
		if ($clist =~ /OUTPUT/) {

            # Allow localhost traffic.
			$table->append_entry(
								 $clist,
								 {
									"out-interface" => "lo",
									"destination"   => "127.0.0.1",
									"jump"          => "ACCEPT"
								 }
			) or die ("Error: Unable to append to chain $clist");

            # Allow loopback traffic to the firewall IP address.
			$table->append_entry(
								 $clist,
								 {
									"destination" => $IP,
									"jump"        => "ACCEPT"
								 }
			) or die ("Error: Unable to append to chain $clist");

            # Allow outbound SSH traffic from the firewall.
			$table->insert_entry(
								 $clist,
								 {
									protocol      => "tcp",
									"source-port" => $sshport,
									jump          => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert into chain $clist");

            # Allow outbound NTP traffic from the firewall.
			$table->insert_entry(
								 $clist,
								 {
									protocol      => "udp",
									#why is this not source?
									'destination' => $vmnet_nat_router_address,
									"source-port" => 123,
									jump          => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert into chain $clist");

            # Allow outbound SOAP communication from the firewall.
			$table->insert_entry(
								 $clist,
								 {
									protocol      => "tcp",
									"source-port" => "8080:8090",
									jump          => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert into chain $clist");
		}
	}
	$log->info("Setting localhost entries");

	#  Allow our DNS connections for resolution of domains
	# now, lets append the @chainlist array and add the FORWARD chain name
	# Could be written cleaner but it works for now!
	push(@chainlist, "FORWARD");

	# enter loop of dns nameservers list
	foreach my $dnsname (@$array_ref) {

		# add DNS entries into all chains
		foreach my $chainname (@chainlist) {

# we have to specify INPUT, OUPUT, and FORWARD here because other
# chains do exist within our iptables ruleset and we don't want to add the DNS nameserver
# entries into them.
			if ($chainname eq "INPUT") {
				$table->append_entry(
									 "INPUT",
									 {
										protocol      => "udp",
										'source'      => $dnsname,
										"source-port" => $dnsport,
										jump          => "ACCEPT"
									 }
			    ) or die ("Error: Unable to append to chain $chainname");
			}

			# entry into OUTPUT chain
			elsif ($chainname eq "OUTPUT") {
				$table->append_entry(
									 "OUTPUT",
									 {
										protocol           => "udp",
										'destination'      => $dnsname,
										"destination-port" => $dnsport,
										jump               => "ACCEPT"
									 }
			    ) or die ("Error: Unable to append to chain $chainname");
			}

			# entry into FORWARD chain (both directions)
			else {
				$table->append_entry(
									 "FORWARD",
									 {
										protocol      => "udp",
										'source'      => $dnsname,
										"source-port" => $dnsport,
										jump          => "ACCEPT"
									 }
			    ) or die ("Error: Unable to append to chain $chainname");
				$table->append_entry(
									 "FORWARD",
									 {
										protocol           => "udp",
										'destination'      => $dnsname,
										"destination-port" => $dnsport,
										jump               => "ACCEPT"
									 }
			    ) or die ("Error: Unable to append to chain $chainname");
			}
		}
	}
	$table->append_entry(
						 "FORWARD",
						 {
						    "source"      => "10.0.0.1/32",
							"destination" => "10.0.0.0/24",
							"protocol"    => "icmp",
							"icmp-type"   => "echo-request",
							"jump"        => "ACCEPT"
						 }
	) or die ("Error: Unable to append to chain FORWARD");
	$table->append_entry(
						 "FORWARD",
						 {
							"destination" => "10.0.0.1/32",
							"source"      => "10.0.0.0/24",
							"protocol"    => "icmp",
							"icmp-type"   => "echo-reply",
							"jump"        => "ACCEPT"
						 }
	) or die ("Error: Unable to append to chain FORWARD");

# Adds drop rules at end of default ruleset so all that does not match will be logged
#pop(@chainlist);    # removes the FORWARD element in the list here
	foreach my $chainname (@chainlist) {
		# LOG/DROP all that does not match the rules within our INPUT and OUTPUT chains
		if("$chainname" eq "INPUT"){
			$table->append_entry("$chainname", { jump => "Drop_Log_In" }) or
	            die ("Error: Unable to append to chain $chainname");
		}
		if("$chainname" eq "OUTPUT"){
			$table->append_entry("$chainname", { jump => "Drop_Log_Out" }) or
	            die ("Error: Unable to append to chain $chainname");
		}
		if("$chainname" eq "FORWARD"){
			$table->append_entry("$chainname", { jump => "Drop_Log_Fwd" }) or
	            die ("Error: Unable to append to chain $chainname");
		}
	}

# Set Drop_Log within the FORWARD chain for logging.
#	$table->append_entry("FORWARD", { "jump" => "Drop_Log" });
# iptables -t nat -I PREROUTING 1 -m state --state NEW  -j LOG --log-level debug --log-tcp-options --log-ip-option#s
# iptables -t nat -I PREROUTING 1 -j LOG --log-tcp-options --log-ip-options --log-level debug
	$table->commit() or die ("Error: Unable to commit to filter table");
}

=pod

=item *

_createNat()

Create a NAT rule that allows for all HoneyClient VM's to have access through the Honeywall.  We are using a Masquerading rule,
masquerading is a simplified form of SNAT (source NAT) in which packets receive the IP address of the output interface as their source
address.

I<Input>: No input

I<Output>: Output is a bolean value for succes or failure during the rule insertion.

=cut

# creating our NAT rules for the honeyclient network
sub _createNat {
	my $table   = IPTables::IPv4::init('nat');
	my $network = getVar(name => "honeyclientnet");
	$table->append_entry(
						   "POSTROUTING",
						   {
							  "out-interface" => "eth0",
							  "source"        => "10.0.0.0/24",
							  "jump"          => "MASQUERADE"
						   }
	) or die ("Error: Unable to append to chain POSTROUTING");
	$table->commit() or die ("Error: Unable to commit to nat table");
}

=pod

=item *

_createPreroutingLogging()

Create a logging rule for the NAT table (PREROUTING chain) in which we log all traffic that does match the specified rule.

I<Input>: No input

I<Output>: Output is a boolean value for succes or failure during the rule insertion.

=cut

sub _createPreroutingLogging {
	my $hashref = shift;
	my $vmID    = shift;
	my $table   = IPTables::IPv4::init('nat');
	my %rules   = _parseHash($hashref);

   # start looping through our HoH to insert our rules into the iptables ruleset
	for my $destip (keys %rules) {
		my $success =
		  $table->insert_entry(
						  "PREROUTING",
						  {
							"source"      => $rules{$destip}{'source'},
							"destination" => "!$rules{$destip}{'destination'}",
							"jump"        => "LOG",
							"log-level"   => "debug",
							"log-prefix"  => "VMID=$vmID  "
						  },
						  0
		  );
        if (!$success) {
            die ("Error: Unable to insert entry into chain PREROUTING");
        }
		print "success = $success\n";
	}
	$table->commit() or die ("Error: Unable to commit changes to nat table");
	return $success;
}

# Opposite of _createPreroutingLogging ;)
sub _deletePreroutingLogging {
	my $hashref = shift;
	my $vmID    = shift;
	my $table   = IPTables::IPv4::init('nat');
	my %rules   = _parseHash($hashref);
	my $success = 0;

   # start looping through our HoH to insert our rules into the iptables ruleset
	for my $destip (keys %rules) {
		$success =
		  $table->delete_entry(
						  "PREROUTING",
						  {
							"source"      => $rules{$destip}{'source'},
							"destination" => "!$rules{$destip}{'destination'}",
							"jump"        => "LOG",
							"log-level"   => "debug",
							"log-prefix"  => "VMID=$vmID  "
						  }
		  );
		  if(!$success){
            die ("Error: Unable to delete entry from chain PREROUTING");
		  	last;
		  }
		print "success = $success\n";
	}
	$table->commit() or die ("Error: Unable to commit changes to nat table");
	return $success;
}

=pod

=item *

_getdns()

This function grabs the DNS settings from the /etc/resolv.conf file.  It assumes that the default location
for these settings will be in that file.  However, it does check and make sure that it is a linux
box first.

I<Input>: No input

I<Output>: Returns a complete list of nameservers if true, if not true, returns value of linux variable which should be 0

=cut

sub _getdns {

	# sets the path of the $dnspath var
	my $dnspath = getVar(name => "dnspath");
	my @dnslist = ();

# grab logging configuration options specified in configuration file within our
# HoneyClient::Manager::FW package.  Additionally, we state basic informational messages
# throughout the function.
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Opening _getdns() function");

    # open up for reading
	open (RESOLV, $dnspath) or
        die "Unable to read DNS settings from file $dnspath";
	while (<RESOLV>) {
		chomp;

		# pass if does not contain "nameserver"
		next if (!/nameserver/);

  # substitute nameserver with empty space so that we may isolate the IP address
		s/nameserver //ig;
		$log->info("Getting DNS entry from $dnspath:  $_");

		# push the ip addresses into our array
		push @dnslist, $_;
	}
	close RESOLV or
        die "Unable to close file $dnspath";

    # returns the dns nameserver array full of primary, secondary, and possibly tertiary DNS nameservers
	return @dnslist;
}

=pod

=item *

_createDropLog()

Create a user-defined chain called Drop_Log which logs and drops all rules that do not match rules within the INPUT and
OUTPUT chains.

I<Input>: No input

I<Output>: Return true if successful , returns false if unsuccessful append.

=cut

sub _createDropLog {
	my $table = IPTables::IPv4::init('filter');

	#	my $table = IPTables::IPv4::init('nat');
	# variable initialization
	my $chain = shift;
	my $log_prefix = shift;
	my $drop  = "DROP";

	# test for defined table object
	if (!defined($table)) {
        die ("Error: filter table was undefined!");
    }

	unless ($table->create_chain($chain)) {
        die ("Error: Unable to create chain $chain in filter table");
    }

	unless ($table->append_entry(
                                 $chain,
                                 {
                                  jump         => "LOG",
                                  "log-prefix" => $log_prefix,
                                  "log-level"  => "debug",
                                  "log-tcp-options"
                                 })) {
        die ("Error: Unable to append to chain $chain in filter table");
    }

	# appending $chain with a target of DROP
	unless ($table->append_entry($chain, { jump => $drop })) {
        die ("Error: Unable to append to chain $chain in filter table");
    }

	unless ($table->commit()) {
        die ("Error: Unable to commit filter table");
    }
}

=pod

=item *

_doFullBackup()

Does a complete backup to hard disk of the current active iptables ruleset.

I<Input>: Requires the $outputdir where the file will be written to.

I<Output>: Returns void; dies if failure.

=cut

sub _doFullBackup {
	my ($outputdir) = @_;
	my ($currenttime, $fh) = q{};

	# logging objects
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Starting full backup");

	# get the current time
	$currenttime = _getLogtime();

	#Lets create our backup directory now if it doesn't already exist
    if (! -d $outputdir) {
       	mkdir ($outputdir) or die "Unable to make directory: $outputdir";
    }

	# new filehandle
	$fh = new FileHandle(">$outputdir/ruleset$currenttime");
    if (!defined($fh)) {
        die "Unable to open file: " . $outputdir . "/ruleset" . $currenttime;
    }

	# information message to logfile
	$log->info("Writing to $outputdir/ruleset$currenttime");

 # write to our filehandle which contains a dump of the current iptables ruleset
	print($fh "", Data::Dumper->Dump([ \%IPTables::IPv4 ], ['rules'])) or
        die "Unable to write to file: " . $outputdir . "/ruleset" . $currenttime;

	# close out the filehandle
	close($fh) or
        die "Unable to close file: " . $outputdir . "/ruleset" . $currenttime;
}

=pod

=item *

_setstaticrate()

This function creates a static rate limiting rule for our default honeyclient default ruleset.  For testing purposes, I
allow an initial burst of 10 tcp/udp/icmp packets, then gives you 5 packets per minute thereafter.

I<Input>: Requires the $outputdir where the file will be written to.

I<Output>: Return true if commit success or false if commit failure

=cut

sub _setStaticRate {
	my $table     = IPTables::IPv4::init('filter');
	my $success   = q{};
	my @chains    = qw(FORWARD);                      # more to be added later
	my @protocols = qw( icmp );                       # more to be added later
	my $ICMP      = "ICMP";
	my $forward   = "FORWARD";

	# hardcoded in for now, will be moved to /etc/honeyclient.conf soon
	my $GSX            = "10.0.0.1/32";
	my $honeyclientnet = "10.0.0.0/24";
	my $log            = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering _setstaticrate() function");

# example iptables rule
#iptables -A OUTPUT -p icmp -m limit --limit-burst 10 --limit 5/minute -j ACCEPT
#iptables -A OUTPUT -p icmp -j DROP
# perform rate limiting for tcp/udp and icmp protocols, max of 10 bursts, the average 5 packets per minute
# loop through protocol array list and push rules into @raterules
	foreach my $protocol (@protocols) {
		$log->info("Setting static rate limiting rule for $protocol");
		push(
			 @raterules,
			 {
				'source'      => "10.0.0.0/24",
				'limit'       => '20/min',
				'protocol'    => $protocol,
				'matches'     => ['limit'],
				'limit-burst' => 20,
				jump          => "ACCEPT"
			 }
		);
	}

# loop through @chains (outerloop), then loop through the rules (inner loop), append the rules
# for each of the @chains
	foreach $chain (@chains) {
		foreach my $rr (@raterules) {
			$success = $table->append_entry($chain, $rr);
            if (!$success) {
                die ("Error: Unable to append entries to chain $chain");
            }
		}
	}
	$table->commit() or die ("Error: Unable to commit changes to filter table");
}

=pod

=item *

_remoteConnection()

This function opens a few remote connection holes within our honeyclient firewall, more specifically ssh and 8082/tcp (used for connection to/from GSX server manager module)

I<Input>: No input

I<Output>: Return true if successful commit, returns false if unsuccessful commit

=cut

sub _remoteConnection {
	my $table   = IPTables::IPv4::init('filter');
	my $success = q{};
	my @chains  = qw(INPUT OUTPUT);
	my $sshport = getVar(name => "sshport");
	my $log     = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering _remoteConnection() function");

	#	system("iptables -I INPUT -p tcp --dport 22 -j ACCEPT");
	#	system("iptables -I OUTPUT -p tcp --sport 22 -j ACCEPT");
	#	system("iptables -A FORWARD -j LOG --log-tcp-options --log-ip-options");
	# lets allow ssh in and out for testing purposes
	# inserting at the TOP/HEAD of the chain
	$log->info(
"Inserting rule to head of INPUT chain that allows all port $sshport traffic");
	foreach my $chainname (@chains) {
		if ($chainname =~ /INPUT/) {
			$table->insert_entry(
								 $chainname,
								 {
									protocol           => "tcp",
									"destination-port" => $sshport,
									jump               => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert entry into chain $chainname");

			# 8080:8090 is for the FW SOAP server and all other servers
			$table->insert_entry(
								 $chainname,
								 {
									protocol           => "tcp",
									"destination-port" => "8080:8090",
									jump               => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert entry into chain $chainname");
		}

# lets allow remote connection from GSX to honeywall in and out for command/control
# we open up ports 8080 to 8090 so but this will be reconfigured to only allow for certain ports
# to be open later on.
		if ($chainname =~ /OUTPUT/) {
			$table->insert_entry(
								 $chainname,
								 {
									protocol      => "tcp",
									"source-port" => $sshport,
									jump          => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert entry into chain $chainname");
			$table->insert_entry(
								 $chainname,
								 {
									protocol      => "tcp",
									"source-port" => "8080:8090",
									jump          => "ACCEPT"
								 },
								 0
			) or die ("Error: Unable to insert entry into chain $chainname");
		}
	}

# Lets append a DROP rule to the FORWARD chain.  This rule will log and drop all
# unmatched traffic
#	$table->append_entry( "FORWARD", { "jump" => "DROP_LOG" } );
#							 "in-interface"  => "eth1",
#							 "out-interface" => "eth0",
#							 'matches'       => ['state'],
#							 "state"         => $state,
	$table->append_entry("FORWARD", { "jump" => "Drop_Log" }) or
        die ("Error: Unable to append entries into chain FORWARD");

#system("iptables -A FORWARD -j LOG --log-tcp-options --log-ip-options --log-prefix '[IPTABLES LOG] : '"
#$table->append_entry( "FORWARD", { "matches" => ['physdev'], "jump" => "LOG", "log-prefix" => "FORWARD: ", "log-level" => "debug" } );
	$table->commit() or die ("Error: Unable to commit changes to filter table");
}

=pod

=item *

_set_ip_forwarding()

Set the /proc/sys/net/ipv4/ip_forward file to a value supplied by the user

I<Input>: $value which will be either 0 or 1

I<Output>: nothing

=cut

sub _set_ip_forwarding {
	my ($value) = @_;
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering _set_ip_forwarding() function");

# The set_ip_forwarding() function does what its name implies; it tells the
# Linux kernel either to forward IP packets, or not to forward packets. The
# function accepts a single parameter, either 0 or 1, which determines whether
# the kernel will forward. The script initially turns all forwarding off while it loads
# the firewall policy. Then, right before the script exits, the script turns forwarding back on.
	my $fh = new IO::File "> /proc/sys/net/ipv4/ip_forward";
	if (defined $fh) {
		$log->info("Setting /proc/sys/net/ipv4/ip_forward to $value");
		print $fh "$value" or
            die ("Unable to write to /proc/sys/net/ipv4/ip_forward");
		$fh->close() or
            die ("Unable to close /proc/sys/net/ipv4/ip_forward");
	} else {
        die ("Unable to write to /proc/sys/net/ipv4/ip_forward");
    }
}

=pod

=item *

_checkRoot()

Checks to make sure FW.pm is running as root user (uid 0).

I<Input>: No input

I<Output>: Return true if success or false if failure

=cut

sub _checkRoot {
	use English '-no_match_vars';
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering _checkRoot() function");
	### lets check and see if we have root (uid 0) access ###
	# simple check to see if we are root or not
	if ($UID != 0) {
		$log->info("User ID:  $UID");
		return (0);
	} else {
		$log->info("User ID:  $UID");
		$log->info("Looks like we are root and may proceed");
		return (1);
	}
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  _rule_exists() function checks for the existance of rules within our IPTables ruleset.  Within this function,
we are checking the rules within the user-defined chains that we have created.  If there is a match within the "input" VM, we consider that a match since when the rule is initially appended, it is appended to both the VM#-in and VM#-out chains.  Here, I am only testing against the VM#-in chain since if the rule is in one, it has to be in both.

I<Inputs>:
B<$table>is the object type of IPTables::IPv4::Table.
B<$vin> is the VM input chain name.
B<$vout> is the VM output chain name.
B<%rule> is a hash containing source, destination, and protocol values.

I<Output>: Return true if success or false if failure

=cut

sub _rule_exists {
	my ($table, $vin, $vout, %rule) = @_;
	my ($code, @outrules, @inrules, $i);
	my $log = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering _rule_exists() function");

	# getting list of chain rules, hash is passed in from FWPunch()
	@inrules = $table->list_rules($rule{'chain'});

# Eventually, we will run tests against the outrules as well but for now we are just populating the @outrules array
	@outrules = $table->list_rules($rule{'chain'});

# loop through all the rules to find a match, using source, destination, target and protocol as matching fields
	for ($i = 0 ; $i <= $#inrules ; $i++) {
		if (   $inrules[$i]->{'source'} eq $rule{'source'}
			&& $inrules[$i]->{'destination'} eq $rule{'destination'}
			&& $inrules[$i]->{'jump'}        eq $rule{'jump'}
			&& $inrules[$i]->{'protocol'}    eq $rule{'protocol'})
		{

			# We have a match
			$code = 1;
			last;
		} else {

			# No match
			$code = 0;
		}
	}
	$log->info("Returning return code $code");
	return $code;
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]: _translate($url);

The translate function converts a host name to dotted quad format.

I<Inputs>:
B<$url>is the domain name that will be converted to dotted quad format.

I<Output>: Return the domain name as an IP address.

=cut

sub _translate {
	(my $url) = @_;
	chomp($url);
	my $packed_address = gethostbyname($url);
	my $dotted_quad    = inet_ntoa($packed_address);
	return ($dotted_quad);
}
##################################################################
# Function name:  getStatus()
# Description: Gathers basic IPTable statistics such as packet and byte count
#			   for each rule in the OUTPUT chain.
# INPUT:  VM number
# OUTPUT: table_commit() status, 0 for failure, 1 for success
##################################################################

=pod

=item *

getStatus();

Gets the current iptables ruleset for all the chains (both default and user-defined) and writes them to hard disk.
Loop through each chain which gets you the list of chain names.  The function list_rules()  returns an array of hash references,
which contain descriptions of each rule in the chain chainname.   Below is the core of the function FWStatus().

        foreach $chainname(@chainlist){
                print "\n$chainname\n";
                my @chainrules = $table->list_rules($chainname);
                for my $href (@chainrules){
                        for $line (keys %$href){
                                print FWSTATUS "$line=$href->{$line} ";
                        }
                print "\n";
                }
        }

I<Inputs>:
B<$class>is the name of the package.

I<Output>: nothing

=begin testing

eval{
	diag("Testing fwStatus()...");
    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep 1;
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    $som = $stub->getStatus();
    # testing to make sure the chains are empty
    ok(!$som->result, "getStatus() successfully passed.")   or diag("The getStatus() call failed.");
#    $som = $stub->_setAcceptPolicy();
#    $som = $stub->_flushChains();
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep 1;

# Report any failure found.
if ($@) {
    fail($@);
	}

=end testing

=cut

sub getStatus {
	my ($class) = @_;
	my $table   = IPTables::IPv4::init('filter');
	my @default = qw (OUTPUT FORWARD INPUT);
	my (
		$file_no, $dname,  $inhref,  $forhref,
		$outhref, $inrole, $forrole, $outrole
	  )
	  = q{};
	my @rules       = ();
	my @chainlist   = $table->list_chains();
	my $fwstatuslog = "fw-output/fwStatus.log";
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
	  localtime(time);    #get script start time
	my $iptables_save = "/sbin/iptables-save";
	my $log           = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering FWStatus() function");

	# loop through each of the chains and get the rules for each of those chains
	foreach $dname (@default) {
		@rules = $table->list_rules($dname);

		# get the rule count for that chain
		$file_no = scalar(@rules);

# below, we check for the existance of a rule within our chains, if no rules exists, they are considered empty.
#empty
		if ($file_no == 0) {
			my $status = 0;
			$log->info("IPTables ruleset is empty.");
		}

		# not empty
		else {
			$status = 1;
			$log->info(
				  "IPTables ruleset is not empty, it contains $file_no rules.");
			last;
		}
	}

	# if rules do exist with our default chains
	if ($status) {

		#POSIX module, if-exited
		$log->info("Saving iptables rules to fw-output/iptables-save.log");
        # TODO: Need to check to make sure this call returns properly.
		system("$iptables_save > fw-output/iptables-save.log");

#    WIFEXITED(system("$iptables_save > fw-output/iptables-save.log")) or die "Couldn't run: $iptables_save > fw-output/iptables-save.log ($OS_ERROR)";;
		my $logtime = sprintf("%4d-%02d-%02d %02d:%02d:%02d",
							  $year + 1900,
							  $mon + 1, $mday, $hour, $min, $sec);
		open(FWSTATUS, ">$fwstatuslog")
		  or die "Cannot write to fwstatuslog: $!\n";
		print FWSTATUS "FWStatus call time:  $logtime\n";
		print FWSTATUS "*************\n";
		foreach $chainname (@chainlist) {
			print FWSTATUS "\n$chainname\n";
			my @chainrules = $table->list_rules($chainname);
			for my $href (@chainrules) {
				for $line (keys %$href) {
					print FWSTATUS "$line=$href->{$line} ";
				}
				print "\n";
			}
		}
		print FWSTATUS "\n\n*******\n\n";
		close (FWSTATUS) or die ("Error: Unable to close file $fwstatuslog");
		return $status;
	} else {
		return $status;
	}
}

=pod

=item *

_iplookup();

_iplookup takes a domain name ($dest) and performs a DNS query to find an IP address or IP addresses corresponding to
that domain name.  Currently, _resolveHost() is being used.

I<Inputs>:
B<$dest> is a domain name that will be queried to retrieve corresponding IP addresses.

I<Output>: An array of resolved IP addresses. If the array only contains one value, then just the
           one value is in the array.

=cut

sub _iplookup {
	use Net::DNS;
	my ($dest)     = @_;
	my $errorcode  = q{};
	my $res        = Net::DNS::Resolver->new();
	# TODO: Make these timeouts non-static.
	$res->tcp_timeout(10);
	$res->udp_timeout(10);
	my @iplist     = ();
	my %resolvedip = ();
	my $query      = $res->search("$dest");
	my $log        = get_logger("HoneyClient::Manager::FW");
	$log->info("Entering _iplookup() function");
	$log->info("Received $dest as an argument");

	if ($query) {
		foreach my $rr ($query->answer) {
			next unless $rr->type eq "A";
			$log->info("$dest can be resolved to $rr->address");
			push(@iplist, $rr->address);
			$resolvedip{$rr} = $rr->address;
			$errorcode = 1;
		}
	} else {

		#		warn "query failed: ", $res->errorstring, "\n";
		if ($res->errorstring =~ /NXDOMAIN/) {
			$log->info("Warning, query failed");
			$errorcode = 0;
		}
        die ("Error: Unable to perform lookup on $dest");
	}
	return ($errorcode, @iplist);
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  insertMac();

insertMac function add mac address filtering (Anti-spoofing) rules after the VM user-chains
are created.  They must be remotely called after the vm_add_chain() function.

I<Inputs>:
B<$chain> is the name of the chain that you will be applying the Mac filtering to.
B<$ip> is the VM ip address that will be filtered.
B<$mac> is the mac address of the VM honeyclient.

I<Output>: returns nothing

=cut

sub _insertMac {
	my $table = IPTables::IPv4::init('filter');
	my $class = shift;
	my $chain = shift;
	my $ip    = shift;
	my $mac   = shift;
	my ($vmchainout, $code, $status) = q{};
	$vmchainout = "$chain-out";
	my $iptables = "/sbin/iptables";

# This tests to see if a value for $mac has been defined, if the image is not up and running (accepting
# icmp request/replies, then mac will not be able to be found.  If it is found, $mac will be set, hence
# defined.  Success will yield a 1 if rule insertion is successful, failure to insert the mac filter entry        # will return a 0
	if (defined($mac)) {

		# rules will be inserted at the HEAD of the user-defined chain
		my $success =
		  $table->insert_entry(
							   $vmchainout,
							   {
								  "source"     => $ip,
								  'matches'    => ['mac'],
								  'mac-source' => "!$mac",
								  "jump"       => "DROP"
							   },
							   0
		  );
        if (!$success) {
            die ("Error: Unable to insert entry into chain $vmchainout");
        }
		$table->commit() or die ("Error: Unable to commit changes to filter table");
		return $success;
	} else {
		$success = 0;
		return $success;
	}
}

=pod

=item *

_chain_exists();

_chain_exists tests to see if the chain already exists within the IPTables ruleset.

I<Inputs>:
B<$vmindex> is the Virtual Machine index number that will be used for comparing to the array of existing chains.

I<Output>: returns true if chain exists, fales if it does not exist.

=begin testing

eval{

    diag("Testing _chainExists()...");
    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep 1;
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    my $som  = $stub->fwInit($hashref);
    $som = $stub->addChain($hashref);
    is($som->result, 1, "_chainExists($hashref) successfully passed.")  or diag("The _chainExists() call failed.");
    $som = $stub->_setAcceptPolicy();
    $som = $stub->_flushChains();
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep 1;

# Report any failure found.
if ($@) {
    fail($@);
	}

=end testing

=cut

sub _chainExists {
	my ($vmname) = @_;                            # pass in VM name
	my $table = IPTables::IPv4::init('filter');
	my ($chain, $success, $vin, $vout) = q{};
	my @chains = ();

	# Concatenate VM names to create chain name
	$vin  = $vmname . "-IN";                      # create our input vm name
	$vout = $vmname . "-OUT";                     # create our output vm name
	if (!defined($table)) {
		die("Error, could not connect to IPTABLES interface: $!");
	} else {
		foreach $chain (@chains) {

# Here, we are testing to see if the user-defined input chain exists within the current set of chains
# TODO: This code may short-circuit and give you a false positive if only one of the chains exist.
			if ($vin eq $chain || $vout eq $chain) {
				$success = 1;                     # match
				last;
			} else {
				$success = 0;                     # no match occurred
			}
		}
		return ($success);
	}
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  isAlive();

Tests for existance of a file to verify if firewall has been started (not currently active)

I<Inputs>:
B<$pidfile> is the name of the created PID file.

I<Output>: creation of file with resolved IP addresses.

=cut

sub isAlive {
	my ($pidfile) = "/var/run/firewall.pid";
	my $alive = "";

# we will be checking for the existance of a newly created firewall with the word ENABLED in it.
	if (-f $pidfile) {
		$alive = 1;
	} else {
		$alive = 0;
	}
	return ($alive);
}

=pod

=item *

_getLogtime();

gets the time based on the OS time

I<Inputs>:  nothing

I<Output>: current time

=cut

sub _getLogtime {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
	  localtime(time);
	my ($currenttime) = "";
	$mon = $mon + 1;
	if ($mon < 10) {
		$mon = "0$mon";
	}
	if ($mday < 10) {
		$mday = "0$mday";
	}
	$year1 = $year + 1900;
	if ($hour < 10) {
		$hour = "0$hour";
	}
	if ($min < 10) {
		$min = "0$min";
	}
	if ($sec < 10) {
		$sec = "0$sec";
	}
	return $currenttime = "$mon$mday$year1-$hour$min$sec";
}

=pod

=item *

FWShutdown();

This function first flushes and deletes all the chains in the IPTables ruleset, then sets the ACCEPT policy
to all the default chains (INPUT, FORWARD, and OUTPUT).  Additionally, the function then loops through the process table
and kills all processes with "startFWListener.sh" in the process commandline (of which there should only be one).


I<Inputs>:  nothing
I<Output>: process will be killed

=begin testing

eval{

    $URL = HoneyClient::Manager::FW->init_fw();
    # Wait at least a second, in order to initialize the daemon.
    sleep 1;
    # Connect to daemon as a client.
    $stub = getClientHandle(namespace => "HoneyClient::Manager::FW");
    $som = $stub->starttestProcess();
    $som = $stub->fwShutdown();
    $som = $stub->findProcess();
   ok($som->result, "fwShutdown() successfully passed.")   or diag("The FWShutdown() call failed.");
};

# Kill the child daemon, if it still exists.
HoneyClient::Manager::FW->destroy_fw();
sleep 1;

# Report any failure found.
if ($@) {
    fail($@);
	}

=end testing

=cut

sub fwShutdown {
	use Proc::ProcessTable;
	$t = new Proc::ProcessTable;
	my $class = @_;

	# gets the process name from our configuration file
	my $processname = getVar(name => "fwprocess");

	# flushes all the rules within all the chains
	# deletes all the chains
	# sets the policy to INPUT, OUTPUT, and FORWARD to ACCEPT
	_flushChains();
	_setAcceptPolicy();

	# Lets delete all process running fwListener.pl
	foreach my $p (@{ $t->table }) {
		if ($p->cmndline =~ /$processname/) {

			#kill the process with the name $processname
			$p->kill(9) or
                die ("Error: Unable to kill process $processname");
		}
	}
}

=pod

=item *

starttestProcess() - system command to start the SOAP FW listener.  This function
is used strictly for pod2test purposes.

I<Inputs>:  nothing
I<Output>:  nothing

=cut

#test function for FWShutdown
sub starttestProcess {
    # TODO: Check to make sure this system call returns properly.
	system("/bin/sh /hc/startFWListener.sh");
}

=pod

=item *

findProcess() - used for test purposes only to find a started SOAP server listener.

I<Inputs>:  class name
I<Output>:  returns the boolean value, true or false

=cut

#test function for confirming process has been shutdown
sub findProcess {
	use Proc::ProcessTable;
	$t = new Proc::ProcessTable;
	my $class     = @_;
	my $returnval = q{};

	# we should not find the running process
	foreach my $p (@{ $t->table }) {

		# found the process which means the FWShutdown() function failed.
		if ($p->cmndline =~ /startFWListener.pl/) {
			$returnval = 0;
			last;
		}

		# did not find startFWListener.pl, FWShutdown was a success
		else {
			$returnval = 1;
		}
	}
	return $returnval;
}

=pod

=item *

_getpid();

_getpid() takes in 1 argument and returns the $pid of the SOAP firewall listener.

I<Inputs>:  Takes in the process name (name of the listener)
I<Output>:  returns the process ID number

=cut

sub _getpid {
	use Proc::ProcessTable;
	$t = new Proc::ProcessTable;
	my $processname = shift;
	my $pidarray    = ();
	my $pid         = q{};

# loop throught the process table here and return the process ID of the $processname
	foreach my $p (@{ $t->table }) {
		if ($p->cmndline =~ /$processname/) {
			return ($p->pid());
		}
	}
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  _sendMail() is a helper function that sends email to other systems informing them of various actions with the firewall.

_sendMail will send mail to the root account at localhost informing the root user of various firewall actions
I<Inputs>:
B<$from> is where the user is sending from
B<$to> is where the user is sending to
B<$subject> is the subject of the email
B<$body> is content of the email
I<Output>: returns nothing for now

=cut

sub _sendMail {
	my $from    = shift;
	my $to      = shift;
	my $subject = shift;
	my $body    = shift;
	open(SM, "|-", "/bin/mail", "-s", $subject, $to, "-f", $from) or
        die ("Error: Unable to send mail");
	print SM $body, "\n";
	close(SM) or die ("Error: Unable to send mail");
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  getcpuload is a  function that gives you the cpuload of the OS firewall.  This should help give a better understanding of how the
firewall OS is running.

I<Inputs>:
nothing
I<Output>: cpu load of the OS FW

=cut

sub getcpuload {
	my ($class) = @_;
    # TODO: Make sure system call returns properly.
	my $uptime  = `$UPTIME`;
	my $cpuLoad = 0;
	if ($uptime =~ /load average:\s+([\d\.]+)/) {
		$cpuLoad = $1;
	}
	return $cpuLoad;
}

=pod

=item *

_getip gets the current IP address and mask of the specified interface.

I<Inputs>:
Requires the interface so that it can find the IP address of that interface
I<Output>: IP address and Mask of that interface

=cut

sub _getip {
	my $device = shift;

	# gets OS name
	my $machine = `uname`;
	my ($Linux, $output, $ip, $mask) = q{};

	# get the ip only from a linux box
	if ($machine =~ m/Linux/i) {
		$Linux = 1;
	} else {
        die "Unable to determine the IP of interface $device. OS is not Linux.";
	}
	if ($Linux) {

		# extracts information out of ifconfig command
		$output = `/sbin/ifconfig $device | grep 'inet addr'`;
		$output =~ /addr:(\d+\.\d+\.\d+\.\d+)/;
		$ip = $1;
		$output =~ /Mask:(\d+\.\d+\.\d+\.\d+)/;
		$mask = $1;
	}
	if (!defined($ip)) {
		$ip = "Unassigned";
        die "Unable to get the IP from interface $device";
	}

	# don't really care about mask but we'll get it anyway
	if (!defined($mask)) {
		$mask = "No mask";
	}

	# all we care about is the actual ip address of that interface
	return ($ip);
}

=pod

=item *

_getmac gets the current MAC address of the specified interface.

I<Inputs>:
Requires the interface so that it can find the MAC address of that interface
I<Output>: returns the mac address of the interface

=cut

sub _getmac {
	my $device  = shift;
	my $machine = `uname`;
	my ($Linux, $output) = q{};

	# checking to make sure the machine is a linux box
	if ($machine =~ m/Linux/i) {
		$Linux = 1;
	} else {
        die "Unable to determine the MAC address of interface $device. OS is not Linux.";
	}
	if ($Linux) {

		# grepping the results of ifconfig ethx
		$output = `/sbin/ifconfig $device | grep HWaddr`;
		$output =~ /(.{1,2}:.{1,2}:.{1,2}:.{1,2}:.{1,2}:.{1,2})/;
		$output = $1;
		chomp($output);
	}

	# checking to make sure we get a value here
	if (!defined($output)) {
		$output = "MAC address not defined";
        die "Unable to get the MAC address from interface $device";
	} else {

		# return the mac address here
		return ($output);
	}
}

=pod

=item *

_resolveHost() is a helper function that takes in destination domain name and
spits out an array list of resolved ip addresses

I<Inputs>:
Requires domain name ($host)
I<Output>: returns array list of resolved IP addresses

=cut

sub _resolveHost {

	#import libraries
	use Net::DNS::Resolver;
    use Net::IP;
	use Carp ();
	my $resolver = Net::DNS::Resolver->new();

	# TODO: Make these timeouts non-static.
	$resolver->tcp_timeout(10);
	$resolver->udp_timeout(10);

	# Extract arguments -  passed in
	my ($host) = @_;
	my @ret    = ();

    # Check to see if the host is already a valid IP address.
    my $ip = Net::IP->new($host);
    if (defined($ip)) {
        push (@ret, $ip->ip());
        return @ret;
    }

	my $query  = $resolver->search($host);

	# Sanity check.
	if (!$query) {
        # XXX: Instead of halting on unknown host errors, we just simply
        # resolve unknown entries to localhost and warn on the error.
		Carp::carp "Error: Unable to resolve host '" . $host . "'. "
		  . $resolver->errorstring . "\n";
        push(@ret, '127.0.0.1');
        return @ret;
	}
	foreach $record ($query->answer()) {
		next unless $record->type eq "A";

		#push the ip address into the @ret array
		push(@ret, $record->address);
	}
	return @ret;
}

=pod

=item *

fwOff() opens up our firewall.

I<Inputs>: n/a
I<Output>: nothing

=cut

sub fwOff {

	# package name
	my $class = shift;

	# flush all entries in all chain and delete the chains
	_flushChains();

# turns off the firewall and sets the policy to the default chains (INPUT, OUTPUT, and FORWARD)
# to ACCEPT
	_setAcceptPolicy();
}

=pod

=item *

killProcess();

This is a function kills all systems process based on the command line name give via the remote call.
It looks through the process table and removes all processes with that key name.

<Inputs>:
no input

I<Output>: destruction of all Process IDs.

=cut

sub killProcess {
	use Proc::ProcessTable;
	my $class   = shift;
	my $process = shift;
	my ($t, $p, $success) = "";
	$t = new Proc::ProcessTable;
	chomp($process);
	foreach my $p (@{ $t->table }) {
		if ($p->cmndline =~ /$process/) {
			$success = 1;
			print "Removing $process pid " . $p->pid . "\n";
			$p->kill(9) or die ("Error: Unable to kill process $process");
		}
	}
	return ($success);
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  checkDiskSize();

checkDiskSize() checks the size of the honeywall partitions and makes sure the disk does not fill up.  If
it reaches a certain level (90%), then it shoots off an email to root and logs it to hard disk.

I<Inputs>:
no inputs

I<Output>: outputs the percentage of hard disk that is filled per partition.

=cut

sub checkDiskSize {
	my $class  = shift;
	my $target = "90";
	my $disksize;
	my $sendmail = 1;
	my $MACHINE  = `uname`;
	my $address  = "root";
	my $linux    = 0;
	my $mail     = "/usr/bin/mail";
	my $df       = "/bin/df";
	my $grep     = "/bin/grep";

	if ($MACHINE =~ m/Linux/i) {
		$linux = 1;
	} else {
		$linux = 0;
	}
	if ($linux) {
		my @partitions =
		  qw(/dev/sda1 /dev/sda2 /dev/sda5 /dev/sda6 /dev/sda7 /dev/sda8 /dev/sda9);
		foreach my $part (@partitions) {
            # TODO: Check to make sure this system call returns properly.
			$disksize = `$df -k | $grep $part | cut -b53-54`;
			if ($disksize > 50) {
				print "$part\t$disksize%\n";
			} else {
				print "All filesystems are within their limits\n";
			}
		}
	}
}

=pod

=item *

[NOT IMPLEMENTED AT THIS TIME]:  isCompromised();

isCompromised() checks the iptables log files to see if there has been a compromise to one of the VM images.

I<Inputs>:  hash reference($hashref)

I<Output>:  none

=cut

sub isCompromised {

	# check to see if /var/log/iptables file exists
	# if exists, parse all logs with TAG (hwall)
	# grab the VMID of all those entries
	# report back VMID(s) that could possibly be compromised
	# return VMID list

}


=pod

=item *

checkLog();

checkLog() checks for network anomalies (MAC address spoofing) or any blocked outbound traffic that orginates from
anywhere from the VM subnet.

I<Inputs>:  hash reference($hashref)

I<Output>:  none

=cut

sub checkLog {
	my $class    = shift;
	my $hashref  = shift;
#	my $filename = getVar(name => "iptableslog")
	my $vmname   = _getVMName($hashref);
	my $filename = "/root/honeyclient/sandbox/alphaFW/test.log";
#	macCheck($hashref, $vmname, $filename);
}

=pod

=item *

runTcpdump() - starts a tcpdump procces for a specified VM machine.

I<Inputs>:  VM name and the source IP address of the image.

I<Output>:  none

=cut

#sub runTcpdump {
#	my $class   = shift;
#	my $hashref = shift;
#
#	# gets the vm name
#	my $vmname = _getVMName($hashref);
#
#	# get the source IP address of the VM
#	my $vmaddress = _getSourceIP($hashref);
#
## calls startTcpdump to start tcpdump process for that VM   - logs all traffic outbound from $vmaddress
#	createPcap($vmname, $vmaddress);
#}

=pod

=item *

clearTcpdump() - Deletes the corresponding tcpdump .pcap file, then creates a new file for logging.

I<Inputs>:  none

I<Output>:  none

=cut

#sub clearTcpdump {
#	my $class   = shift;
#
## calls startTcpdump to start tcpdump process for that VM   - logs all traffic outbound from $vmaddress
#	flushTcpdump($vmname, $vmaddress);
#}

=pod

=item *

removeTcpdump() - removes the corresponding  tcpdump .pcap file

I<Inputs>:  VM name and the source IP address of the image.

I<Output>:  none

=cut

#sub removeTcpdump {
#	my $class   = shift;
#	my $hashref = shift;
#
#	# gets the vm name
#	my $vmname = _getVMName($hashref);
#
##	# get the source IP address of the VM
##	my $vmaddress = _getSourceIP($hashref);
#
## calls startTcpdump to start tcpdump process for that VM   - logs all traffic outbound from $vmaddress
#	destroyTcpdump($vmname);
#}



=pod

=item *

_getSourceIP() - gets the source IP address from the hash table sent from the HoneyClient Manager

I<Inputs>:  hash reference
I<Output>:  source ip address

=cut

sub _getSourceIP {

	# pass in the hashref here
	my $hashref = shift;
	my ($vm_ID, $src_MAC_addr, $src_IP_addr) = q{};

	# Get the VM identifier.
	foreach $vm_ID (keys %{$hashref}) {

		# Get the VM's source MAC address.
		foreach $src_MAC_addr (keys %{ $hashref->{$vm_ID}->{'sources'} }) {

			# Get the VM's source IP address.
			foreach $src_IP_addr (
					 keys %{ $hashref->{$vm_ID}->{'sources'}->{$src_MAC_addr} })
			{
				return ($src_IP_addr);
			}
		}
	}
}

=pod

=item *

testConnect() - will allow the user to test connectivity for all their
VM's sitting on the backend network behind the honeywall.

I<Inputs>:  package name is passed by default

I<Output>:  $success; boolean value to determine if iptables inserted the rules or not.

=cut

sub testConnect {
	my $class = shift;
	my $table = IPTables::IPv4::init('filter');
	my $dnsport = getVar(name => "dnsport");
	my $status;

	_set_ip_forwarding(0);
	# Set the chain policies to ACCEPT
	_setAcceptPolicy();
	# flush all the chains
	_flushChains();
	# Create our NAT rule in the POSTROUTING chain
	_createNat();
	_set_ip_forwarding(1);

	return 1;

}


__END__



=head1 SEE ALSO

L<http://www.honeyclient.org/trac>

SOAP::Lite, SOAP::Transport::HTTP

L<http://www.soaplite.com>

IPTables::IPv4

Net::DNS

IPTables Perl API
L<http://sourceforge.net/projects/iptperl/>

Data::Dumper, English, Proc::ProcessTable, FileHandle

L<http://www.honeyclient.org/trac>

=head1 REPORTING BUGS

L<http://www.honeyclient.org/trac/newticket>

=head1 ACKNOWLEDGEMENTS

Derrik Pates for providing the IPTables perl API code and to the sourceforge perl API mailing list for providing
detailed support about the IPTables::IPv4 module.

=head1 AUTHOR

JD Durick, E<lt>jdurick@mitre.orgE<gt>

Xeno Kovah, E<lt>xkovah@mitre.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 The MITRE Corporation.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

