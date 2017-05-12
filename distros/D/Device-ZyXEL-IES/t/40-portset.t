use strict;
use warnings;
use Test::More tests => 16;

use Net::SNMP qw(:asn1);
use Device::ZyXEL::IES;
use Data::Dumper;

my $d = Device::ZyXEL::IES->new(
  hostname => 'localhost',  
  get_community => 'public', 
  set_community => 'public_set');

isa_ok( $d,   'Device::ZyXEL::IES' );

my $s = Device::ZyXEL::IES::Slot->new(
  id => 3, ies => $d);

isa_ok( $s, 'Device::ZyXEL::IES::Slot' );

my $p = Device::ZyXEL::IES::Port->new(
  id => 301, slot => $s );

isa_ok( $p, 'Device::ZyXEL::IES::Port' );


my $TESTOID;
my $TESTVALUE;
my $TESTCARDTYPE;

# Hooking for test ============================================================
# hook allows snmpget from Net::SNMP::Util
{
 no warnings;

 *{Net::SNMP::_send_pdu} = sub {
    my ( $this ) = @_;
	my $varbindlist = $this->var_bind_list();
	foreach my $oid ( keys %{$varbindlist}) {
	  if ( $oid =~ /\.1\.3\.6\.1\.4\.1\.890\.1\.5\.13\.5\.6\.3\.1\.3\.0\./ ) {
		# a read of cardtype.
		$this->{_pdu}{_var_bind_list}{ $oid } = $TESTCARDTYPE;
	  }
	  else {
		# assume set of some port value
	    ok ( defined( $varbindlist->{$TESTOID} ) && $varbindlist->{$TESTOID} eq $TESTVALUE );
	  }
    }
	return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
 }

};

($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.2.1.2.2.1.7.301', '2' );

# will fire a snmp set of adminstatus oid
my $pdr = $p->write_adminstatus(2);

$TESTVALUE = '1';
$pdr = $p->write_adminstatus(1);

## now test profiles.

# prepare to set the profile
$TESTCARDTYPE = 'ALC1248G-51'; # ADSL mode
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.2.1.10.94.1.1.1.1.4.301', '10240d1024u' );

# Should read cardtype automatically via trigger
$pdr = $p->write_profile( '10240d1024u' );

$TESTCARDTYPE = 'VLC1348G-51'; # VDSL mode
$s->read_cardtype(); # to make the slot change type
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.2.1.10.97.1.1.1.1.3.301', '20240d1024u' );

# Should read cardtype automatically via trigger
$pdr = $p->write_profile( '20240d1024u' );

$TESTCARDTYPE = 'SLC1348G-51'; # VDSL mode
$s->read_cardtype(); # to make the slot change type
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.2.1.10.48.1.1.1.2.301', '1024' );

# Should read cardtype automatically via trigger
$pdr = $p->write_profile( '1024' );


## now try INP

$TESTCARDTYPE = 'ALC1248G-51'; # ADSL mode
$s->read_cardtype(); # to make the slot change type
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.15.301', '4' );
$pdr = $p->write_inpdown( '4' );
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.14.301', '6' );
$pdr = $p->write_inpup( '6' );


# try a wrong value - he validity of this test is that it 
# does not add one to the testplan, cause it does no SNMP
# it still sets the inp_down attribute to 9 though
$pdr = $p->write_inpdown( '9' );
ok ( $p->inp_down == 4 );

$TESTCARDTYPE = 'VLC1348G-51'; # ADSL mode
$s->read_cardtype(); # to make the slot change type
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.6.301', '40' );
$pdr = $p->write_inpdown( '40' );

($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.7.301', '60' );
$pdr = $p->write_inpup( '60' );

($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.1.3.1.1.2.301', '5' );
$pdr = $p->write_maxmac( '5' );

# Annex M
$TESTCARDTYPE = 'ALC1248G-51'; # ADSL mode
$s->read_cardtype(); # to make the slot change type
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.3.301', '2' );
$pdr = $p->write_annexM( '2' );

# AnnexL
($TESTOID, $TESTVALUE)  = ( '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.2.301', '3' );
$pdr = $p->write_annexL( '3' );
