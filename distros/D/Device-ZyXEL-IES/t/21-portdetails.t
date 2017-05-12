use strict;
use warnings;
use Test::More tests => 6;
use Net::SNMP qw(:asn1);
use Data::Dumper;
use Device::ZyXEL::IES;

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

isa_ok( $d,   'Device::ZyXEL::IES' );

my $s = Device::ZyXEL::IES::Slot->new(
  id => 3, cardtype => 'foobar', ies => $d);

isa_ok( $s, 'Device::ZyXEL::IES::Slot' );

my $p = Device::ZyXEL::IES::Port->new(
  id => 301, slot => $s, adminstatus => 2 );

isa_ok( $p, 'Device::ZyXEL::IES::Port' );


# Hooking for test ============================================================
# hook allows snmpget from Net::SNMP::Util
{
 no warnings;

 *{Net::SNMP::_send_pdu} = sub {
    my ( $this ) = @_;
	my $nofOids = scalar( keys ( %{$this->{_pdu}{_var_bind_list}} ));
    foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
      if ( $oid =~ /^.1.3.6.1.2.1.10.94.1.1.1.1.4.\d+$/ ||
           $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.8.1.1.1.\d+$/ ) {
         $this->{_pdu}{_var_bind_list}{ $oid } = 'profile';
      }
      else {
         $this->{_pdu}{_var_bind_list}{ $oid } = 2; # some number that validates with all attributes
      }
    }
								
    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 }

};
								   
my $pdr = $p->fetchDetails();

ok($pdr eq 'OK');

ok($p->profile eq 'profile');
ok($p->operstatus == 2);

