# MyTestHelpers.pm -- my shared test script helpers

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# MyTestHelpers.pm is shared by several distributions.
#
# MyTestHelpers.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyTestHelpers.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
package MyTestHelpers;
use strict;
use Exporter;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

# uncomment this to run the ### lines
#use Smart::Comments;

@ISA = ('Exporter');
@EXPORT_OK = qw(findrefs
                main_iterations
                warn_suppress_gtk_icon
                glib_gtk_versions
                any_signal_connections
                nowarnings);
%EXPORT_TAGS = (all => \@EXPORT_OK);

sub DEBUG { 0 }


#-----------------------------------------------------------------------------

{
  my $warning_count;
  my $stacktraces;
  my $stacktraces_count = 0;
  sub nowarnings_handler {
    my ($msg) = @_;
    # don't error out for cpan alpha version number warnings
    unless (defined $msg
            && $msg =~ /^Argument "[0-9._]+" isn't numeric in numeric gt/) {
      $warning_count++;
      if ($stacktraces_count < 3 && eval { require Devel::StackTrace }) {
        $stacktraces_count++;
        $stacktraces .= "\n" . Devel::StackTrace->new->as_string() . "\n";
      }
    }
    warn @_;
  }
  sub nowarnings {
    $SIG{'__WARN__'} = \&nowarnings_handler;
  }
  END {
    if ($warning_count) {
      MyTestHelpers::diag ("Saw $warning_count warning(s):");
      if (defined $stacktraces) {
        MyTestHelpers::diag ($stacktraces);
      } else {
        MyTestHelpers::diag('(Devel::StackTrace not available for backtrace)');
      }
      MyTestHelpers::diag ('Exit code 1 for warnings');
      $? = 1;
    }
  }
}

sub diag {
  if (do { local $@; eval { Test::More->can('diag') }}) {
    Test::More::diag (@_);
  } else {
    my $msg = join('', map {defined($_)?$_:'[undef]'} @_)."\n";
    $msg =~ s/^/# /mg;
    print STDERR $msg;
  }
}

sub dump {
  my ($thing) = @_;
  if (eval { require Data::Dumper; 1 }) {
    MyTestHelpers::diag (Data::Dumper::Dumper ($thing));
  } else {
    MyTestHelpers::diag ("Data::Dumper not available");
  }
}

#-----------------------------------------------------------------------------
# Test::Weaken and other weaking

sub findrefs {
  my ($obj) = @_;
  defined $obj or return;
  require Scalar::Util;
  if (ref $obj && Scalar::Util::reftype($obj) eq 'HASH') {
    MyTestHelpers::diag ("Keys: ",
                         join(' ',
                              map {"$_=".(defined $obj->{$_}
                                          ? "$obj->{$_}" : '[undef]')}
                              keys %$obj));
  }
  if (eval { require Devel::FindRef }) {
    MyTestHelpers::diag (Devel::FindRef::track($obj, 8));
  } else {
    MyTestHelpers::diag ("Devel::FindRef not available -- ", $@);
  }
}

sub test_weaken_show_leaks {
  my ($leaks) = @_;
  $leaks || return;

  my $unfreed = $leaks->unfreed_proberefs;
  my $unfreed_count = scalar(@$unfreed);
  MyTestHelpers::diag ("Test-Weaken leaks $unfreed_count objects");
  MyTestHelpers::dump ($leaks);

  my $proberef;
  foreach $proberef (@$unfreed) {
    MyTestHelpers::diag ("  unfreed ", $proberef);
  }
  foreach $proberef (@$unfreed) {
    MyTestHelpers::diag ("search ", $proberef);
    MyTestHelpers::findrefs($proberef);
  }
}

#-----------------------------------------------------------------------------
# Gtk/Glib helpers

# Gtk 2.16 can go into a hard loop on events_pending() / main_iteration_do()
# if dbus is not running, or something like that.  In any case limiting the
# iterations is good for test safety.
#
sub main_iterations {
  my $count = 0;
  if (DEBUG) { MyTestHelpers::diag ("main_iterations() ..."); }
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);

    if ($count >= 500) {
      MyTestHelpers::diag ("main_iterations(): oops, bailed out after $count events/iterations");
      return;
    }
  }
  MyTestHelpers::diag ("main_iterations(): ran $count events/iterations");
}

# warn_suppress_gtk_icon() is a $SIG{__WARN__} handler which suppresses spam
# from Gtk trying to make you buy the hi-colour icon theme.  Eg,
#
#     {
#       local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
#       $something = SomeThing->new;
#     }
#
sub warn_suppress_gtk_icon {
  my ($message) = @_;
  unless ($message =~ /Gtk-WARNING.*icon/
         || $message =~ /\Qrecently-used.xbel/
         ) {
    warn @_;
  }
}

sub glib_gtk_versions {
  my $gtk1_loaded = Gtk->can('init');
  my $gtk2_loaded = Gtk2->can('init');
  my $glib_loaded = Glib->can('get_home_dir');

  if ($gtk1_loaded) {
    MyTestHelpers::diag ("Perl-Gtk1    version ",Gtk->VERSION);
  }
  if ($gtk2_loaded) {
    MyTestHelpers::diag ("Perl-Gtk2    version ",Gtk2->VERSION);
  }
  if ($glib_loaded) { # when loaded
    MyTestHelpers::diag ("Perl-Glib    version ",Glib->VERSION);
    MyTestHelpers::diag ("Compiled against Glib version ",
                         Glib::MAJOR_VERSION(), ".",
                         Glib::MINOR_VERSION(), ".",
                         Glib::MICRO_VERSION(), ".");
    MyTestHelpers::diag ("Running on       Glib version ",
                         Glib::major_version(), ".",
                         Glib::minor_version(), ".",
                         Glib::micro_version(), ".");
  }
  if ($gtk2_loaded) {
    MyTestHelpers::diag ("Compiled against Gtk version ",
                         Gtk2::MAJOR_VERSION(), ".",
                         Gtk2::MINOR_VERSION(), ".",
                         Gtk2::MICRO_VERSION(), ".");
    MyTestHelpers::diag ("Running on       Gtk version ",
                         Gtk2::major_version(), ".",
                         Gtk2::minor_version(), ".",
                         Gtk2::micro_version(), ".");
  }
  if ($gtk1_loaded) {
    MyTestHelpers::diag ("Running on       Gtk version ",
                         Gtk->major_version(), ".",
                         Gtk->minor_version(), ".",
                         Gtk->micro_version(), ".");
  }
}

# Return true if there's any signal handlers connected to $obj.
#
# Signal IDs are from 1 up, don't pass 0 to signal_handler_is_connected()
# since in Glib 2.4.1 it spits out a g_log() error.
#
sub any_signal_connections {
  my ($obj) = @_;
  my @connected = grep {$obj->signal_handler_is_connected ($_)} (1 .. 500);
  if (@connected) {
    my $connected = join(',',@connected);
    MyTestHelpers::diag ("$obj signal handlers connected: $connected");
    return $connected;
  }
  return undef;
}

# wait for $signame to be emitted on $widget, with a timeout
sub wait_for_event {
  my ($widget, $signame) = @_;
  if (DEBUG) { MyTestHelpers::diag ("wait_for_event() $signame on ",$widget); }
  my $done = 0;
  my $got_event = 0;
  my $sig_id = $widget->signal_connect
    ($signame => sub {
       if (DEBUG) { MyTestHelpers::diag ("wait_for_event()   $signame received"); }
       $done = 1;
       return 0; # Gtk2::EVENT_PROPAGATE (new in Gtk2 1.220)
     });
  my $timer_id = Glib::Timeout->add
    (30_000, # 30 seconds
     sub {
       $done = 1;
       MyTestHelpers::diag ("wait_for_event() oops, timeout waiting for $signame on ",$widget);
       return 1; # Glib::SOURCE_CONTINUE (new in Glib 1.220)
     });
  if ($widget->can('get_display')) {
    # display new in Gtk 2.2
    $widget->get_display->sync;
  } else {
    # in Gtk 2.0 gdk_flush() is a sync actually
    Gtk2::Gdk->flush;
  }

  my $count = 0;
  while (! $done) {
    if (DEBUG >= 2) { MyTestHelpers::diag ("wait_for_event()   iteration $count"); }
    Gtk2->main_iteration;
    $count++;
  }
  MyTestHelpers::diag ("wait_for_event(): '$signame' ran $count events/iterations\n");

  $widget->signal_handler_disconnect ($sig_id);
  Glib::Source->remove ($timer_id);
}


#-----------------------------------------------------------------------------
# X11::Protocol helpers

sub X11_chosen_screen_number {
  my ($X) = @_;
  my $i;
  foreach $i (0 .. $#{$X->{'screens'}}) {
    if ($X->{'screens'}->[$i]->{'root'} == $X->{'root'}) {
      return $i;
    }
  }
  die "Oops, current screen not found";
}

sub X11_server_info {
  my ($X) = @_;
  MyTestHelpers::diag("");
  MyTestHelpers::diag("X server info");
  MyTestHelpers::diag("vendor: ",$X->{'vendor'});
  MyTestHelpers::diag("release_number: ",$X->{'release_number'});
  MyTestHelpers::diag("protocol_major_version: ",$X->{'protocol_major_version'});
  MyTestHelpers::diag("protocol_minor_version: ",$X->{'protocol_minor_version'});
  MyTestHelpers::diag("byte_order: ",$X->{'byte_order'});
  MyTestHelpers::diag("num screens: ",scalar(@{$X->{'screens'}}));
  MyTestHelpers::diag("width_in_pixels:  ",$X->{'width_in_pixels'});
  MyTestHelpers::diag("height_in_pixels: ",$X->{'height_in_pixels'});
  MyTestHelpers::diag("width_in_millimeters:  ",$X->{'width_in_millimeters'});
  MyTestHelpers::diag("height_in_millimeters: ",$X->{'height_in_millimeters'});

  MyTestHelpers::diag("root_visual: ",$X->{'root_visual'});
  my $visual_info = $X->{'visuals'}->{$X->{'root_visual'}};
  MyTestHelpers::diag("  depth: ",$visual_info->{'depth'});
  MyTestHelpers::diag("  class: ",$visual_info->{'class'},
                      ' ', $X->interp('VisualClass', $visual_info->{'class'}));
  MyTestHelpers::diag("  colormap_entries: ",$visual_info->{'colormap_entries'});
  MyTestHelpers::diag("  bits_per_rgb_value: ",$visual_info->{'bits_per_rgb_value'});
  MyTestHelpers::diag("  red_mask:   ",sprintf('%#X',$visual_info->{'red_mask'}));
  MyTestHelpers::diag("  green_mask: ",sprintf('%#X',$visual_info->{'green_mask'}));
  MyTestHelpers::diag("  blue_mask:  ",sprintf('%#X',$visual_info->{'blue_mask'}));

  MyTestHelpers::diag("ima"."ge_byte_order: ",$X->{'ima'.'ge_byte_order'},
                      ' ', $X->interp('Significance', $X->{'ima'.'ge_byte_order'}));
  MyTestHelpers::diag("black_pixel: ",sprintf('%#X',$X->{'black_pixel'}));
  MyTestHelpers::diag("white_pixel: ",sprintf('%#X',$X->{'white_pixel'}));
  foreach  (0 .. $#{$X->{'screens'}}) {
    if ($X->{'screens'}->[$_]->{'root'} == $X->{'root'}) {
      MyTestHelpers::diag("chosen screen: $_");
    }
  }
  MyTestHelpers::diag("");
}

  1;
__END__
