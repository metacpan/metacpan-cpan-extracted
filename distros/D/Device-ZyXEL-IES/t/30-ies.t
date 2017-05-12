#!perl -T

use strict;
use warnings;
use Test::More tests => 2;
use Net::SNMP qw(:asn1);
use Data::Dumper;

# the test subject ;)
use Device::ZyXEL::IES;

# Hooking for test ============================================================
# Taken from Net::SNMP::Util
{
 no warnings;

*{Net::SNMP::_send_pdu} = sub {
   my ( $this ) = @_;
   foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
	  if ( $oid =~ /^.*\.1\.0$/ ) {
         $this->{_pdu}{_var_bind_list}{ $oid } = "IES-5005";
	  } 
	  else {
         $this->{_pdu}{_var_bind_list}{ $oid } = 17000;
	  }
   }
					   
   return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
}

};

my ($d);

undef $d;
$d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public');

my $dfr = $d->fetchDetails();

ok( $d->uptime() == 17000 );
ok( $d->sysdescr() eq 'IES-5005' );

