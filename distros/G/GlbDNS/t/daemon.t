


# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More tests => 5;
BEGIN { use_ok('GlbDNS') };
BEGIN { use_ok('GlbDNS::Zone') };
use Net::DNS;

use Data::Dumper;
use Working::Daemon;
my $daemon = Working::Daemon->new();
$GlbDNS::TEST{noadmin}  = 1;
$daemon->name("glbdns");
$daemon->parse_options(
    "port=i"     => 15789             => "Which port number to listen to",
    "address=s"  => "0.0.0.0"      => "IP Address to listen to",
    "syslog"     => 0              => "Syslog",
    "config=s"   => "" => "Configuration directory",
    "loglevel=i" => 1              => "What level of messaes to log, higher is more verbose",
    "zones=s"    => "t/zone_dir"        => "Where to find zone files",
    );


$daemon->daemon(0);

if(fork()) {
  sleep 1;
  my $resolver = Net::DNS::Resolver->new(nameservers => ["127.0.0.1"], recurse => 0, debug => 0);
  $resolver->port("15789");
  my $packet = $resolver->query("london.example.local", "A");
  is($packet->answer    , 2);
  is($packet->authority , 4);
  is($packet->additional, 4);
  sleep 6;
} else {
  $SIG{ALRM} = sub { die "timeout"};
  my $glbdns = GlbDNS->new($daemon);
  GlbDNS::Zone->load_configs($glbdns, "t/zone_dir/");
  alarm 5;
  eval {
    $glbdns->start;
  };
  if($@ !~/timeout/) {
    fail($@);
  }
}




