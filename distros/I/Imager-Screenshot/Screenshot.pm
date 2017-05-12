package Imager::Screenshot;
use strict;
use vars qw(@ISA $VERSION @EXPORT_OK);
use Imager;
require Exporter;

push @ISA, 'Exporter';
@EXPORT_OK = 'screenshot';

BEGIN {
  require Exporter;
  @ISA = qw(Exporter);
  $VERSION = '0.013';

  require XSLoader;
  XSLoader::load('Imager::Screenshot' => $VERSION);
}

sub screenshot {
  # lose the class if called as a method
  @_ % 2 == 1 and shift;

  my %opts = 
    (
     decor => 0, 
     display => 0, 
     left => 0, 
     top => 0,
     right => 0,
     bottom => 0,
     monitor => 0,
     @_);

  my $result;
  if (defined $opts{hwnd}) {
    defined &_win32
      or die "Win32 driver not enabled\n";
    $result = _win32($opts{hwnd}, $opts{decor}, $opts{left}, $opts{top},
		     $opts{right}, $opts{bottom}, $opts{monitor});
  }
  elsif (defined $opts{id}) { # X11 window id
    exists $opts{display} or $opts{display} = 0;
    defined &_x11
      or die "X11 driver not enabled\n";
    $result = _x11($opts{display}, $opts{id}, $opts{left}, $opts{top},
		   $opts{right}, $opts{bottom});
  }
  elsif (defined $opts{darwin}) { # as long as it's there
    defined &_darwin
      or die "Darwin driver not enabled\n";
    $result = _darwin($opts{left}, $opts{top}, $opts{right}, $opts{bottom});
  }
  elsif ($opts{widget}) {
    # Perl/Tk widget
    my $top = $opts{widget}->toplevel;
    my $sys = $top->windowingsystem;
    if ($sys eq 'win32') {
      unless (defined &_win32) {
        Imager->_set_error("Win32 Tk and Win32 support not built");
        return;
      }
      $result = _win32(hex($opts{widget}->id), $opts{decor}, 
		       $opts{left}, $opts{top}, $opts{right}, $opts{bottom});
    }
    elsif ($sys eq 'x11') {
      unless (defined &_x11) {
        Imager->_set_error("X11 Tk and X11 support not built");
        return;
      }

      my $id_hex = $opts{widget}->id;
      
      # is there a way to get the display pointer from Tk?
      $result = _x11($opts{display}, hex($id_hex), $opts{left}, $opts{top},
		     $opts{right}, $opts{bottom});
    }
    else {
      Imager->_set_error("Unsupported windowing system '$sys'");
      return;
    }
  }
  else {
    $result =
      defined &_win32 ? _win32(0, $opts{decor}, $opts{left}, $opts{top},
			       $opts{right}, $opts{bottom}, $opts{monitor}) :
      defined &_darwin ? _darwin($opts{left}, $opts{top},
				 $opts{right}, $opts{bottom}) :
      defined &_x11 ? _x11($opts{display}, 0, $opts{left}, $opts{top},
			     $opts{right}, $opts{bottom}) :
	   die "No drivers enabled\n";
  }

  unless ($result) {
    Imager->_set_error(Imager->_error_as_msg());
    return;
  }

  # RT #24992 - the Imager typemap entry is broken pre-0.56, so
  # wrap it here
  return bless { IMG => $result }, "Imager";
}

sub have_win32 {
  defined &_win32;
}

sub have_x11 {
  defined &_x11;
}

sub have_darwin {
  defined &_darwin;
}

sub x11_open {
  my $display = _x11_open(@_);
  unless ($display) {
    Imager->_set_error(Imager->_error_as_msg);
    return;
  }

  return $display;
}

sub x11_close {
  _x11_close(shift);
}

1;

__END__

=head1 NAME

Imager::Screenshot - screenshot to an Imager image

=head1 SYNOPSIS

  use Imager::Screenshot 'screenshot';

  # whole screen
  my $img = screenshot();

  # Win32 window
  my $img2 = screenshot(hwnd => $hwnd);

  # X11 window
  my $img3 = screenshot(display => $display, id => $window_id);

  # X11 tools
  my $display = Imager::Screenshot::x11_open();
  Imager::Screenshot::x11_close($display);

  # test for win32 support
  if (Imager::Screenshot->have_win32) { ... }

  # test for x11 support
  if (Imager::Screenshot->have_x11) { ... }
  
  # test for Darwin (Mac OS X) support
  if (Imager::Screenshot->have_darwin) { ... }
  

=head1 DESCRIPTION

Imager::Screenshot captures either a desktop or a specified window and
returns the result as an Imager image.

Currently the image is always returned as a 24-bit image.

=over

=item screenshot hwnd => I<window handle>

=item screenshot hwnd => I<window handle>, decor => <capture decorations>

=item screenshot hwnd => "active"

Retrieve a screenshot under Win32, if I<window handle> is zero,
capture the desktop.

By default, window decorations are not captured, if the C<decor>
parameter is set to true then window decorations are included.

As of 0.010 hwnd can also be C<"active"> to capture the active (or
"foreground") window.

=item screenshot hwnd => 0

Retrieve a screeshot of the default desktop under Win32.

=item screenshot hwnd => 0, monitor => -1

Retrieve a screenshot of all attached monitors under Win32.

Note: this returns an image with an alpha channel, since there can be
regions in the bounding rectangle of all monitors that no particular
monitor covers.

=item screenshot hwnd => 0, monitor => I<index>

Retrieve a screenshot from a particular monitor under Win32.  A
I<monitor> of zero is always treated as the primary monitor.

If the given monitor is not active screenshot() will fail.

=item screenshot id => I<window id>

=item screenshot id => I<window id>, display => I<display object>

Retrieve a screenshot under X11, if I<id> is zero, capture the root
window.  I<display object> is a integer version of an X11 C< Display *
>, if this isn't supplied C<screenshot()> will attempt connect to the
the display specified by $ENV{DISPLAY}.

Note: taking a screenshot of a remote display is slow.

=item screenshot darwin => 0

Retrieve a screenshot under Mac OS X.  The only supported value for
the C<darwin> parameter is C<0>.

For a screen capture to be taken, the current user using
Imager:Screenshot must be the currently logged in user on the display.

If you're using fast user switching, the current user must be the
active user.

Note: this means you can ssh into a Mac OS X box and screenshot from
the ssh session, if you're the current user on the display.

=item screenshot widget => I<widget>

=item screenshot widget => I<widget>, display => I<display>

=item screenshot widget => I<widget>, decor => I<capture decorations>

Retrieve a screenshot of a Tk widget, under Win32 or X11, depending on
how Tk has been built.

If Tk was built for X11 then the display parameter applies.

If Tk was built for Win32 then the decor parameter applies.

=item screenshot

If no C<id>, C<hwnd> or C<widget> parameter is supplied:

=over

=item *

if Win32 support is compiled, return screenshot(hwnd => 0).

=item *

if Darwin support is compiled, return screenshot(darwin => 0).

=item *

if X11 support is compiled, return screenshot(id => 0).

=item *

otherwise, die.

=back

You can also supply the following parameters to retrieve a subset of
the window:

=over

=item *

left

=item *

top

=item *

right

=item *

bottom

=back

If left or top is negative, then treat that as from the right/bottom
edge of the window.

If right ot bottom is zero or negative then treat as from the
right/bottom edge of the window.

So setting all 4 values to 0 retrieves the whole window.

  # a 10-pixel wide right edge of the window
  my $right_10 = screenshot(left => -10, ...);

  # the top-left 100x100 portion of the window
  my $topleft_100 = screenshot(right => 100, bottom => 100, ...);

  # 10x10 pixel at the bottom right corner
  my $bott_right_10 = screenshot(left => -10, top => -10, ...);

If screenshot() fails, it will return nothing, and the cause of the
failure can be retrieved via Imager->errstr, so typical use could be:

  my $img = screenshot(...) or die Imager->errstr;

=item have_win32

Returns true if Win32 support is available.

=item have_x11

Returns true if X11 support is available.

=item have_darwin

Returns true if Darwin support is available.

=item Imager::Screenshot::x11_open

=item Imager::Screenshot::x11_open I<display name>

Attempts to open a connection to either the display name in
$ENV{DISPLAY} or the supplied display name.  Returns a value suitable
for the I<display> parameter of screenshot, or undef.

=item Imager::Screenshot::x11_close I<display>

Closes a display returned by Imager::Screenshot::x11_open().

=back

=head1 TAGS

screenshot() sets a number of tags in the images it returns, these are:

=over

=item *

ss_left - the distance between the left side of the window and the
left side of the captured area.  The same value as the I<left>
parameter when that is positive.

=item *

ss_top - the distance between the top side of the window the top side
of the captured area.  The same value at the I<top> parameter when
that is positive.

=item *

ss_window_width - the full width of the window.

=item *

ss_window_height - the full height of the window.

=item *

ss_type - the type of capture done, either "Win32" or "X11".

=back

To cheaply get the window size you can capture a single pixel:

  my $im = screenshot(right => 1, bottom => 1);
  my $window_width  = $im->tags(name => 'ss_window_width');
  my $window_height = $im->tags(name => 'ss_window_height');

=head1 CAVEATS

It's possible to have more than one grab driver available, for
example, Win32 and X11, and which is used can have an effect on the
result.

Under Win32 or OS X, if there's a screesaver running, then you grab
the results of the screensaver.

On OS X, you can grab the display from an ssh session as long as the
ssh session is under the same user as the currently active user on the
display.

Grabbing the root window on a rootless server (eg. Cygwin/X) may not
grab the background that you see.  In fact, when I tested under
Cygwin/X I got the xterm window contents even when the Windows
screensaver was running.  The root window captured appeared to be that
generated by my window manager.

Grabbing a window with other windows overlaying it will capture the
content of those windows where they hide the window you want to
capture.  You may want to raise the window to top.  This may be a
security concern if the overlapping windows contain any sensitive
information - true for any screen capture.

=head1 LICENSE

Imager::Screenshot is licensed under the same terms as Perl itself.

=head1 TODO

Future plans include:

=over

=item *

window name searches - currently screenshot() requires a window
identifier of some sort, it would be more usable if we could supply
some other identifier, either a window title or a window class name.

=back

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=cut


