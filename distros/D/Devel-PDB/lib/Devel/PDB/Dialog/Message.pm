# vi: set autoindent shiftwidth=4 tabstop=8 softtabstop=4 expandtab:
package Devel::PDB::Dialog::Message;
use strict;
use warnings;

use Curses;
use Curses::UI;
use Curses::UI::Window;
use Curses::UI::Common;

use vars qw(
  $VERSION
  @ISA
  );

@ISA = qw(
  Curses::UI::Window
  Curses::UI::Common
  );

$VERSION = '1.2';

sub new () {
    my $class = shift;

    my %userargs = @_;
    keys_to_lowercase(\%userargs);

    my %args = (
        -border  => 1,
        -message => '',    # The message to show
        -ipad    => 1,
        -fg      => -1,
        -bg      => -1,

        %userargs,

        -titleinverse => 1,
        -centered     => 1,
    );

    # Create a new object, but remember the current
    # screen_too_small setting. The width needed for the
    # buttons can only be computed in the second run
    # of focus() and we do not want the first run to
    # set screen_too_small to a true value because
    # of this.
    #
    my $remember = $Curses::UI::screen_too_small;
    my $this     = $class->SUPER::new(%args);

    my $viewer = $this->add(
        'message', 'TextViewer',
        -border     => 1,
        -vscrollbar => 1,
        -wrapping   => 1,
        -padbottom  => 2,
        -text       => $this->{-message},
        -bg         => $this->{-bg},
        -fg         => $this->{-fg},
        -bbg        => $this->{-bg},
        -bfg        => $this->{-fg},
        -focusable  => 0,
    );

    # Create a hash with arguments that may be passed to
    # the Buttonbox class.
    my %buttonargs = (-buttonalignment => 'right',);
    foreach my $arg (qw(-buttons -selected -buttonalignment)) {
        $buttonargs{$arg} = $this->{$arg}
          if exists $this->{$arg};
    }
    my $b = $this->add(
        'buttons', 'Buttonbox',
        -y  => -1,
        -bg => $this->{-bg},
        -fg => $this->{-fg},

        %buttonargs
    );

    # Let the window in which the buttons are loose focus
    # if a button is pressed.
    $b->set_routine(
        'press-button',
        sub {
            my $this   = shift;
            my $parent = $this->parent;
            $parent->loose_focus();
        });

    $this->set_binding(sub { $viewer->cursor_left;     $viewer->intellidraw }, KEY_LEFT);
    $this->set_binding(sub { $viewer->cursor_right;    $viewer->intellidraw }, KEY_RIGHT);
    $this->set_binding(sub { $viewer->cursor_up;       $viewer->intellidraw }, KEY_UP);
    $this->set_binding(sub { $viewer->cursor_down;     $viewer->intellidraw }, KEY_DOWN);
    $this->set_binding(sub { $viewer->cursor_pageup;   $viewer->intellidraw }, KEY_PPAGE);
    $this->set_binding(sub { $viewer->cursor_pagedown; $viewer->intellidraw }, KEY_NPAGE);
    $this->set_binding(sub { $viewer->cursor_to_home;  $viewer->intellidraw }, KEY_HOME);
    $this->set_binding(sub { $viewer->cursor_to_end;   $viewer->intellidraw }, KEY_END);
    $this->set_binding(sub { $viewer->search_forward;  $viewer->intellidraw }, "/");
    $this->set_binding(sub { $viewer->search_backward; $viewer->intellidraw }, "?");
    $this->set_binding(sub { DB::export_to_file(undef, $this->{-title}, \$this->{-message}) }, "\cS", "\cL", KEY_F(6),);

    # Restore screen_too_small (see above) and
    # start the second layout pass.
    $Curses::UI::screen_too_small = $remember;
    $this->layout;

    # Set the initial focus to the buttons.
    $b->focus;

    return bless $this, $class;
}

# TODO delete_curses_windows
sub layout() {
    my $this = shift;
    return $this if $Curses::UI::screen_too_small;

    # The maximum available space on the screen.
    my $avail_width  = $ENV{COLS};
    my $avail_height = $ENV{LINES};

    # Compute the maximum available space for the message.

    $this->process_padding;

    my $avail_textwidth = $avail_width;
    $avail_textwidth -= 2;                                          # border for the textviewer
    $avail_textwidth -= 2 if $this->{-border};
    $avail_textwidth -= $this->{-ipadleft} - $this->{-ipadright};

    my $avail_textheight = $avail_height;
    $avail_textheight -= 2;                                          # border for the textviewer
    $avail_textheight -= 2;                                          # empty line and line of buttons
    $avail_textheight -= 2 if $this->{-border};
    $avail_textheight -= $this->{-ipadtop} - $this->{-ipadbottom};

    # Break up the message in separate lines if neccessary.
    my @lines = ();
    foreach (split(/\n/, $this->{-message})) {
        push @lines, @{text_wrap($_, $avail_textwidth)};
    }

    # Compute the longest line in the message.
    my $longest_line = 0;
    foreach (@lines) {
        $longest_line = length($_)
          if (length($_) > $longest_line);
    }

    # Compute the width of the buttons (if the buttons
    # object is available. This is not the case just after
    # new() calls SUPER::new()).
    my $buttons      = $this->getobj('buttons');
    my $button_width = 0;
    if (defined $buttons) {
        $button_width = $buttons->compute_buttonwidth;
    }

    # Decide what is the longest line.
    $longest_line = $button_width if $longest_line < $button_width;

    # Check if there is enough space to show the widget.
    if ($avail_textheight < 1 or $avail_textwidth < $longest_line) {
        $Curses::UI::screen_too_small = 1;
        return $this;
    }

    # Compute the size of the widget.

    my $w = $longest_line;
    $w += 2;                                          # border of textviewer
    $w += 2;                                          # extra width for preventing wrapping of text
    $w += 2 if $this->{-border};
    $w += $this->{-ipadleft} + $this->{-ipadright};

    my $h = @lines;
    $h += 2;                                          # empty line + line of buttons
    $h += 2;                                          # border of textviewer
    $h += 2 if $this->{-border};
    $h += $this->{-ipadtop} + $this->{-ipadbottom};

    $this->{-width}  = $w;
    $this->{-height} = $h;

    $this->SUPER::layout;

    return $this;
}

sub get() {
    my $this = shift;
    $this->getobj('buttons')->get;
}

sub run {
    $Curses::UI::rootobject->tempdialog(@_);
}

1;
