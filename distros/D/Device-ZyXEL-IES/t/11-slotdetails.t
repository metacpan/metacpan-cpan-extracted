use strict;
use warnings;
use Test::More tests => 13;
use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

isa_ok( $d,   'Device::ZyXEL::IES' );

my $s_shdsl = Device::ZyXEL::IES::Slot->new(
  id => 3, ies => $d);

my $s_vdsl = Device::ZyXEL::IES::Slot->new(
  id => 4, ies => $d);

my $s_adsl = Device::ZyXEL::IES::Slot->new(
  id => 5, ies => $d);


# Hooking for test ============================================================
# hook allows snmpget from Net::SNMP::Util
{
 no warnings;

 *{Net::SNMP::_send_pdu} = sub {
    my ( $this ) = @_;
	my $nofOids = scalar( keys ( %{$this->{_pdu}{_var_bind_list}} ));
    foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
      if ( $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.6.3.1.4.0.\d+$/ ) {
         $this->{_pdu}{_var_bind_list}{ $oid } = 'firmware';
      }
      elsif ( $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0.3$/ ) {
         $this->{_pdu}{_var_bind_list}{ $oid } = 'SLC1248G-22';
      }
      elsif ( $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0.4$/ ) {
         $this->{_pdu}{_var_bind_list}{ $oid } = 'VLC1348G-51';
      }
      elsif ( $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0.5$/ ) {
         $this->{_pdu}{_var_bind_list}{ $oid } = 'ALC1248G-51';
      }
      else {
		 diag("Unmatched oid: $oid used");
      }
    }
								
    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 }

};
								   
my $pdr = $s_shdsl->fetchDetails();

ok($pdr eq 'OK');
ok($s_shdsl->firmware eq 'firmware');
ok($s_shdsl->cardtype eq 'SLC1248G-22');
ok($s_shdsl->iftype eq 'SHDSL');

$pdr = $s_vdsl->fetchDetails();

ok($pdr eq 'OK');
ok($s_vdsl->firmware eq 'firmware');
ok($s_vdsl->cardtype eq 'VLC1348G-51');
ok($s_vdsl->iftype eq 'VDSL');

$pdr = $s_adsl->fetchDetails();

ok($pdr eq 'OK');
ok($s_adsl->firmware eq 'firmware');
ok($s_adsl->cardtype eq 'ALC1248G-51');
ok($s_adsl->iftype eq 'ADSL');
