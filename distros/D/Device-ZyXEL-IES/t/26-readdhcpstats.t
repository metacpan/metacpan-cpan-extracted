use strict;
use warnings;
use Test::More tests => 2;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

my $s_adsl = Device::ZyXEL::IES::Slot->new(
  id => 3, ies => $d);

my $p_adsl = Device::ZyXEL::IES::Port->new(
  id => 301, slot => $s_adsl );


# Hooking for test ============================================================
# hook allows snmpget from Net::SNMP::Util
{
 no warnings;

 *{Net::SNMP::_send_pdu} = sub {
    my ( $this ) = @_;
    foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
      if ( $oid eq '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.1.301' ) {
	    $this->{_pdu}{_var_bind_list}{ $oid } = 14; # DISCOVERY
	  }
      elsif ( $oid eq '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.2.301' ) {
	    $this->{_pdu}{_var_bind_list}{ $oid } = 28; # OFFER
	  }
      elsif ( $oid eq '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.3.301' ) {
	    $this->{_pdu}{_var_bind_list}{ $oid } = 32; # REQUEST
	  }
      elsif ( $oid eq '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.4.301' ) {
	    $this->{_pdu}{_var_bind_list}{ $oid } = 44; # ACK
	  }
      elsif ( $oid eq '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.5.301' ) {
	    $this->{_pdu}{_var_bind_list}{ $oid } = 0; # ACKBYSNOOPFULL
	  }
      else {
		 diag("unknown oid: $oid");
         $this->{_pdu}{_var_bind_list}{ $oid } = "?";
      }
    }
								
    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 }

};
								  
my ($pdr, $t);

$pdr = $p_adsl->read_dhcp_stats();
ok( $pdr->{'dhcpDiscovery'} == 14 );
ok( $p_adsl->dhcpDiscovery == 14);

