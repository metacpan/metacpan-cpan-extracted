package GStreamer::GConf;

# $Id$

use strict;
use warnings;

use GStreamer;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.02';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

GStreamer::GConf -> bootstrap($VERSION);

1;

# --------------------------------------------------------------------------- #

__END__

=head1 NAME

GStreamer::GConf - (DEPRECATED) Perl interface to the GStreamer GConf library

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

B<DEPRECATED> GStreamer::GConf provides access to the GConf interaction
facilities of the GStreamer library.

=head1 DESCRIPTION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gstreamer-gconf

=item *

Upstream URL: None

=item *

Last upstream version: N/A

=item *

Last upstream release date: N/A

=item *

Migration path for this module: no upstream replacement

=back

B<Note>: I<GStreamer::GConf> is neither necessary for nor does it work with the
0.10 series of the GStreamer library.  In 0.10 and above, simply use these
elements: gconfvideosink, gconfvideosrc, gconfaudiosink, gconfaudiosrc.

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
