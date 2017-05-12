use strict;
use warnings;
use Test::More tests => 101;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

my ($base, $max, $identifier, $startat);

# Hooking for test ============================================================
# Taken from Net::SNMP::Util
{
 no warnings;

*{Net::SNMP::_send_pdu} = sub {
   my ( $this ) = @_;
   my %vlist = ();
   my @names = ();
   my %types = ();
   foreach my $oid ( @{$this->{_pdu}{_var_bind_names}} ){
      my $n;
      my $s;
      if ( $oid =~ /^$base\.(\d+)$/ ){
		 $s = $1;
         if ( $s<$max ){
            $n = "$base.".($s+1);
		    $s++;
         } 
		 else {
		  if ( $base =~ /^(.*)\.(\d+)$/ ) {
			 $n = "$1.".($2+1);
			}
			else {
			 $n = "huh";
			}
		 }
      } 
	  else {
         $n = $oid.'.'.$startat;
		 $s = 1;
      }
      push @names,  $n;
      if ( $base =~ /^.*\.3\.0$/ ) {
        $vlist{ $n } = sprintf("%s", ('ALC1248G-51', 'VLC1224G-51')[int(rand(2))]);
        $types{ $n } = OCTET_STRING;
      }
      else {
        $vlist{ $n } = 2;
        $types{ $n } = INTEGER;
      }
   }
   $this->{_pdu}{_var_bind_list}  = \%vlist;
   $this->{_pdu}{_var_bind_names} = \@names;
   $this->{_pdu}{_var_bind_types} = \%types;

   return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 };
};

# call the slotInventory method
my ($d);

undef $d;
$d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

($base, $max, $startat) = ('.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0', 3, 1);

my $si = $d->slotInventory();

# Now the slots should contain something
#
my $s = $d->slots;

ok ($d->num_slots == 3 );
ok ($d->has_slot('3'));

# What if the card type changes to one with lesser ports?
# create an SNMP catcher for cardtype lookup for portInventory
{
 no warnings;

 *{Net::SNMP::_send_pdu} = sub {
    my ( $this ) = @_;
    foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
      if ( $oid =~ /^\.1\.3\.6\.1\.2\.1\.10\.94\.1\.1\.1\.1\.4\.\d+$/ ) {
        $this->{_pdu}{_var_bind_list}{ $oid } = 'ADSLprofile';
      }
      elsif ( $oid =~ /^\.1\.3\.6\.1\.2\.1\.10\.97\.1\.1\.1\.1\.3\.\d+$/ ) {
        $this->{_pdu}{_var_bind_list}{ $oid } = 'VDSLprofile';
      }
      elsif ( $oid =~ /^\.1\.3\.6\.1\.2\.1\.10\.48\.1\.1\.1\.1\.2\.\d+$/ ) {
        $this->{_pdu}{_var_bind_list}{ $oid } = 'VDSLprofile';
      }
      elsif ( $oid =~ /^\.1\.3\.6\.1\.4\.1\.890\.1\.5\.13\.5\.6\.3\.1\.3\.0\.3$/ ) {
        $this->{_pdu}{_var_bind_list}{ $oid } = 'VLC1224G-51';
      }
	  else {
        $this->{_pdu}{_var_bind_list}{ $oid } = 2;
	  }
    }
    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
  };
};
			   

# portInventory will fetch the card type and 
# call fetchdetails for all ports created
my $slot = $d->get_slot('3');
my $pi = $slot->portInventory();

ok($pi eq 'OK');

my $p = $slot->ports;

ok( $slot->num_ports == 24);

foreach my $port ( $slot->port_pairs ) {
	my $p = $port->[1];
  isa_ok( $p, 'Device::ZyXEL::IES::Port' );
  ok($p->id =~ /^\d+$/);

  ok($p->profile =~ /profile/);
  ok( $p->adminstatus == 2 );
}

my $port = $slot->get_port('301');

isa_ok( $port,   'Device::ZyXEL::IES::Port' );

