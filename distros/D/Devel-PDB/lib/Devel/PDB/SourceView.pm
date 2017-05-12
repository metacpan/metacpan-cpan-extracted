# vi: set autoindent shiftwidth=4 tabstop=8 softtabstop=4 expandtab:
package Devel::PDB::SourceView;

use strict;
use warnings;

use Curses;
use Curses::UI::Widget;
use Curses::UI::Common;

use Devel::PDB::Source;

use vars qw(
  $VERSION
  @ISA
  );

$VERSION = '1.2';

@ISA = qw(
  Curses::UI::Widget
  );

sub new () {
    my ($class, %userargs) = @_;

    keys_to_lowercase(\%userargs);

    my %args = (
        -parent => undef,    # the parent window
        -width  => undef,    # the width of the label
        -height => undef,    # the height of the label
        -x      => 0,        # the hor. pos. rel. to the parent
        -y      => 0,        # the vert. pos. rel. to the parent
        -bg     => -1,
        -fg     => -1,
        -source => undef,

        %userargs,

        -routines => {
            'cursor-up'    => \&cursor_up,
            'cursor-down'  => \&cursor_down,
            'cursor-ppage' => \&cursor_pageup,
            'cursor-npage' => \&cursor_pagedown,
            'search'       => \&search,
            'search-next'  => \&search_next,
            'search-prev'  => \&search_prev,
            'goto'         => \&goto,
            'cursor-home'  => \&cursor_home,
            'cursor-end'   => \&cursor_end,
        },
        -bindings => {
            KEY_UP()    => 'cursor-up',
            'k'         => 'cursor-up',
            KEY_DOWN()  => 'cursor-down',
            'j'         => 'cursor-down',
            KEY_PPAGE() => 'cursor-ppage',
            "\cB"       => 'cursor-ppage',
            KEY_NPAGE() => 'cursor-npage',
            "\cF"       => 'cursor-npage',
            '/'         => 'search',
            'n'         => 'search-next',
            'N'         => 'search-prev',
            "\cG"       => 'goto',
            KEY_HOME()  => 'cursor-home',
            KEY_END()   => 'cursor-end',
        },

        -nocursor => 0,
    );

    # Create the widget.
    my $this = $class->SUPER::new(%args);

    $this->layout();

    return $this;
}

sub layout() {
    my $this = shift;
    $this->SUPER::layout or return;

    return $this;
}

sub source {
    my $this = shift;

    if (@_) {
        my $source = shift;
        $this->{-source}->view(undef) if $this->{-source};
        $this->{-source} = $source;
        $this->{-source}->view($this);
        return $this;
    }

    return $this->{-source};
}

sub scroll_to_line {
    my $this         = shift;
    my $source       = $this->{-source};
    my $current_line = $source->current_line;
    my $y1           = $source->scr_y;
    my $y2           = $y1 + $this->canvasheight;

    if ($current_line < $y1 || $current_line >= $y2) {
        $y1 = $current_line - ($this->canvasheight >> 1);
        $y1 = 0 if $y1 < 0;
        $source->scr_y($y1);
    }
}

sub draw(;$) {
    my $this      = shift;
    my $no_update = shift || 0;
    my $source    = $this->{-source};

    $this->{-title} = $source->filename . ':' . ($source->cur_y + 1);

    # Draw the widget.
    $this->SUPER::draw(1) or return $this;

    my $canvas = $this->{-canvasscr};

    # Clear all attributes.
    $canvas->attrset(A_NORMAL);

    # Let there be color
    my $color;

    if ($Curses::UI::color_support) {
        $color = COLOR_PAIR($Curses::UI::color_object->get_color_pair($this->{-fg}, $this->{-bg}));
        $canvas->attron($color);
    }

    my $current_line = $source->current_line;
    my $lines        = $source->lines;
    my $breaks       = $source->breaks;
    my $cwidth       = $this->canvaswidth - 2;
    my $cheight      = $this->canvasheight;

    for (my ($n, $y) = ($source->scr_y, 0); $n < @$lines && $y < $cheight; ++$n, ++$y) {
        my $line = $lines->[$n] || '#';
        my $reverse = $current_line == $n;

        chomp $line;

        # Clip it if it is too long.
        $line = substr($line, 0, $cwidth) if length($line) > $cwidth;

        if ($reverse) {
            $canvas->attron(A_REVERSE);
            $canvas->addstr($y, 0, ' ' x $cwidth);
        }

        if ($breaks->{$n}) {
            $canvas->attron(
                COLOR_PAIR($Curses::UI::color_object->get_color_pair(($breaks->{$n} =~ /\0/) ? 'black' : 'red', $this->{-bg})))
              if $color;
            $canvas->addch($y, 0, '*');
            $canvas->attron($color) if $color;
        }
        $canvas->addstr($y, 2, $line);

        $canvas->attroff(A_REVERSE) if $reverse;
    }

    $canvas->move($source->cur_y - $source->scr_y, $source->cur_x - $source->scr_x + 2);

    $canvas->noutrefresh;
    doupdate() unless $no_update;

    return $this;
}

sub scroll_to_cursor {
    my ($this) = @_;
    my $source = $this->source;
    my $cur_y  = $source->cur_y;
    my $scr_y  = $source->scr_y;
    my $height = $this->canvasheight;

    $source->scr_y($cur_y - $height + 1) if $cur_y >= $scr_y + $height;
    $source->scr_y($cur_y) if $cur_y < $scr_y;

    $this->intellidraw;
}

sub cursor_up(;$) {
    my $this = shift;
    shift;    # stub for bindings handling.
    my $amount = shift || 1;
    my $source = $this->source;

    $source->cur_y($source->cur_y - $amount);
    $this->scroll_to_cursor;

    return $this;
}

sub cursor_down(;$) {
    my $this = shift;
    shift;    # stub for bindings handling.
    my $amount = shift || 1;
    my $source = $this->source;

    $source->cur_y($source->cur_y + $amount);
    $this->scroll_to_cursor;

    return $this;
}

sub cursor_pageup(;$) {
    my $this = shift;

    $this->cursor_up(undef, $this->canvasheight - 1);

    return $this;
}

sub cursor_pagedown(;$) {
    my $this = shift;

    $this->cursor_down(undef, $this->canvasheight - 1);

    return $this;
}

sub real_search {
    my ($this, $dir, $regex) = @_;

    $regex = $Curses::UI::rootobject->question(-question => 'Please enter a RegEx to search for', DB::window_style(),)
      if !$regex;

    if ($regex) {
        my $source = $this->source;
        my $lines  = $source->lines;
        my $cnt    = @$lines;
        my $i      = $source->cur_y + $dir;
        for (; $i >= 0 && $i < $cnt; $i += $dir) {
            if ($lines->[$i] =~ /$regex/i) {
                $source->cur_y($i);
                $this->scroll_to_cursor;
                last;
            }
        }
        $this->{-lastsearch} = $regex;
    }
}

sub search {
    my $this = shift;
    $this->real_search(1);
}

sub search_next {
    my $this = shift;
    $this->real_search(1, $this->{-lastsearch});
}

sub search_prev {
    my $this = shift;
    $this->real_search(-1, $this->{-lastsearch});
}

sub goto {
    my ($this, $line) = @_;

    $line = undef if (length($line) == 1 && ord($line) < 32);
    $line = $Curses::UI::rootobject->question(-question => 'Destination line number', DB::window_style())
      unless (defined($line));
    $line = int $line if defined $line;
    if ($line > 0) {
        my $source = $this->source;
        my $cnt    = @{$source->lines};

        $line = $cnt if $line > $cnt;
        $source->cur_y($line - 1);
        $this->scroll_to_cursor;
    }
}

sub cursor_home {
    my $this = shift;
    $this->goto(1);
}

sub cursor_end {
    my $this   = shift;
    my $source = $this->source;
    $this->goto(scalar(@{$source->lines}));
}

1;
