package Device::Router::RTX;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw//;
use warnings;
use strict;
our $VERSION = '0.06';

use Carp qw/carp croak/;
# DEPENDS
use Net::Telnet;
use Net::TFTP;
# use Net::IP;
# END DEPENDS

sub _read_config
{
    my ($configfile, $args) = @_;
    if (!-f $configfile) {
	print <<EOF;
I was told that there was a configuration file in '$configfile' but
I can't seem to find it.
EOF
	return;
    }
    open my $input, "<", $configfile or die $!;
    while (my $line = <$input>) {
	next if $line =~ /^#/;
	if ($line =~ /^(\w+):\s*(.*?)\s*$/) {
	    my $parameter = $1;
	    $parameter = lc $parameter;
	    my $value = $2;
	    $args->{$parameter} = $value;
	} else {
	    die "$configfile:$.: parse error at '$line'";
	}
    }
    close $input or die $!;
}

sub new
{
    my ($class, %args) = @_;
    my $rtx = {};
    for (keys %args) {
	$_ = lc $_;
    }
    if ($args{config}) {
	_read_config ($args{config}, \%args);
    }
    if (!$args{store}) {
#	carp "No file store specified";
    }
    elsif (! -d $args{store}) {
#	carp "File store '$args{store}' is not a valid directory";
    }
    else {
	$rtx->{store} = $args{store};
    }
    if (!$args{address}) {
	croak "No internet protocol address for router";
    }
    else {
	$rtx->{address} = $args{address};
    }
    if (defined($args{password})) {
	$rtx->{password} = $args{password};
    }
    else {
	$rtx->{password} = "";
    }
    if (defined($args{admin_password})) {
	$rtx->{admin_password} = $args{admin_password};
    }
    else {
	$rtx->{admin_password} = "";
    }
    $rtx->{verbose} = $args{verbose};
    bless $rtx;
    return $rtx;
}

sub _check
{
    my ($rtx) = @_;
    if (!$rtx || ref $rtx ne __PACKAGE__) {
	die "Bad object passed";
    }
    if (!$rtx->{address}) {
	die "No internet protocol address for router in object";
    }
}

sub connect
{
    my ($rtx) = @_;
    _check ($rtx);
#    my $telnet_connection = new Net::Telnet (Dump_Log => "stuff.txt");
    my $telnet_connection = new Net::Telnet();
#    $telnet_connection->option_log (*STDERR);
    # See documentation for Net::Telnet
    $telnet_connection->open ($rtx->{address});
    if ($rtx->{password}) {
#	$telnet_connection->print ();
	my $stuff = $telnet_connection->get ();
#	print "stuff is: $stuff\n";
	if ($stuff =~ m'Error:  Other user logged in by telnet.') {
	    die "Someone else is already logged in.\n";
	}
	else {
	    $telnet_connection->print ($rtx->{password});
	}
	if ($telnet_connection->eof()) {
	    die "Telnet connection cut off for some reason.\n";
	}
	my $response = $telnet_connection->get();
#	print "Response is: $stuff\n";
    }
    $rtx->{telnet_connection} = $telnet_connection;
}

my $_config_desc = "RTX1000 configuration file";

sub get_config
{
    my ($rtx, $filename) = @_;
    $filename = "config" unless $filename;
    _check ($rtx);
    my $tftp = Net::TFTP->new ($rtx->{address});
    $tftp->ascii;
    if (-f $filename) {
	warn "$_config_desc '$filename' already exists.\n";
	return;
    }
    my $remotefile = "config";
    if ($rtx->{admin_password}) {
	$remotefile .= "/$rtx->{admin_password}";
    }
    elsif ($rtx->{password}) {
	$remotefile .= "/$rtx->{password}";
	carp "Admin password is not set";
    }
    else {
	carp "Neither admin nor user passwords are set";
    }
    if ($rtx->{verbose}) {
	print "Getting $remotefile\n";
    }
    $tftp->get ($remotefile, $filename);
    if ($tftp->error ()) {
	die "tftp get '$remotefile failed': ",$tftp->error ();
    }
    die "TFTP failed" unless -f $filename;
#    open my $input, "<", $filename or die $!;
#    while (<$input>) { print }
#    close $input or die $!;
}

my $ip_address = qr/(?:(?:\d+\.){3}(?:\d+))/;
# The following does not contain the full possibilities with "except" etc.
my $ip_range_re = qr:(($ip_address)-($ip_address)/(\d+)):;
my $mac_re = qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/;
# Reference: Cmdref.pdf page 211
my $protocol_re = qr/(?:esp|tcp|udp|icmp|\d+)/;
# Reference: Cmdref.pdf page 56
my %aliases = (qw/
ftp 20&21
ftpdata 20
telnet 23
smtp 25
domain 53
gopher 70
finger 73
www 80
pop3 110
sunrpc 111
ident 113
ntp 123
nntp 119
snmp 161
syslog 514
printer 515
talk 517
route 520
uucp 540/
);
my @alias_keys = sort {length $b <=> length $a} keys %aliases;
my $port_re = '(?:'.join ('|', @alias_keys).'|\\d+)';

sub _add_mac
{
    my ($config, $mac, $what) = @_;
    $config->{mac}->{$mac} = $what;
    $config->{mac_map}->{$what} = $mac;
}

sub _check_range
{
    my ($range, $ip) = @_;
}

sub read_config
{
    my ($rtx, $filename) = @_;
    $filename = "config" unless $filename;
    die "Cannot find $_config_desc '$filename'" unless -f $filename;
    open my $input, "<", $filename or die $!;
    my $config = {};
    # Default value is to disallow tftp.
    # Reference: Cmdrefs.pdf, page 57
    $config->{tftp_host} = "none";
    while (my $line = <$input>) {
	next if $line =~ /^\s*$/;
	if ($line =~ /#\s+RTX1000\s+Rev\.([\d.]+)/) {
	    $config->{firmware} = $1;
	    next;
	}
	if ($line =~ /mac address\s*:\s*($mac_re)\s*,\s*($mac_re)\s*,\s*($mac_re)/i) {
	    my @macs = ($1, $2, $3);
	    _add_mac ($config, $macs[0], "lan1");
	    _add_mac ($config, $macs[1], "lan2");
	    _add_mac ($config, $macs[2], "lan3");
	    next;
	}
	if ($line =~ /tftp\s+host\s+($ip_address|any|none)/) {
	    $config->{tftp_host} = $1;
	    next;
	}
	if ($line =~ /no\s+tftp\s+host/) {
	    $config->{tftp_host} = "none";
	    next;
	}
	# Login password can be printable ascii characters
	# Reference: Cmdref.pdf, page 43.
	# Reference does not mention whether the space character is OK
	# or not. Here I have assumed "not".
	if ($line =~ /(administrator|login)\s+password\s+([[:graph:]]+)/) {
	    $config->{$1."_password"} = $2;
	    next;
	}
	if ($line =~ m:ip\s+lan(\d)\s+address\s+($ip_address)/(\d+):) {
	    my $lan = "lan$1";
	    $config->{$lan}->{address} = $2;
	    $config->{$lan}->{mask}    = $3;
	    next;
	}
	if ($line =~ /nat\s+descriptor\s+type\s+(\d+)\s+(masquerade)/) {
	    my $nat_descriptor = $1;
	    my $type = $2;
	    $config->{nat}->{$nat_descriptor}->{type} = $type;
	    next;
	}
	# Reference: Cmdref.pdf page 211
	if ($line =~ /nat\s+descriptor\s+masquerade\s+(static)\s+(\d+)\s+(\d+)\s+($ip_address)\s+($protocol_re)\s+(?:($port_re)=)?($port_re)/) {
	    my $nat_descriptor = $2;
	    my $id = $3;
	    my $ip = $4;
	    my $protocol = $5;
	    my $outer_port = $6;
	    my $inner_port = $7;
	    $config->{nat}->{$nat_descriptor}->{$id} =
	    {
	     id         => $id,
	     ip         => $ip,
	     protocol   => $protocol,
	     outer_port => $outer_port,
	     inner_port => $inner_port
	    };
	    next;
	}
	if ($line =~ /dhcp\s+scope\s+(\d+)\s+$ip_range_re/) {
	    my $scope = $1;
	    my $range = $2;
	    $config->{dhcp}->{$scope}->{range} = $2;
	    next;
	}
	if ($line =~ /dhcp\s+scope\s+bind\s+(\d+)\s+($ip_address)\s+(ethernet\s+)?($mac_re)/i) {
	    my $scope = $1;
	    my $scope_hash = $config->{dhcp}->{$scope};
	    if (!$scope_hash) {
		print "Warning: unknown scope $scope\n";
	    }
	    else {
		my $ip = $2;
		_check_range ($scope_hash->{range}, $ip);
		my $mac = $4;
		_add_mac ($config, $mac, $ip);
		# Add the data to scope_hash
		$scope_hash->{$ip} = {mac => $mac};
	    }
	    next;
	}
	next if $line =~ /^#/;
	$line =~ s/\s+$//;
	print "Unrecognized line '$line'\n";
    }
    close $input or die $!;
    $rtx->{config} = $config;
}

# Do one command

sub _command
{
    my ($rtx, $command) = @_;
    _check ($rtx);
    $rtx->connect() unless $rtx->{telnet_connection};
    $rtx->_admin_login();
    my @lines = $rtx->{telnet_connection}->cmd ("$command\n");
    my $retval = join ("", @lines);
    die "Error doing '$command': $retval" if $retval =~ /Error:/;
    return @lines;
}

# Save the configuration to permanent memory

sub save
{
    my ($rtx) = @_;
    _check ($rtx);
    my @lines = $rtx->_command ("save\n");
    my $retval = join ("", @lines);
    die "Save failed: $retval" unless $retval =~ /Saving.*Done/;
}

sub _admin_login
{
    my ($rtx) = @_;
    _check ($rtx);
    return if $rtx->{admin};
    my $admin_login_cmd = "administrator\n$rtx->{admin_password}\n";
    my @reply =	$rtx->{telnet_connection}->cmd($admin_login_cmd);
    $rtx->{admin} = 1;
}

sub command
{
    my ($rtx, $command) = @_;
    _check ($rtx);
    $rtx->_command ("$command\n");
    $rtx->save ("$command\n");
}

sub _check_mac
{
    my ($mac) = @_;
    die "Bad MAC address '$mac'" unless $mac =~ /$mac_re/i;
}

sub wake
{
    my ($rtx, $lan, $mac) = @_;
    _check ($rtx);
    _check_mac ($mac);
    # Reference: Cmdrefs.pdf, page 305
    my @output = $rtx->_command ("wol send lan$lan $mac");
    print "@output\n";
}

sub arp
{
    my ($rtx) = @_;
    _check ($rtx);
    my @output = $rtx->_command("show arp");
    my @arp;
    for my $line (@output) {
	if ($line =~ /LAN(\d)\s+($ip_address)\s+($mac_re)\s+(\d+)/) {
	    my %arp_data;
	    $arp_data{lan} = $1;
	    $arp_data{ip}  = $2;
	    $arp_data{mac} = $3;
	    $arp_data{ttl} = $4;
	    push @arp, \%arp_data;
	}
    }
    if (@arp) {
	return \@arp;
    }
    return;
}

1;
