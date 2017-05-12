# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package Gtk2::Ex::Clock;
use 5.008;
use strict;
use warnings;
use Gtk2 1.200; # version 1.200 for GDK_PRIORITY_REDRAW
use POSIX ();
use POSIX::Wide 2; # version 2 for netbsd 646 alias
use List::Util qw(min);
use Scalar::Util;
use Time::HiRes;
use Glib::Ex::SourceIds;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 15;

use constant _DEFAULT_FORMAT => '%H:%M';

use Glib::Object::Subclass
  'Gtk2::Label',
  properties => [Glib::ParamSpec->string
                 ('format',
                  'Format string',
                  'An strftime() format string to display the time.',
                  _DEFAULT_FORMAT,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('timezone',
                  'Timezone',
                  'The timezone to use in the display, either a string for the TZ environment variable, or a DateTime::TimeZone object.  An empty string or undef means the local timezone.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('timezone-string',
                  'Timezone string',
                  'The timezone to use in the display, as a string for the TZ environment variable.  An empty string or undef means the local timezone.',
                   (eval {Glib->VERSION(1.240);1}  
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->int
                 ('resolution',
                  'Resolution',
                  'The resolution of the clock, in seconds, or 0 to decide this from the format string.',
                  0,     # min
                  3600,  # max
                  0,     # default
                  Glib::G_PARAM_READWRITE),
                ];


# _TIMER_MARGIN_MILLISECONDS is an extra period in milliseconds to add to
# the timer period requested.  It's designed to ensure the timer doesn't
# fire before the target time boundary of 1 second or 1 minute, in case
# g_timeout_add() or the select() within it ends up rounding down to a clock
# tick boundary.
#
# In the unlikely event there's no sysconf() value for CLK_TCK, or no
# sysconf() func at all, assume the traditional 100 ticks/second, ie. a
# resolution of 10 milliseconds, giving a 20 ms margin.
#
use constant _TIMER_MARGIN_MILLISECONDS => do {
  my $clk_tck = -1;  # default -1 like the error return from sysconf()
  ## no critic (RequireCheckingReturnValueOfEval)
  eval { $clk_tck = POSIX::sysconf (POSIX::_SC_CLK_TCK()); };
  ### $clk_tck
  if ($clk_tck <= 0) { $clk_tck = 100; } # default assume 100 Hz, 10ms tick
  (2 * 1000.0 / $clk_tck)
};
### _TIMER_MARGIN_MILLISECONDS: _TIMER_MARGIN_MILLISECONDS()


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'format'} = _DEFAULT_FORMAT;
  $self->{'resolution'} = 0; # per pspec default
  $self->{'decided_resolution'} = 60; # of _DEFAULT_FORMAT
  $self->set_use_markup (1);
  _update($self);  # initial string for initial size
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'timezone_string') {
    my $timezone = $self->{'timezone'};
    # For DateTime::TimeZone read back the ->name() string.
    # Not yet documented.  Is this a good idea?
    if (Scalar::Util::blessed ($timezone)) {
      $timezone = $timezone->name;
    }
    return $timezone;
  }

  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Clock SET_PROPERTY: $pspec->get_name

  my $pname = $pspec->get_name;
  if ($pname eq 'timezone_string') {  # alias
    $pname = 'timezone';
  }
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'timezone') {
    if (Scalar::Util::blessed($newval)
        && $newval->isa('DateTime::TimeZone')) {
      require DateTime;
    } elsif (defined $newval && $newval ne '') {
      require Tie::TZ;
    }
  }

  if ($pname eq 'resolution' || $pname eq 'format') {
    $self->{'decided_resolution'}
      = $self->get('resolution')
        || ($self->strftime_is_seconds($self->{'format'}) ? 1 : 60);
    ### decided resolution: $self->{'decided_resolution'}
  }
  if ($pname eq 'timezone' || $pname eq 'format') {
    _update ($self);
  }
}

sub _timer_callback {
  my ($ref_weak_self) = @_;
  ### _timer_callback()
  my $self = $$ref_weak_self || return 0; # Glib::SOURCE_REMOVE

  _update ($self);

  # this timer should be removed by SourceIds anyway
  return 0; # Glib::SOURCE_REMOVE
}

# set the label string and start or restart timer
sub _update {
  my ($self) = @_;
  ### Clock _update()

  my $tod = Time::HiRes::time();
  my $format   = $self->{'format'};
  my $timezone = $self->{'timezone'};

  my ($str, $minute, $second);
  if (Scalar::Util::blessed($timezone)
      && $timezone->isa('DateTime::TimeZone')) {
    my $t = DateTime->from_epoch (epoch => $tod, time_zone => $timezone);
    $str = $t->strftime ($format);
    $minute = $t->minute;
    $second = $t->second;
  } else {
    my @tm;
    if (defined $timezone && $timezone ne '') {
      ### using TZ: $timezone
      no warnings 'once';
      local $Tie::TZ::TZ = $timezone;
      @tm = localtime ($tod);
      $str = POSIX::Wide::strftime ($format, @tm);
    } else {
      ### using current timezone
      @tm = localtime ($tod);
      $str = POSIX::Wide::strftime ($format, @tm);
    }
    $minute = $tm[1];
    $second = $tm[0];
  }
  $self->set_label ($str);

  # Decide how long in milliseconds until the next update.  This is from the
  # current $minute,$second,frac($tod) to the next multiple of
  # $self->{'decided_resolution'} seconds, plus _TIMER_MARGIN_MILLISECONDS
  # described above.
  #
  # If $self->{'decided_resolution'} is 1 second then $minute,$second have
  # no effect and it's just from the fractional part of $tod to the next 1
  # second.  Similarly if $self->{'decided_resolution'} is 60 seconds then
  # $minute has no effect.
  #
  # Rumour has it $second can be 60 for some oddity like a TAI system clock
  # displaying UTC.  Dunno if it really happens, but cap at 59 just in case.
  #
  # In theory an mktime of $second+1, or $minute+1,$second=0, would be the
  # $tod value to target.  Not absolutely certain that would come out right
  # if crossing a daylight savings boundary, though capping it modulo the
  # resolution like ($newtod - $tod) % $self->{'decided_resolution'} would
  # ensure a sensible range.  Would an mktime be worthwhile?  Taking just
  # 60*$minute+$second is a little less work.
  #
  my $milliseconds = POSIX::ceil
    (_TIMER_MARGIN_MILLISECONDS
     + (1000
        * ($self->{'decided_resolution'}
           - ((60*$minute + min(59,$second)) % $self->{'decided_resolution'})
           - ($tod - POSIX::floor($tod))))); # fraction part

  ### timer: "$tod is $minute,$second wait $milliseconds to give ".($tod + $milliseconds / 1000.0)
  Scalar::Util::weaken (my $weak_self = $self);
  $self->{'timer'} = Glib::Ex::SourceIds->new
    (Glib::Timeout->add ($milliseconds,
                         \&_timer_callback, \$weak_self,
                         Gtk2::GDK_PRIORITY_REDRAW() - 1));  # before redraws

}


#------------------------------------------------------------------------------

# $format is an strftime() format string.  Return true if it has 1 second
# resolution.
#
sub strftime_is_seconds {
  my ($self, $format) = @_;

  # %c is ctime() style, includes seconds
  # %r is "%I:%M:%S %p"
  # %s is seconds since 1970 (a GNU extension)
  # %S is seconds 0 to 59
  # %T is "%H:%M:%S"
  # %X is locale preferred time, probably "%H:%M:%S"
  # modifiers standard E and O, plus GNU "-_0^"
  #
  # DateTime extras:
  #   %N is nanoseconds, which really can't work, so ignore
  #
  # DateTime methods:
  #   second()
  #   sec()
  #   hms(), time()
  #   datetime(), is8601()
  #   epoch()
  #   utc_rd_as_seconds()
  #
  #   jd(), mjd() fractional part represents the time, but the decimals
  #   aren't a whole second so won't really display properly, ignore for now
  #   
  $format =~ s/%%//g; # literal "%"s, so eg. "%%Something" is not "%S"
  return ($format =~ /%[-_^0-9EO]*
                       ([crsSTX]
                       |\{(sec(ond)?|hms|(date)?time|iso8601|epoch|utc_rd_as_seconds)})/x);
}

1;
__END__

=for stopwords Pango realtime menubar multi undef TZ startup DateTime unicode charset resizes NoShrink zoneinfo Gtk2-Ex-Clock Ryde

=head1 NAME

Gtk2::Ex::Clock -- simple digital clock widget

=head1 SYNOPSIS

 use Gtk2::Ex::Clock;
 my $clock = Gtk2::Ex::Clock->new;  # local time

 # or a specified format, or a different timezone
 my $clock = Gtk2::Ex::Clock->new (format => '%I:%M<sup>%P</sup>',
                                   timezone => 'America/New_York');

 # or a DateTime::TimeZone object for the timezone
 use DateTime::TimeZone;
 my $timezone = DateTime::TimeZone->new (name => 'America/New_York');
 my $clock = Gtk2::Ex::Clock->new (timezone => $timezone);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Clock> is a subclass of C<Gtk2::Label>.

    Gtk2::Widget
       Gtk2::Misc
          Gtk2::Label
             Gtk2::Ex::Clock

=head1 DESCRIPTION

C<Gtk2::Ex::Clock> displays a digital clock.  The default is 24-hour format
"%H:%M" local time, like "14:59".  The properties below allow other formats
and/or a specified timezone.  Pango markup like "<bold>" can be included for
font effects.

C<Gtk2::Ex::Clock> is designed to be light weight and suitable for use
somewhere unobtrusive in a realtime or semi-realtime application.  The
right-hand end of a menubar is a good place for instance, depending on user
preferences.

In the default minutes display all a Clock costs in the program is a timer
waking once a minute to change a C<Gtk2::Label>.

If you've got a 7-segment LED style font you can display alarm clock style
by selecting that font in the usual ways from an RC file setting or Pango
markup.  F<examples/7seg.pl> in the sources does it with Pango markup and
Harvey Twyman's font.  (Unzip into your F<~/.fonts> directory.)

=over

L<http://www.twyman.org.uk/Fonts/>

=back

=head1 FUNCTIONS

=over 4

=item C<< $clock = Gtk2::Ex::Clock->new (key=>value,...) >>

Create and return a new clock widget.  Optional key/value pairs set initial
properties as per C<< Glib::Object->new >>.  For example,

    my $clock = Gtk2::Ex::Clock->new (format => '%a %H:%M',
                                      timezone => 'Asia/Tokyo');

=back

=head1 PROPERTIES

=over 4

=item C<format> (string, default C<"%H:%M">)

An C<strftime> format string for the date/time display.  See the C<strftime>
man page or the GNU C Library manual for possible C<%> conversions.

Date conversions can be included to show a day or date as well as the time.
This is good for a remote timezone where you might not be sure if it's today
or tomorrow yet.

    my $clock = Gtk2::Ex::Clock->new (format => 'London %d%m %H:%M',
                                      timezone => 'Europe/London');

Pango markup can be used for bold, etc.  For example "am/pm" as superscript.

    my $clock = Gtk2::Ex::Clock->new(format=>'%I:%M<sup>%P</sup>');

Newlines can be included for multi-line display, for instance date on one
line and the time below it.  The various C<Gtk2::Label> and C<Gtk2::Misc>
properties can control centring.  For example,

    my $clock = Gtk2::Ex::Clock->new (format  => "%d %b\n%H:%M",
                                      justify => 'center',
                                      xalign  => 0.5);

=item C<timezone> (scalar string or C<DateTime::TimeZone>, default local time)

=item C<timezone-string> (string)

The timezone to use in the display.  An empty string or undef (the default)
means local time.

For a string, the C<TZ> environment variable C<$ENV{'TZ'}> is set to format
the time, and restored so other parts of the program are not affected.  See
the C<tzset> man page or the GNU C Library manual under "TZ Variable" for
possible settings.

For a C<DateTime::TimeZone> object the offsets in it and a C<DateTime>
object's C<< $dt->strftime >> are used for the display.  That C<strftime>
method may have more conversions than what the C library offers.

The C<timezone> and C<timezone-string> properties act on the same underlying
setting.  C<timezone-string> is a plain string type and allows TZ strings to
be set from C<Gtk2::Builder>.

=item C<resolution> (integer, default from format)

The resolution, in seconds, of the clock.  The default 0 means look at the
format to decide whether seconds is needed or minutes is enough.  Formats
using C<%S> and various other mostly-standard forms like C<%T> and C<%X> are
recognised as seconds, as are C<DateTime> methods like C<%{iso8601}>.
Anything else is minutes.  If that comes out wrong you can force it by
setting this property.

Incidentally, if you're only displaying hours then you don't want hour
resolution since a system time change won't be recognised until the
requested resolution worth of real time has elapsed.

=back

The properties of C<Gtk2::Label> and C<Gtk2::Misc> will variously control
padding, alignment, etc.  See the F<examples> directory in the sources for
some complete programs displaying clocks in various forms.

=head1 LOCALIZATIONS

For a string C<timezone> property the C<POSIX::strftime> function gets
localized day names etc from C<LC_TIME> in the usual way.  Generally Perl
does a suitable C<setlocale(LC_TIME)> at startup so the usual settings take
effect automatically.

For a C<DateTime::TimeZone> object the DateTime C<strftime> gets
localizations from the C<< DateTime->DefaultLocale >> (see L<DateTime>).
Generally you must make a call to set C<DefaultLocale> yourself at some
point early in the program.

The C<format> string can include wide-char unicode in Perl's usual fashion,
for both plain C<strftime> and C<DateTime>.  The plain C<strftime> uses
C<POSIX::Wide::strftime()> so characters in the format are not limited to
what's available in the locale charset.

=head1 IMPLEMENTATION

The clock is implemented by updating a C<Gtk2::Label> under a timer.  This
is simple and makes good use of the label widget's text drawing code, but it
does mean that in a variable-width font the size of the widget can change as
the time changes.  For minutes display any resizes are hardly noticeable,
but for seconds it may be best to have a fixed-width font, or to
C<set_size_request> a fixed size (initial size plus a few pixels say), or
even try a NoShrink (see L<Gtk2::Ex::NoShrink>).

The way C<TZ> is temporarily changed to implement a non-local timezone could
be slightly on the slow side.  The GNU C Library (as of version 2.10) for
instance opens and re-reads a zoneinfo file on each change.  Doing that
twice (to the new and back to the old) each minute is fine, but for seconds
you may prefer C<DateTime::TimeZone>.  Changing C<TZ> probably isn't thread
safe either, though rumour has it you have to be extremely careful with
threads and Gtk2-Perl anyway.  Again you can use a C<DateTime::TimeZone>
object if nervous.

Any code making localized changes to C<TZ> should be careful not to run the
main loop with the change in force.  Doing so is probably a bad idea for
many reasons, but in particular if a clock widget showing the default local
time could update to the different C<TZ>.  Things like C<< $dialog->run >>
iterate the main loop.

The display is designed for a resolution no faster than 1 second, so the
DateTime C<%N> format format for nanoseconds is fairly useless.  It ends up
displaying a value some 20 to 30 milliseconds past the 1 second boundary
because that's when the clock updates.  A faster time display is of course
possible, capped by some frame rate and the speed of the X server, but would
more likely be something more like a stopwatch than time of day.
Incidentally C<Gtk2::Label> as used in the Clock here isn't a particularly
efficient base for rapid updates.

=head1 SEE ALSO

C<strftime(3)>, C<tzset(3)>, L<Gtk2>, L<Gtk2::Label>, L<Gtk2::Misc>,
L<DateTime::TimeZone>, L<DateTime>, L<POSIX::Wide>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-clock/index.html>

=head1 LICENSE

Gtk2-Ex-Clock is Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Clock is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Clock.  If not, see L<http://www.gnu.org/licenses/>.

=cut
