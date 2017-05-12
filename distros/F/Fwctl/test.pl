use vars qw( $x );
use strict;

$| = 1;

$x = 1;

BEGIN {
    print "1..131\n";
}

sub test {
    my ($name, $got, $expected ) = @_;

    printf STDERR "%-60s", $name;
    if ( $got ne $expected ) {
	print STDOUT "not ok $x\n";
    } else {
	print STDOUT "ok $x\n";
    }
    $x++;
}

use Fwctl;
use Fwctl::RuleSet;

my %fwopts = ( aliases_file	=> "test-data/etc/aliases",
	       interfaces_file  => "test-data/etc/interfaces",
	       rules_file	=> "test-data/etc/rules",
	       accounting_file  => "test-data/log/acct",
	     );

# Starts by testing the find_interface methods
my $fwctl = new Fwctl( %fwopts );

my $if = $fwctl->find_interface( "127.0.0.1" );
test( "find_interface 127.0.0.1", $if->{name}, "LOCAL" );
$if = $fwctl->find_interface( "INTERNET" );
test( "find_interface INTERNET", $if->{name} , "EXT");
$if = $fwctl->find_interface( "192.168.1.0/24" );
test( "find_interface 192.168.1.0/24", $if->{name}, "INT" );
$if = $fwctl->find_interface( "192.168.4.255" );
test( "find_interface 192.168.4.255", $if->{name}, "INT" );
$if = $fwctl->find_interface( "10.10.10.10" );
test( "find_interface 10.10.10.10", $if->{name}, "EXT" );
$if = $fwctl->find_interface( "ANY" );
test( "find_interface ANY", $if->{name}, "ANY" );
$if = $fwctl->find_interface( "192.168.1.2" );
test( "find_interface 192.168.1.2", $if->{name}, "INT1" );

# Test the 16 combination for a telnet connection with
# each policy. 
# SRC_ANY		=> ANY
# SRC_LOCAL_IP		=> INT_IP
# SRC_LOCAL_IMPLIED	=> INT_NET
# SRC_REMOTE		=> INT_REM_HOST
# DST_ANY		=> ANY
# DST_LOCAL_IP		=> PERIM_IP
# DST_LOCAL_IMPLIED	=> PERIM_NET
# DST_REMOTE		=> INTERNET_HOST

$fwopts{rules_file} =  "rules";

# Clear out directory
system( "rm -fr test-data/out/*" );

# Save current chains
system( "ipchains-save > saved-chains" ) == 0
  or die "couldn't save current chains: $?\n";

my $shellcmd = q{ ipchains -L -v -n |tail +28 | perl -pe 's|\(.*\)||; s|^ +\d+ +\d+ ||; s|^ pkts bytes ||' };

my $stripcmd = q{ perl -pe 's|[\t ]+||g' };

my @SRC	    = qw( ANY INT_IP INT_NET INT_REM_HOST      );
my @DST	    = qw( ANY PERIM_IP PERIM_NET INTERNET_HOST );
my @POLICY  = qw( accept account deny );
#@POLICY = ();
for my $pol ( @POLICY ) {
  for my $src ( @SRC ) {
    for my $dst ( @DST ) {
      my @MASQ;
    SWITCH:
      for ($pol) {
	/deny/  && do {
	  @MASQ = qw( nomasq );
	  last SWITCH;
	};
	/accept|account/ && do {
	  @MASQ = qw( masq nomasq );
	  last SWITCH;
	};
      }
      for my $masq ( @MASQ ) {
	open RULES, ">rules" 
	  or die "couldn't open rules file for writing: $!\n";
	print RULES "$pol telnet -src $src -dst $dst -$masq\n";
	close RULES;
	eval {
	    $fwctl = new Fwctl( %fwopts );
	    $fwctl->configure;
	};
	my $filename = "$pol-$src-$dst-$masq";
	if ( $@ ) {
	    print $@;
	    test( $filename, 1, 0 );
	    next;
	}
	system( "$shellcmd > test-data/out/$filename" ) == 0
	  or die "error dumping chains configuration: $?\n";

	# Strip whitespace for comparaison
	system( "$stripcmd < test-data/out/$filename > test-data/out/$filename.out" );
	system( "$stripcmd < test-data/in/$filename > test-data/in/$filename.in" );

	my $result = system( "cmp", "-s", "test-data/in/$filename.in",
			     "test-data/out/$filename.out" );
	test( $filename, $result, 0 );
	unlink "test-data/in/$filename.in";
	unlink "test-data/out/$filename.out";
	# Remote human readable output of test that succeeds.
	unlink "test-data/out/$filename"  if $result == 0;
      }
    }
  }

}

# Some of the other tests
my %SERVICE_TESTS = (
		     "accept-all-INT_NET-INTERNET-masq" => "accept all -src INT_NET  -dst INTERNET -masq",
		     "account-all-INT_NET-PERIM_NET"	=> "account all -src INT_NET -dst PERIM_NET",
		     "accept-dhcp-INT_NET-INT_IP"	=> "accept dhcp -src INT_NET -dst INT_IP",
		     "deny-dhcp-INT_NET"		=> "deny dhcp -src INT_NET -nolog",
		     "accept-ftp-INTERNET-PERIM_HOST"	=> "accept ftp -src INTERNET -dst PERIM_HOST",
		     "accept-ftp-PERIM_HOST-INTERNET-noport"	=>"accept ftp -src PERIM_HOST -dst INTERNET -noport",
		     "accept-http-INTERNET-PERIM_HOST"	=> "accept http -src INTERNET -dst PERIM_HOST",
		     "accept-http-PERIM_HOST-INTERNET-port"	=> "accept http -src PERIM_HOST -dst INTERNET -port 80,443,8000:9000",
		     "accept-name_service-INT_HOST-PERIM_HOST-query" => "accept name_service -src INT_HOST -dst PERIM_HOST -query 5353",
		     "accept-name_service-PERIM_HOST-INTERNET-server" => "accept name_service -src PERIM_HOST -dst INTERNET -server -query  5353",
		     "accept-name_service-INT_NET-INT_IP" => "accept name_service -src INT_NET -dst INT_IP",
		     "deny-netbios-INT_NET-nolog" => "deny netbios -src INT_NET -nolog",
		     "accept-ntp-PERIM_HOST-NTP_SERVERS" => "accept ntp -src PERIM_HOST -dst NTP_SERVERS",
		     "accept-ntp-PERIM_HOST-NTP_SERVERS-masq-client" => "accept ntp -src PERIM_HOST -dst NTP_SERVERS -client -masq",
		     "accept-ping-INT_NET-PERIM_NET"	=> "accept ping -src INT_NET -dst PERIM_NET",
		     "accept-ping-INT_NET-INTERNET-masq"	=> "accept ping -src INT_NET -dst INTERNET -masq",
		     "accept-rsh-PERIM_IP-PERIM_HOST" => "accept rsh -src PERIM_IP -dst PERIM_HOST",
		     "deny-snmp-INT_NET-nolog" =>  "deny snmp -src INT_NET -nolog",
		     "accept-timed-INT_NET-INT_IP" => "accept timed -src INT_NET -dst INT_IP",
		     "accept-traceroute-INT_NET-INTERNET-masq" => "accept traceroute -src INT_NET -dst INTERNET -masq",
		     "accept-traffic_control" => "accept traffic_control",
		     "accept-syslog-INT_HOST-INT_IP" => "accept syslog -src INT_HOST -dst INT_IP -client",
		     "accept-syslog-INTERNET_HOST-EXT_IP" => "accept syslog -src INTERNET_HOST -dst EXT_IP",
		     "accept-hylafax-INT_NET-INT_IP" => "accept hylafax -src INT_NET -dst INT_IP",
		     "accept-telnet-INT_NET_INTERNET-log" => "accept telnet -src INT_NET -dst INTERNET -log",
		     "accept-ping-INTERNET-EXT_IP-account-log" => "accept ping -src INTERNET -dst EXT_IP -log -account -name monitoring",
		     "accept-hylafax-INT_NET-INT_IP"   => "accept hylafax -src INT_NET -dst INT_IP",
		     "accept-pcanywhere-INT_HOST-INTERNET_HOST" => "accept pcanywhere -src INT_HOST -dst INTERNET_HOST",
		     "accept-lpd-INT_HOST-INTERNET_HOST"	=> "accept lpd -src INT_HOST -dst INTERNET_HOST",
		     "accept-telnet-INT_HOST-INT_REM_HOST" => "accept telnet -src INT_HOST -dst INT_REM_HOST",
		     "accept-telnet-INT_NETS-INT_REM_HOST" => "accept telnet -src INT_NETS -dst INT_REM_HOST",
		     "accept-telnet-INT_REM_NETS-INT_REM_HOST" => "accept telnet -src INT_REM_NETS -dst INTERNET_HOST",
		     "accept-ip_pkt-INT_HOST-INTERNET_HOST" => "accept ip_pkt -src INT_HOST -dst INTERNET_HOST --proto ipip",
		     "accept-udp_pkt-INT_HOST-INTERNET_HOST" => "accept udp_pkt -src INT_HOST -dst INTERNET_HOST --masq --port 514",
		     "accept-icmp_pkt-INT_IP-INT_NET" => "accept icmp_pkt -src INT_IP -dst INT_NET --code redirect",
		     "accept-pptp-INT_HOST-INTERNET_HOST-masq"       => "accept pptp -src INT_HOST  -dst INTERNET_HOST --masq",
		     "accept-ipsec-INT_HOST-INTERNET_HOST"      => "accept ipsec -src INT_HOST -dst INTERNET_HOST",
		     "accept-ssh-INTERNET-INT_HOST-portfw"      => "accept ssh -src INTERNET -dst INT_HOST -portfw",
		     "accept-ftp-INTERNET-INT_HOST-portfw"      => "accept ftp -src INTERNET -dst INT_HOST --portfw --nopasv",
		     "accept-udp_service-INT_NET-PERIM_HOST-portfw-INT1_IP"      => "accept udp_service -src INT_NET -dst PERIM_HOST --portfw INT1_IP --port 514",
		     "accept-pptp-INTERNET-INT_HOST-portfw-EXT_IP"      => "accept pptp -src INTERNET -dst INT_HOST --portfw EXT_IP",
		     "accept-ftp-INT_NET-INTERNET-masq"      => "accept ftp -src INT_NET -dst INTERNET --masq",
		     "accept-telnet-VPN_CLIENT1-VPN1_IP"     => "accept telnet -src VPN_CLIENT1 -dst VPN1_IP",
		     "accept-telnet-VPN_CLIENT2-VPN2_IP"     => "accept telnet -src VPN_CLIENT2 -dst VPN2_IP",
		     "accept-telnet-VPN_CLIENT2-INT_NET"     => "accept telnet -src VPN_CLIENT2 -dst INT_NET",
		     "accept-ica-INT_NET-INTERNET_HOST-masq"     => "accept ica -src INT_NET -dst INTERNET_HOST -masq",
		     "accept-ica-INTERNET-INT_HOST-portfw-nobrowse"     => "accept ica -src INTERNET -dst INT_HOST --portfw --nobrowse",
		    );

#%SERVICE_TESTS = ();
for my $name ( sort keys %SERVICE_TESTS) {
  my $rule = $SERVICE_TESTS{$name};
  open RULES, ">rules" 
    or die "couldn't open rules file for writing: $!\n";
  print RULES $rule, "\n";
  close RULES;
  eval {
      $fwctl = new Fwctl( %fwopts );
      $fwctl->configure;
  };
  if ( $@ ) {
      print $@;
      test( $name, 1, 0 );
      next;
  }
  system( "$shellcmd > test-data/out/$name" ) == 0
    or die "error dumping chains configuration: $?\n";

  # Strip whitespace for comparaison
  system( "$stripcmd < test-data/out/$name > test-data/out/$name.out" );
  system( "$stripcmd < test-data/in/$name > test-data/in/$name.in" );

  my $result = system( "cmp", "-s", "test-data/in/$name.in",
		       "test-data/out/$name.out" );
  test( $name, $result, 0 );
  # Remote output of test that succeeds.
  unlink "test-data/in/$name.in";
  unlink "test-data/out/$name.out";
  unlink "test-data/out/$name"  if $result == 0;
}

END {
  if (-e "saved-chains" ) {
    system ( "ipchains", "-F" );
    system ( "ipchains", "-X" );
    system( "ipchains-restore < saved-chains" ) == 0
      or die "failed to restore chains: $?\n";
    unlink "saved-chains";
  }
  unlink "rules";
}


1;



