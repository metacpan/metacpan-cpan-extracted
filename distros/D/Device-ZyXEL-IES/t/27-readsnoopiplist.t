use strict;
use warnings;
use Test::More tests => 3;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

my %SEQUENCE = (
  1 => { ip => '192.168.0.1',  mac => pack("(C)*", 0xFE, 0xDA, 0xBE, 0x33, 0x44, 0x55) }, 
  2 => { ip => '192.168.0.2',  mac => pack("(C)*", 0xFE, 0xDA, 0xBE, 0x44, 0x33, 0x22) }, 
  3 => { ip => '1',  mac => '1' } 
  );

my $nof = 0;

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
	 my $v;
     my ($base, $s);
     if ( $oid =~ /^(\.1\.3\.6\.1\.4\.1\.890\.1\.5\.13\.5\.13\.1\.1\.1\.2\.301).*$/ ){ # right oid
       my $base = $1;
	   $nof++;
	   my $next = $SEQUENCE{$nof};
	   if ( $next->{ip} ne '1' ) {
		 $n = "$base.".$next->{ip};
		 $v = $next->{mac};
	   }
	   else {
		 $n = '1';
		 $v = $next->{mac};
	   }
     } 
     else {
	   $base = $oid;	 
       $n = "$oid.1";
       $s = 1;
      }
      push @names,  $n;
      $vlist{ $n } = $v;
      $types{ $n } = OCTET_STRING;
   }
   $this->{_pdu}{_var_bind_list}  = \%vlist;
   $this->{_pdu}{_var_bind_names} = \@names;
   $this->{_pdu}{_var_bind_types} = \%types;

   return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 };
};

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

my $s = Device::ZyXEL::IES::Slot->new( id => 3, ies => $d );

my $p = Device::ZyXEL::IES::Port->new( id => 301, slot => $s );

my $list = $p->read_snoop_iplist();

ok ( scalar( keys( %{$list} ) ) == 2 );

ok( defined( $list->{'192.168.0.1'} && $list->{'192.168.0.1'} eq 'FE:DA:BE:33:44:55' ));
ok( defined( $list->{'192.168.0.2'} && $list->{'192.168.0.2'} eq 'FE:DA:BE:44:33:22' ));

