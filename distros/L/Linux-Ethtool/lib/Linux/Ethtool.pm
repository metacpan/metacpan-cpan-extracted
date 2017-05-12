=head1 NAME

Linux::Ethtool - Interface to the Linux SIOCETHTOOL ioctl

=head1 SYNOPSIS

  use Linux::Ethtool qw(:all);
  
  my $link    = get_link("eth0")    // die($!);
  my $rx_csum = get_rx_csum("eth0") // die($!);
  my $tx_csum = get_tx_csum("eth0") // die($!);
  
  print "Link detected:          ".($link ? "yes" : "no")."\n";
  print "RX checksum offloading: ".($rx_csum ? "yes" : "no")."\n";
  print "TX checksum offloading: ".($tx_csum ? "yes" : "no")."\n";

=head1 DESCRIPTION

This module provides a procedural interface to the basic operations provided by
the Linux SIOCETHTOOL ioctl. The more complex operations that involve getting or
setting whole structures at a time are implemented in OO fashion by packages
under this namespace.

=head1 SUBROUTINES

=cut

package Linux::Ethtool;

use strict;
use warnings;

our $VERSION = "0.11";

require XSLoader;
XSLoader::load("Linux::Ethtool");

use Exporter qw(import);

our @EXPORT_OK = qw(
	get_link
	get_rx_csum
	set_rx_csum
	get_tx_csum
	set_tx_csum
	get_sg
	set_sg
	get_tso
	set_tso
	get_ufo
	set_ufo
	get_gso
	set_gso
	get_gro
	set_gro
);

our %EXPORT_TAGS = (
	all => [ @EXPORT_OK ]
);

=pod

The following subroutines get or set boolean values on a network interface.

The get functions return defined true/false on success, undef on failure.

The set functions return true on success, false on failure.

  get_link($dev) - Link detected
  
  get_rx_csum($dev), set_rx_csum($dev, $enable) - RX checksum offloading enabled
  get_tx_csum($dev), set_tx_csum($dev, $enable) - TX checksum offloading enabled
  get_sg($dev),      set_sg($dev, $enable)      - Scatter gather enabled
  get_tso($dev),     set_tso($dev, $enable)     - TCP Segmentation Offload enabled
  get_ufo($dev),     set_ufo($dev, $enable)     - UDP Fragmentation Offload enabled
  get_gso($dev),     set_gso($dev, $enable)     - Generic Segmentation Offload enabled
  get_gro($dev),     set_gro($dev, $enable)     - Generic Receive Offload enabled

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Daniel Collins E<lt>solemnwarning@solemnwarning.netE<gt>

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Linux::Ethtool::Settings>, L<Linux::Ethtool::WOL>

=cut

1;
