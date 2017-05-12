package GStreamer;

# $Id$

use 5.008;
use strict;
use warnings;

use Glib;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(
  GST_SECOND
  GST_MSECOND
  GST_USECOND
  GST_NSECOND
  GST_TIME_FORMAT
  GST_TIME_ARGS
  GST_RANK_NONE
  GST_RANK_MARGINAL
  GST_RANK_SECONDARY
  GST_RANK_PRIMARY
);

# --------------------------------------------------------------------------- #

our $VERSION = '0.20';

sub import {
  my ($self) = @_;
  my @symbols = ();

  foreach (@_) {
    if (/^-?init$/) {
      $self -> init();
    } else {
      push @symbols, $_;
    }
  }

  GStreamer -> export_to_level(1, @symbols);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

GStreamer -> bootstrap($VERSION);

# --------------------------------------------------------------------------- #

use constant GST_SECOND => 1_000_000 * 1_000;
use constant GST_MSECOND => GST_SECOND / 1_000;
use constant GST_USECOND => GST_SECOND / 1_000_000;
use constant GST_NSECOND => GST_SECOND / 1_000_000_000;

use constant GST_TIME_FORMAT => "u:%02u:%02u.%09u";

sub GST_TIME_ARGS {
  my ($t) = @_;

  return (
    ($t / (GST_SECOND * 60 * 60)),
    ($t / (GST_SECOND * 60)) % 60,
    ($t / GST_SECOND) % 60,
    ($t % GST_SECOND)
  );
}

use constant GST_RANK_NONE => 0;
use constant GST_RANK_MARGINAL => 64;
use constant GST_RANK_SECONDARY => 128;
use constant GST_RANK_PRIMARY => 256;

# --------------------------------------------------------------------------- #

package GStreamer::Caps;

use overload
  '+' => \&__append,
  '-' => \&__subtract,
  '&' => \&__intersect,
  '|' => \&__union,
  '<=' => \&__is_subset,
  '>=' => \&__is_superset,
  '==' => \&__is_equal,
  '""' => \&__to_string,
  fallback => 1;

sub __append {
  my ($a, $b, $swap) = @_;
  my $tmp = GStreamer::Caps::Empty -> new();

  unless ($swap) {
    $tmp -> append($a);
    $tmp -> append($b);
  } else {
    $tmp -> append($b);
    $tmp -> append($a);
  }

  return $tmp;
}

sub __subtract {
  my ($a, $b, $swap) = @_;

  return $swap ?
    $b -> subtract($a) :
    $a -> subtract($b);
}

sub __intersect {
  my ($a, $b, $swap) = @_;

  return $swap ?
    $b -> intersect($a) :
    $a -> intersect($b);
}

sub __union {
  my ($a, $b, $swap) = @_;

  return $swap ?
    $b -> union($a) :
    $a -> union($b);
}

sub __is_subset {
  my ($a, $b, $swap) = @_;

  return $swap ?
    $b -> is_subset($a) :
    $a -> is_subset($b);
}

sub __is_superset {
  my ($a, $b, $swap) = @_;

  return $swap ?
    $a -> is_subset($b) :
    $b -> is_subset($a);
}

sub __is_equal {
  my ($a, $b, $swap) = @_;

  return $swap ?
    $b -> is_equal($a) :
    $a -> is_equal($b);
}

sub __to_string {
  my ($a) = @_;

  return $a -> to_string();
}

# --------------------------------------------------------------------------- #

package GStreamer;

1;

__END__

=head1 NAME

GStreamer - Perl interface to version 0.10.x of the GStreamer library

=head1 SYNOPSIS

  use GStreamer -init;

  my $loop = Glib::MainLoop -> new();

  # set up
  my $play = GStreamer::ElementFactory -> make("playbin", "play");
  $play -> set(uri => Glib::filename_to_uri $file, "localhost");
  $play -> get_bus() -> add_watch(\&my_bus_callback, $loop);
  $play -> set_state("playing");

  # run
  $loop -> run();

  # clean up
  $play -> set_state("null");

  sub my_bus_callback {
    my ($bus, $message, $loop) = @_;

    if ($message -> type & "error") {
      warn $message -> error;
      $loop -> quit();
    }

    elsif ($message -> type & "eos") {
      $loop -> quit();
    }

    # remove message from the queue
    return TRUE;
  }


=head1 ABSTRACT

B<NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE>

This module only works with the 0.10.x series of the GStreamer C libraries.
There is another Perl module, L<GStreamer1>, that is intended for the 1.x
series of the GStreamer C libraries.  L<GStreamer1> is located at
L<https://metacpan.org/pod/GStreamer1>.

The two C libraries, as well as their associated Perl modules, can be installed
concurrently on the same host.

See the POD for L<GStreamer1> (L<https://metacpan.org/pod/GStreamer1>) for
more information about that module.

B<NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE>

GStreamer makes everybody dance like crazy.  It provides the means to play,
stream, and convert nearly any type of media -- be it audio or video.
GStreamer wraps version 0.10.x of the GStreamer C libraries in a nice and
Perlish way, freeing the programmer from any memory management and object
casting hassles.

=head1 INITIALIZATION

=over

=item B<GStreamer-E<gt>init>

Initializes GStreamer.  Automatically parses I<@ARGV>, stripping any options
known to GStreamer.

=item B<boolean = GStreamer-E<gt>init_check>

Checks if initialization is possible.  Returns TRUE if so.

=back

When importing GStreamer, you can pass the C<-init> option to have
I<GStreamer-E<gt>init> automatically called for you.  If you need to know if
initialization is possible without actually doing it, use
I<GStreamer-E<gt>init_check>.

=head1 VERSION CHECKING

=over

=item B<boolean = GStreamer-E<gt>CHECK_VERSION (major, minor, micro)>

=over

=item * major (integer)

=item * minor (integer)

=item * micro (integer)

=back

Returns TRUE if the GStreamer library version GStreamer was compiled against is
newer than the one specified by the three arguments.

=item B<(major, minor, micro) = GStreamer-E<gt>GET_VERSION_INFO>

Returns the version information of the GStreamer library GStreamer was compiled
against.

=item B<(major, minor, micro) = GStreamer-E<gt>version>

Returns the version information of the GStreamer library GStreamer is currently
running against.

=back

=head1 SEE ALSO

=over

=item L<GStreamer::index>

Lists the automatically generated API documentation pages.

=item L<http://gstreamer.freedesktop.org/>

GStreamer's website has much useful information, including a good tutorial and
of course the API reference, which is canonical for GStreamer as well.

=item L<Gtk2::api>

Just like Gtk2, GStreamer tries to stick closely to the C API, deviating from
it only when it makes things easier and/or more Perlish.  L<Gtk2::api> gives
general rules for how to map from the C API to Perl, most of which also apply
to GStreamer.

=item L<Glib>

Glib is the foundation this binding is built upon.  If you look for information
on basic stuff like signals or object properties, this is what you should read.

=item L<GStreamer1>

Perl bindings for version 1.x of the GStreamer C libraries.  The two C
libraries, as well as their associated Perl modules, can be installed
concurrently on the same host.


=back

=head1 AUTHORS

=over

=item Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=item Brett Kosinski E<lt>brettk at frodo.dyn.gno dot orgE<gt>

=back

=head1 COPYRIGHT

Copyright (C) 2005-2011, 2013 by the gtk2-perl team

=cut
