package GStreamer::Interfaces;

use strict;
use warnings;

use GStreamer;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.06';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

GStreamer::Interfaces -> bootstrap($VERSION);

1;

# --------------------------------------------------------------------------- #

__END__

=head1 NAME

GStreamer::Interfaces - Perl interface to the GStreamer Interfaces library

=head1 SYNOPSIS

  use GStreamer::Interfaces;

  # GStreamer::PropertyProbe

  my $sink = GStreamer::ElementFactory -> make(alsasink => "sink");
  my $pspec = $sink -> get_probe_property("device");

  if ($sink -> needs_probe($pspec)) {
    $sink -> probe_property($pspec);
  }

  my @devices = $sink -> get_probe_values($pspec);

  # GStreamer::XOverlay

  my $overlay = GStreamer::ElementFactory -> make(xvimagesink => "overlay");
  $overlay -> set_xwindow_id($xid);

=head1 ABSTRACT

GStreamer::Interfaces provides access to some of the interfaces in the
GStreamer Interfaces library.  Currently, that's L<GStreamer::PropertyProbe>
and L<GStreamer::XOverlay>.

=head1 INTERFACES

=head2 GStreamer::PropertyProbe

=over

=item pspecs = $element->get_probe_properties

=item pspec = $element->get_probe_property (name)

=item bool = $element->needs_probe (pspec)

=item $element->probe_property (pspec)

=item values = $element->get_probe_values (pspec)

=item values = $element->probe_get_probe_values (pspec)

=item bool = $element->needs_probe_name (name)

=item $element->probe_property_name (name)

=item values = $element->get_probe_values_name (name)

=item values = $element->probe_get_probe_values_name (name)

=back

=head2 GStreamer::XOverlay

=over

=item $overlay->set_xwindow_id (xwindow_id)

=item $overlay->expose

=item $overlay->got_xwindow_id (xwindow_id)

=item $overlay->prepare_xwindow_id

=item $overlay->handle_events (bool) (since 0.10.12)

=back

=head1 AUTHOR

=over

=item Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=back

=head1 COPYRIGHT

Copyright (C) 2005-2010 by the gtk2-perl team

=cut
