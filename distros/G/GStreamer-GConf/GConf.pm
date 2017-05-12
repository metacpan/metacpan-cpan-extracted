package GStreamer::GConf;

# $Id: GConf.pm,v 1.1 2005/08/13 17:22:58 kaffeetisch Exp $

use strict;
use warnings;

use GStreamer;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.01';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

GStreamer::GConf -> bootstrap($VERSION);

1;

# --------------------------------------------------------------------------- #

__END__

=head1 NAME

GStreamer::GConf - Perl interface to the GStreamer GConf library

=head1 SYNOPSIS

  use GStreamer -init;
  use GStreamer::GConf;

  # build pipeline
  my $pipeline = GStreamer::Pipeline -> new("pipeline");

  my $sink = GStreamer::GConf -> get_default_audio_sink();
  my ($source, $spider, $conv, $scale) =
    GStreamer::ElementFactory -> make(filesrc => "source",
                                      spider => "spider",
                                      audioconvert => "conv",
                                      audioscale => "scale");


  $source -> set(location => $ARGV[0]);

  $pipeline -> add($source, $spider, $conv, $scale, $sink);
  $source -> link($spider, $conv, $scale, $sink) or die "Could not link";

  # play
  $pipeline -> set_state("playing") or die "Could not start playing";
  while ($pipeline -> iterate()) { };

  # clean up
  $pipeline -> set_state("null");

=head1 ABSTRACT

GStreamer::GConf provides access to the GConf interaction facilities of the
GStreamer library.

=head1 METHODS

=over

=item $value = GStreamer::GConf->get_string ($key)

=item GStreamer::GConf->set_string ($key, $value)

=item $element = GStreamer::GConf->render_bin_from_key ($key)

=item $element = GStreamer::GConf->render_bin_from_description ($description)

=item $element = GStreamer::GConf->get_default_video_sink

=item $element = GStreamer::GConf->get_default_audio_sink

=item $element = GStreamer::GConf->get_default_video_src

=item $element = GStreamer::GConf->get_default_audio_src

=item $element = GStreamer::GConf->get_default_visualization_element

=back

=head1 AUTHOR

=over

=item Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=back

=head1 COPYRIGHT

Copyright (C) 2005 by the gtk2-perl team

=cut
