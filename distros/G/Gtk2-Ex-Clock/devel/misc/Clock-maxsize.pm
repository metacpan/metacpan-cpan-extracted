# Gtk2::Ex::Clock widget.

# Copyright 2007, 2009, 2011, 2019 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.



# Umm, forget what this was.  Another way to work out the max size of the
# label was it?



package Gtk2::Ex::Clock;
use strict;
use warnings;
use POSIX qw(tzset sysconf _SC_CLK_TCK);
use Time::HiRes;

use Gtk2;

our $VERSION = 1;

use constant {
  DEFAULT_FORMAT     => '%H:%M',
  DEFAULT_TIMEZONE   => '',
  DEFAULT_USE_MARKUP => 1,

  # not wrapped in Gtk2 version 1.140
  GDK_PRIORITY_REDRAW => (Glib::G_PRIORITY_HIGH_IDLE + 20),

  # set this to 1 for some diagnostic prints
  DEBUG => 1
};

use Glib::Object::Subclass
  Gtk2::Label::,
  properties => [Glib::ParamSpec ->string
                 ('format',
                  'format',
                  'An strftime() format string to display the time.',
                  DEFAULT_FORMAT,
                  Glib::G_PARAM_READWRITE),
                 Glib::ParamSpec->string
                 ('timezone',
                  'timezone',
                  'The timezone to use for the display, as taken by the TZ environment variable, or empty for local time.',
                  DEFAULT_TIMEZONE,
                  Glib::G_PARAM_READWRITE),
                 Glib::ParamSpec->int
                 ('resolution',
                  'resolution',
                  'The resolution of the clock, in seconds, or 0 to decide this from the format string.',
                  0, 3600, 0,
                  Glib::G_PARAM_READWRITE)
                 ];

# $timer_margin is an extra period in milliseconds to add to the timer
# period requested.  It's designed to ensure we don't wake up before the
# target time boundary (1 second or 1 minute) if g_timeout_add ends up
# rounding to a clock tick boundary.
#
# In the unlikely event there's no CLK_TCK defined, assume the traditional
# 100 ticks/second, ie. a resolution of 10 milliseconds (giving a 20 ms
# margin).
#
my $timer_margin
  = 2 * (1000.0 / (sysconf(_SC_CLK_TCK) || 100));
if (DEBUG) { print "timer margin $timer_margin milliseconds\n"; }

# $format is an strftime() format string.  Return true if it has 1 second
# resolution.
#
sub strftime_is_seconds {
  my ($format) = @_;
  # %c - ctime() style, includes seconds
  # %r - is "%I:%M:%S %p"
  # %s - seconds since 1970
  # %S - seconds 0 to 59
  # %T - is "%H:%M:%S"
  # %X - is locale preferred time, probably "%H:%M:%S"
  # modifiers standard E and O, plus glibc "-_0^"
  return ($format =~ /%[-_^0-9EO]*[crsSTX]/);
}

# $tz is a string setting for the TZ environment variable, or undef.
# $subr is a code reference.
# Call $subr with TZ set to $tz, or if $tz is the empty string or undef
# then just call $subr with no change to TZ.  There's no return value.
#
sub call_with_timezone {
  my ($tz, $subr) = @_;
  my $old_tz = $ENV{'TZ'};

  # if timezone undef, or if it's the same as the current zone, then avoid
  # munging %ENV and the slowness of tzset()
  if (! defined $tz
      || $tz eq ''
      || (defined $old_tz && $tz eq $old_tz)) {
    &$subr();
  } else {
    $ENV{'TZ'} = $tz;
    tzset();
    &$subr();
    if (defined $old_tz) {
      $ENV{'TZ'} = $old_tz;
    } else {
      delete $ENV{'TZ'};
    }
    tzset();
  }
}

sub timer_callback {
  my ($self) = @_;
  if (DEBUG) { print "timer callback $self\n"; }

  my $tod = Time::HiRes::gettimeofday();
  my $format   = $self->get('format')   || DEFAULT_FORMAT;
  my $timezone = $self->get('timezone') || DEFAULT_TIMEZONE;
  my $str;
  call_with_timezone
    ($timezone,
     sub { my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
             = localtime ($tod);
           $str = POSIX::strftime
             ($format,$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
     });
  $self->set('label',$str);

  # Decide how long, in milliseconds, from $tod to the next multiple of
  # $self->{'timer_resolution'} seconds, ie. to either the next 1 second or
  # 1 minute boundary.  Plus the $timer_margin described above.
  #
  my $resolution = $self->{'timer_resolution'};
  my $milliseconds
    = POSIX::ceil ($timer_margin
                   + 1000 * ($resolution - POSIX::fmod ($tod, $resolution)));
  $self->{'timer_id'}
    = Glib::Timeout->add ($milliseconds, \&timer_callback, $self,
                          GDK_PRIORITY_REDRAW);
  if (DEBUG) {
    print "start timer ",$self->{'timer_id'},", ${milliseconds}ms from $tod, to give ",$tod + $milliseconds / 1000.0,"\n";
  }
  return 0;  # remove previous timer
}

sub stop_timer {
  my ($self) = @_;
  if (defined ($self->{'timer_id'})) {
    if (DEBUG) { print "stop timer ",$self->{'timer_id'},"\n"; }
    Glib::Source->remove ($self->{'timer_id'});
    $self->{'timer_id'} = undef;
  }
}

sub decide_resolution_and_refresh {
  my ($self) = @_;
  $self->{'timer_resolution'}
    = $self->get('resolution')
      || (strftime_is_seconds($self->get('format') || DEFAULT_FORMAT)
          ? 1 : 60);
  if (DEBUG) { print "timer resolution ",$self->{'timer_resolution'},"\n"; }

  stop_timer ($self);
  timer_callback ($self);
}

sub decide_size {
  my ($self) = @_;

  # let GtkLabel's size take effect
  $self->set_size_request (-1,-1);

  $self->freeze_notify();

  my $format = $self->get('format') || DEFAULT_FORMAT;
  my $timezone = $self->get('timezone');
  call_with_timezone
    ($timezone,
     sub {
       my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
         = localtime (time());
       $hour = 23; $min = 59; $sec = 59;    # 23:59:59
       $mday = 30; $mon = 11; $year = 109;  # 31 Dec 2009
       $wday = 6; $yday = 365;
       $self->set('label', POSIX::strftime ($format, $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst));
     });

  my $req = $self->size_request();
  $self->set_size_request ($req->width, $req->height);
  if (DEBUG) {
    print "set_size_request ",$req->width(),"x",$req->height(),"\n";
  }

  $self->thaw_notify();
}

# This is slightly nasty.  The way decide_size() sets 'label' to find out
# how big the label is at 23:59:59 emits notify signals, both a notify of
# the 'label' changes, but also 'width_request' and stuff.  As a precaution
# only spin through that decide_size() for selected notifies, namely our
# format and timezone, and superclasses 'style' and 'use-markup'.
#
sub do_notify {
  my ($self, $pspec, $userdata) = @_;
  my $pname = $pspec->get_name;
  if (DEBUG) {
    print "notify: $pname (in_notify ",$self->{'in_notify'}||0,")\n";
  }
  return if $self->{'in_notify'};
  if ($pname eq 'format'
      || $pname eq 'timezone'
      || $pname eq 'style'
      || $pname eq 'use_markup') {
    $self->{'in_notify'} = 1;
    decide_size ($self);
    decide_resolution_and_refresh ($self);
    $self->{'in_notify'} = 0;
  }
}

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set('use-markup',DEFAULT_USE_MARKUP);
  $self->signal_connect (notify => \&do_notify);
  decide_size ($self);
  decide_resolution_and_refresh ($self);
}

sub DESTROY {
  my ($self) = @_;
  stop_timer ($self);
}

1;
__END__



=head1 NAME

Gtk2::Ex::Clock -- clock widget

=head1 SYNOPSIS

 my $clock = Gtk2::Ex::Clock->new ();
 my $clock = Gtk2::Ex::Clock->new (timezone => 'America/New_York');
 my $clock = Gtk2::Ex::Clock->new (format => '%I:%M<sup>%P</sup>');

=head1 DESCRIPTION

Gtk2::Ex::Clock displays a digital clock.  The default is 24-hour format
local time like "14:59", but the properties below allow other formats and/or
another timezone.

=head1 FUNCTIONS

=over 4

=item Gtk2::Ex::Clock->new ([key=>value, key=>value, ...])

Create and return a new clock widget.  Key/value pairs can be given to set
the properties such as C<format> or C<timezone> described below.  For
example,

    my $clock = Gtk2::Ex::Clock->new (format => '%a %H:%M',
                                    timezone => 'Asia/Tokyo');

=back

=head1 PROPERTIES

=over 4

=item format (default "%H:%M")

An C<strftime> format string to display the time.  The default is "%H:%M".
See the L<strftime(3)> man page or the GNU C Library manual for possible
C<%> conversions.

Date conversions can be included to show a day or date as well as the time.
This is particularly good for a remote timezone where you might not be sure
if it's today or yesterday there yet.

    my $clock = Gtk2::Ex::Clock->new (format => 'London %d%m %H:%M',
                                      timezone => 'Europe/London');

Pango markup can be used in the format string for bold, etc.  For example
am/pm as a superscript.

    my $clock = Gtk2::Ex::Clock->new (format => '%I:%M<sup>%P</sup>');

=item timezone (default local time)

A C<TZ> environment variable setting for the display.  The default is an
empty string, which is taken to mean local time (ie. leave TZ alone).

When set, C<TZ> is temporarily changed while getting and formatting the
time, and then restored so other parts of the program are not affected.  See
the L<tzset(3)> man page or the GNU C Library manual under "TZ Variable" for
the possible settings.

(This C<TZ> and C<tzset> manipulation is probably not thread safe, but
rumour has it you have to be very careful with threads and perl-gtk, so you
probably won't be using threads.)

=item resolution (default from format)

The resolution, in seconds, of the clock.  The default is 0 which means look
at the format to decide whether seconds is needed or minutes is enough.

A format using %S and various other mostly-standard forms lik %T and %X are
recognised as seconds, and anything else is minutes.  If this is not right
you can force the resolution either to ensure a seconds display is updated
every second, or to save CPU by ensuring a minute clock is only redrawn
every minute.

(Incidentally, if you're only displaying hours then you probably don't want
hour resolution, since a system time change in between won't be recognised
until the requested resolution worth of real time has elapsed.)

=back

The properties of GtkMisc (see L<Gtk2::Misc>) can be used to control padding
and alignment too.

=head1 EXAMPLE

Here's a complete program displaying a clock in a toplevel C<GtkWindow>.
See the examples directory in the sources for more.

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Gtk2 '-init';
    use Gtk2::Ex::Clock;

    my $window = Gtk2::Window->new('toplevel');
    $self->signal_connect (delete_event => sub { exit(0); });
    $window->add (Gtk2::Ex::Clock->new(format => '%a %I:%M%P',
                                       timezone => 'Europe/London'));
    $window->show_all;
    Gtk2->main();
    exit 0;

=head1 FUTURE

The current implementation has Gtk2::Ex::Clock as a subclass of GtkLabel,
but this causes some problems for size requests and will probably change to
go just from GtkMisc, so you're encouraged not to use GtkLabel properties.

If a clock is obscured by other windows its timer still runs.  This doesn't
cost much in the default minute resolution, but may be worth avoiding under
seconds resolution.

A DateTime::TimeZone object for the timezone would be a good way to avoid
fiddling with C<TZ> for remote locations.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-clock/index.html>

=head1 LICENSE

Gtk2::Ex::Clock is Copyright 2007, 2009, 2011, 2019 Kevin Ryde

Gtk2::Ex::Clock is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2::Ex::Clock is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2::Ex::Clock.  If not, see L<http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<Gtk2>, L<strftime(3)>, L<tzset(3)>

=cut
