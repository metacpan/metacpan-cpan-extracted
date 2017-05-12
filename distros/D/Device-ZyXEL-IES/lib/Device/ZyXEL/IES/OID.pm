package Device::ZyXEL::IES::OID;

use SNMP;
use Capture::Tiny qw/capture/;

=head1 NAME

Device::ZyXEL::IES::OID - Translate names to OIDs for all the OID's used by Device::ZyXEL::IES::*

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Just a method to translate a name to an OID.
 
my $n = Device::ZyXEL::IES::OID->new;

my $oid = $n->translate("ZYXEL-IES5000-MIB::macFilterPortMacCount");
  
=cut

# private map to use when MIB file lookup fails for any reason.
my %oid_map = (
  'IF-MIB::ifOperStatus' => '.1.3.6.1.2.1.2.2.1.8',
  'IF-MIB::ifAdminStatus' => '.1.3.6.1.2.1.2.2.1.7',
  'IF-MIB::ifHCInOctets' => '.1.3.6.1.2.1.31.1.1.1.6',
  'IF-MIB::ifHCOutOctets' => '.1.3.6.1.2.1.31.1.1.1.10',
  'IF-MIB::ifLastChange' => '.1.3.6.1.2.1.2.2.1.9',

  'DISMAN-EVENT-MIB::sysUpTimeInstance' => '.1.3.6.1.2.1.1.3.0',
  'SNMPv2-MIB::sysDescr.0' => '.1.3.6.1.2.1.1.1.0',

  'ADSL-LINE-MIB::adslLineConfProfile' => '.1.3.6.1.2.1.10.94.1.1.1.1.4',
  'ADSL-LINE-MIB::adslAtucCurrAttainableRate' => '.1.3.6.1.2.1.10.94.1.1.2.1.8',
  'ADSL-LINE-MIB::adslAturCurrAttainableRate' => '.1.3.6.1.2.1.10.94.1.1.3.1.8',
  'ADSL-LINE-MIB::adslAtucChanCurrTxRate' => '.1.3.6.1.2.1.10.94.1.1.4.1.2',
  'ADSL-LINE-MIB::adslAturChanCurrTxRate' => '.1.3.6.1.2.1.10.94.1.1.5.1.2',
  'ADSL-LINE-MIB::adslAturCurrSnrMgn' => '.1.3.6.1.2.1.10.94.1.1.3.1.4',
  'ADSL-LINE-MIB::adslAtucCurrSnrMgn' => '.1.3.6.1.2.1.10.94.1.1.2.1.4',
  'ADSL-LINE-MIB::adslAturCurrAtn' => '.1.3.6.1.2.1.10.94.1.1.3.1.5',
  'ADSL-LINE-MIB::adslAtucCurrAtn' => '.1.3.6.1.2.1.10.94.1.1.2.1.5',
  'ADSL-LINE-MIB::adslAtucChanIntervalUncorrectBlks' => '.1.3.6.1.2.1.10.94.1.1.12.1.5',
  'ADSL-LINE-MIB::adslAturChanIntervalUncorrectBlks' => '.1.3.6.1.2.1.10.94.1.1.13.1.5',
  'ADSL-LINE-MIB::adslAtucIntervalESs' => '.1.3.6.1.2.1.10.94.1.1.8.1.6',
  'ADSL-LINE-MIB::adslAturIntervalESs' => '.1.3.6.1.2.1.10.94.1.1.9.1.5',

  'VDSL-LINE-MIB::vdslLineConfProfile' => '.1.3.6.1.2.1.10.97.1.1.1.1.3',
  'VDSL-LINE-MIB::vdslPhysCurrAttainableRate' => '.1.3.6.1.2.1.10.97.1.1.2.1.9',
  'VDSL-LINE-MIB::vdslPhysCurrLineRate' => '.1.3.6.1.2.1.10.97.1.1.2.1.10',
  'VDSL-LINE-MIB::vdslPhysCurrSnrMgn' => '.1.3.6.1.2.1.10.97.1.1.2.1.5',
  'VDSL-LINE-MIB::vdslPhysCurrAtn' => '.1.3.6.1.2.1.10.97.1.1.2.1.6',
  'VDSL-LINE-MIB::vdslChanIntervalBadBlks' => '.1.3.6.1.2.1.10.97.1.1.8.1.3', # <port>.1.x => Vtuc, <port>.2.x => Vtur
  'VDSL-LINE-MIB::vdslPerfIntervalESs' => '.1.3.6.1.2.1.10.97.1.1.5.1.6', # <port>.1.x => Vtuc, <port>.2.x => Vtur

  'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslSpanConfProfile' => '.1.3.6.1.2.1.10.48.1.1.1.2',
  'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslStatusActualLineRate' => '.1.3.6.1.2.1.10.48.1.2.1.3',
  'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrSnrMgn' => '.1.3.6.1.2.1.10.48.1.5.1.2',
  'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrAtn' => '.1.3.6.1.2.1.10.48.1.5.1.1',
  'ZYXEL-IES5000-MIB::seltTarget.0' => '.1.3.6.1.4.1.890.1.5.13.5.4.3.1.0',
  'ZYXEL-IES5000-MIB::seltOps.0' => '.1.3.6.1.4.1.890.1.5.13.5.4.3.2.0',
  'ZYXEL-IES5000-MIB::seltStatus.0' => '.1.3.6.1.4.1.890.1.5.13.5.4.3.3.0',
  'ZYXEL-IES5000-MIB::seltCableType.0' => '.1.3.6.1.4.1.890.1.5.13.5.4.3.4.0',
  'ZYXEL-IES5000-MIB::seltLoopEstimateLengthFt.0' => '.1.3.6.1.4.1.890.1.5.13.5.4.3.5.0',
  'ZYXEL-IES5000-MIB::seltLoopEstimateLengthMeter.0' => '.1.3.6.1.4.1.890.1.5.13.5.4.3.6.0',
  'ZYXEL-IES5000-MIB::macFilterPortMacCount' => '.1.3.6.1.4.1.890.1.5.13.5.1.3.1.1.2',
  'ZYXEL-IES5000-MIB::dhcpDiscovery' => '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.1',
  'ZYXEL-IES5000-MIB::dhcpOffer' => '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.2',
  'ZYXEL-IES5000-MIB::dhcpRequest' => '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.3',
  'ZYXEL-IES5000-MIB::dhcpAck' => '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.4',
  'ZYXEL-IES5000-MIB::dhcpAckBySnoopFull' => '.1.3.6.1.4.1.890.1.5.13.5.13.1.2.1.5',
  'ZYXEL-IES5000-MIB::subrPortName' => '.1.3.6.1.4.1.890.1.5.13.5.8.1.1.1',
  'ZYXEL-IES5000-MIB::slotModuleFWVersion.0' => '.1.3.6.1.4.1.890.1.5.13.5.6.3.1.4.0',
  'ZYXEL-IES5000-MIB::slotModuleDescr.0' => '.1.3.6.1.4.1.890.1.5.13.5.6.3.1.3.0',
  'ZYXEL-IES5000-MIB::dhcpSnoopMac' => '.1.3.6.1.4.1.890.1.5.13.5.13.1.1.1.2',

  'ZYXEL-IES5000-MIB::adslLineStatsAtucQln1' => '.1.3.6.1.4.1.890.1.5.13.5.13.4.3.1.4',
  'ZYXEL-IES5000-MIB::adslLineStatsAtucQln2' => '.1.3.6.1.4.1.890.1.5.13.5.13.4.3.1.5',
  'ZYXEL-IES5000-MIB::adslLineStatusUpTime' => '.1.3.6.1.4.1.890.1.5.13.5.8.2.4.1.2',
  'ZYXEL-IES5000-MIB::adslLineConfAtucInp' => '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.15',
  'ZYXEL-IES5000-MIB::adslLineConfAturInp' => '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.14',
  'ZYXEL-IES5000-MIB::adslLineConfAnnexM' => '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.3',
  'ZYXEL-IES5000-MIB::adslLineConfAnnexL' => '.1.3.6.1.4.1.890.1.5.13.5.8.2.1.1.2',
  'ZYXEL-IES5000-MIB::adslLineStatsAturHlog' => '.1.3.6.1.4.1.890.1.5.13.5.13.4.3.1.3',
  'ZYXEL-IES5000-MIB::adslLineStatsAtucHlog1' => '.1.3.6.1.4.1.890.1.5.13.5.13.4.3.1.1',
  'ZYXEL-IES5000-MIB::adslLineStatsAtucHlog2' => '.1.3.6.1.4.1.890.1.5.13.5.13.4.3.1.2',
  'ZYXEL-IES5000-MIB::adslLineStatsAturQln' => '.1.3.6.1.4.1.890.1.5.13.5.13.4.3.1.6',

  'ZYXEL-IES5000-MIB::vdslLineStatsVtucSnr' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.29',
  'ZYXEL-IES5000-MIB::vdslLineStatsVtucSnrGroupSize' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.40',
  'ZYXEL-IES5000-MIB::vdslLineStatsVturSnr' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.30',
  'ZYXEL-IES5000-MIB::vdslLineStatsVturSnrGroupSize' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.41',
  'ZYXEL-IES5000-MIB::vdslLineConfVturInp' => '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.6',
  'ZYXEL-IES5000-MIB::vdslLineConfVtucInp' => '.1.3.6.1.4.1.890.1.5.13.5.8.10.1.1.7',
  'ZYXEL-IES5000-MIB::vdslLineStatsProtocol' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.33',
  'ZYXEL-IES5000-MIB::vdslLineStatsVturHlog' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.26',
  'ZYXEL-IES5000-MIB::vdslLineStatsVturHlogGroupSize' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.37',
  'ZYXEL-IES5000-MIB::vdslLineStatsVtucHlog' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.25',
  'ZYXEL-IES5000-MIB::vdslLineStatsVtucHlogGroupSize' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.36',
  'ZYXEL-IES5000-MIB::vdslLineStatsVturQln' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.28',
  'ZYXEL-IES5000-MIB::vdslLineStatsVturQlnGroupSize' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.39',
  'ZYXEL-IES5000-MIB::vdslLineStatsVtucQln' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.27',
  'ZYXEL-IES5000-MIB::vdslLineStatsVtucQlnGroupSize' => '.1.3.6.1.4.1.890.1.5.13.5.13.8.2.1.38',

  'ZYXEL-IES5000-MIB::shdslLineStatusWirePair' => '.1.3.6.1.4.1.890.1.5.13.5.8.3.3.1.1',
);

# assume mibs are installed and loaded.
our $mib_loaded = 1;

=head2 new
 
 Just calls SNMP::initMib() to read the mib files of the system.

=cut
sub new {
  my $class = shift;
  SNMP::initMib();
  return bless {}, $class;
}


sub translate {
  my ($self,$name,$postfix) = @_;
  my $oid;
  if ( $mib_loaded ) {
    my ($stdout,$stderr) = capture {
      $oid = SNMP::translateObj($name);
    };
    $mib_loaded = 0 if $stderr ne '';
  }
  if ( !defined( $oid ) && defined( $oid_map{$name} ) ) {
    $oid = $oid_map{$name};
  }
  if ( defined( $oid ) && defined( $postfix ) && $postfix ne '' ) {
    $oid = $oid . '.' . $postfix;
  }
  return $oid;
}

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::ZyXEL::IES::OID

		  You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-ZyXEL-IES>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-ZyXEL-IES>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-ZyXEL-IES>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-ZyXEL-IES/>

=back


=head1 ACKNOWLEDGEMENTS

Fullrate (http://www.fullrate.dk) 

  Thanks for allowing me to be introduced to the "wonderful" device ;)
  And thanks for donating some of my work time to create this module and 
  sharing it with the world.
			
=head1 COPYRIGHT & LICENSE
			
  Copyright 2012 Jesper Dalberg,   all rights reserved.
			
  This program is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut

1;