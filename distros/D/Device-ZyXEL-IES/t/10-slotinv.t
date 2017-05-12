use strict;
use warnings;
use Test::More tests => 22;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

my ($max);

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
     my ($base, $s);
     if ( $oid =~ /^(.*\.[34]\.0)\.(\d+)$/ ){ # type
       ($base, $s) = ($1, $2);
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
	   $base = $oid;	 
       $n = "$oid.1";
       $s = 1;
      }
      push @names,  $n;
      $vlist{ $n } = sprintf("%s(%d-%d)",  ($base =~ /^.*\.3\.0$/)?'Type':'Firmware',  int($s),  $this->{_version}+1 );
      $types{ $n } = OCTET_STRING;
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

$max = 10;

my $si = $d->slotInventory();

# Now the slots should contain something
#
ok (scalar( keys %{$d->slots}) == 10 );

my $si2 = $d->slotInventory();

ok (scalar( keys %{$d->slots}) == 10 );

#diag ( Dumper( $s ) );

my $slots = $d->slots;
foreach my $s ( keys %{$slots} ) {
	isa_ok( $slots->{$s}, 'Device::ZyXEL::IES::Slot' );
  ok( $slots->{$s}->cardtype eq sprintf("Type(%d-1)", $s) );
}

