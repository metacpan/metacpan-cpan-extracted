use strict;
use warnings;
use GlbDNS;

use Working::Daemon::Syslog;
my $daemon = Working::Daemon->new();

$daemon->name("glbdns");
$daemon->parse_options(
    "port=i"     => 53             => "Which port number to listen to",
    "address=s"  => "0.0.0.0"      => "IP Address to listen to",
    "syslog"     => 0              => "Syslog",
    "config=s"   => "/etc/glbdns/" => "Configuration directory",
    "loglevel=i" => 1              => "What level of messaes to log, higher is more verbose",
    "zones=s"    => "zone/"        => "Where to find zone files",
    );

# this should be support cleaner by Working::Daemon
if ($daemon->options->{syslog}) {
    bless $daemon, 'Working::Daemon::Syslog';
    $daemon->init;
}

$daemon->do_action;

my $dns = GlbDNS->new($daemon);

#use GlbDNS::Config;
use GlbDNS::Zone;


#GlbDNS::Config->load_configs($dns, $daemon->options->{config});
GlbDNS::Zone->load_configs($dns, $daemon->options->{zones});

$dns->start();
