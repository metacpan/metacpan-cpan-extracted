use strict;
use warnings;
use Test::More tests => 7;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

isa_ok( $d,   'Device::ZyXEL::IES' );

my $s = Device::ZyXEL::IES::Slot->new(
  id => 3, ies => $d);

isa_ok( $s, 'Device::ZyXEL::IES::Slot' );

my $p = Device::ZyXEL::IES::Port->new(
  id => 301, slot => $s );

isa_ok( $p, 'Device::ZyXEL::IES::Port' );


# Hooking for test ============================================================
# hook allows snmpget from Net::SNMP::Util
{
 no warnings;

 *{Net::SNMP::_send_pdu} = sub {
    my ( $this ) = @_;
    foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
      if ( $oid =~ /^.*\.1\.8\.\d+$/ ) { # operstatus
         $this->{_pdu}{_var_bind_list}{ $oid } = 2;
      }
      elsif ( $oid =~ /^.*\.1\.7\.\d+$/ ) { # adminstatus
         $this->{_pdu}{_var_bind_list}{ $oid } = 2;
			}
      else {
         $this->{_pdu}{_var_bind_list}{ $oid } = "profile";
      }
    }
								
    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 }

};
								   
my $pdr = $p->read_operstatus();

ok($pdr == 2);

ok($p->operstatus == 2);

$pdr = $p->read_adminstatus();

ok($pdr == 2);

ok($p->adminstatus == 2);
