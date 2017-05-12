use strict;
use warnings;
use Test::More tests => 8;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

# Hooking for test ============================================================
# Taken from Net::SNMP::Util
{
 no warnings;

*{Net::SNMP::_send_pdu} = sub {
   my ( $this ) = @_;
   foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
     if ( $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0.3$/ ) {
       $this->{_pdu}{_var_bind_list}{ $oid } = 'ALC1248G-51';
     }
   } 	 
   return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 };
};

# call the slotInventory method
my ($d);

undef $d;
$d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

# create a slot object
my $s = Device::ZyXEL::IES::Slot->new(
  id => 3, 
  cardtype => 'VLC1224-51', 
  ies => $d);

# instanciating a slot with a card type given should yield
# no initialization of any other attributes, since the value
# is not to be trusted unless it is actually delivered by the 
# IES
ok( scalar(keys %{$s->ports}) == 0);
ok( $s->iftype eq 'ADSL' ); ## the default

# create another slot object
my $s2 = Device::ZyXEL::IES::Slot->new(
  id => 3, 
  ies => $d);

my $slotlist = $d->slots();

ok( $d->has_slot( 3 ) );
ok( !$d->has_slot( 4 ) );

$s2->read_cardtype();

ok( scalar(keys %{$s2->ports}) == 48);
ok( $s2->iftype eq 'ADSL' );


# What if the card type changes to one with lesser ports?
{
 no warnings;

*{Net::SNMP::_send_pdu} = sub {
   my ( $this ) = @_;
   foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
     if ( $oid =~ /^.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0.3$/ ) {
       $this->{_pdu}{_var_bind_list}{ $oid } = 'VLC1224G-51';
     }
   } 	 
   return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 };
};

# "discover" that the card type is new
$s2->read_cardtype();
ok( scalar(keys %{$s2->ports}) == 24);
ok( $s2->iftype eq 'VDSL' );
