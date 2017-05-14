package Games::Rezrov::ZIO_Tk;
#
# z-machine i/o for perls with Perl/Tk.
#

use strict;
use Tk;
use Tk::Font;

use Carp qw(cluck carp confess);

use Games::Rezrov::ZConst;
use Games::Rezrov::ZIO_Generic;
use Games::Rezrov::ZIO_Color;
use Games::Rezrov::FontVectors;

use constant X_BORDER => 2;
# FIX ME?

use constant STANDARD_COMPLIANT_BUT_EVEN_SLOWER => 0;
# if 0 (noncompliant) we buffer output in the upper window.

use constant FIXED_FAMILY => "Courier";
# FIX ME!

use constant DEFAULT_BLINK_DELAY => 1000;

#use constant TEXT_ANCHOR => "nw";
use constant TEXT_ANCHOR => "w";

@Games::Rezrov::ZIO_Tk::ISA = qw(
				 Games::Rezrov::ZIO_Generic
				 Games::Rezrov::ZIO_Color
				);

use Games::Rezrov::MethodMaker qw(
			   dumb_fonts
			   font_cache

			   font_size
			   line_height
			   fixed_font_width
			   current_font

			   cursor_id
			   cursor_x
			   cursor_status
			   blink_id

			   zfont
			   last_text_id

			   variable_font_family
			  );

# again, a lot of statics for speed...
my ($w_main, $c, $status_line, $upper_lines);
my ($abs_x, $abs_row, $abs_col, $rows, @widgets);
my $Y_BORDER;
my $initialized;

sub new {
  my ($type, %options) = @_;
  my $self = new Games::Rezrov::ZIO_Generic(%options);
  bless $self, $type;
  $self->font_cache({});
  $self->zfont(Games::Rezrov::ZConst::FONT_NORMAL);
  $abs_row=0;

  return $self;
}

sub set_version {
  my ($self, $need_status, $init_sub) = @_;
  # set up window
  $w_main = MainWindow->new();
  $w_main->title("rezrov");
  $w_main->bind('<Configure>' => [ $self => 'set_geometry' ]);
  $w_main->bind('<Control-c>' => [ $self => 'cleanup' ]);
#  $w_main->bind('<Tab>' => [ $self => 'i_am_too_dumb_to_figure_this_out' ]);

  my $is_win32 = ($^O =~ /mswin32/i) ? 1 : 0;
  my ($DEFAULT_VARIABLE_FAMILY, $DEFAULT_FONT_SIZE);
  if ($is_win32) {
      $DEFAULT_VARIABLE_FAMILY = "times new roman";
      $DEFAULT_FONT_SIZE = 14;
  } else {
      $DEFAULT_VARIABLE_FAMILY = "times";
      $DEFAULT_FONT_SIZE = 18;
  }

  my $options = $self->zio_options();
  my $vff = lc($options->{"family"} || $DEFAULT_VARIABLE_FAMILY);
  unless (grep {lc($_) eq $vff} $w_main->fontFamilies()) {
    $self->fatal_error(sprintf "Invalid font family \"%s\"; available families are:\n  %s\n", $vff, join "\n  ", column_list([sort $w_main->fontFamilies()]));
  }
  $self->variable_font_family($vff);
  $self->font_size($options->{"fontsize"} || $DEFAULT_FONT_SIZE);
  
  $self->parse_color_options($options);

  my $f_variable = $self->set_text_style(Games::Rezrov::ZConst::STYLE_ROMAN);
  my $f_fixed = $self->set_text_style(Games::Rezrov::ZConst::STYLE_FIXED);
  $self->set_text_style(Games::Rezrov::ZConst::STYLE_ROMAN);

  # Determine the approximate font geometry
  die "Couldn't init fixed font!" unless $f_fixed;
  die "Couldn't init variable font!" unless $f_variable;

  my $font_width = $w_main->fontMeasure($f_fixed, "X");

  my $line_height = $self->biggest_metric($f_fixed, $f_variable, "-linespace");
#  my $line_height = $w_main->fontMetrics($f_fixed, "-linespace");

  $line_height += $options->{"fontspace"} if exists $options->{"fontspace"};

#  $self->line_ascent($self->biggest_metric($f_fixed, $f_variable, "-ascent"));
#  $self->line_descent($self->biggest_metric($f_fixed, $f_variable, "-descent"));

  my $canvas_x = $options->{"x"} || int($w_main->screenwidth * 0.7);
  my $canvas_y;
  if ($options->{"y"}) {
    $canvas_y = $options->{"y"};
  } else {
    my $y = int($w_main->screenheight * 0.6);
    my $rows = int($y / $line_height);
    $canvas_y = $rows * $line_height;
    # round to a multiple of the line height
  }

  $c = $w_main->Canvas(
		       "-width" => $canvas_x,
		       "-height" => $canvas_y,
		       "-bg" => $self->default_bg(),
		       "-takefocus" => 1,
		       "-highlightthickness" => 0,
		      );

  if ($need_status) {
    $status_line = $w_main->Canvas(
				   "-borderwidth" => 0,
				   "-relief" => "flat",
				   "-width" => $canvas_x,
				   "-height" => $line_height,
				   "-bg" => $self->sbg(),
				   "-takefocus" => 0,
				  );
    
    $status_line->pack("-anchor" => "n",
		       "-fill" => "x");
  }

  $self->line_height($line_height);
  $Y_BORDER = $line_height / 2;

  $self->fixed_font_width($font_width);

  $self->set_geometry();

  $abs_x = X_BORDER;
  # HACK

  $abs_col = 0;
  $abs_row = int($canvas_y / $line_height);

  $c->pack("-anchor" => "s",
	   "-expand" => 1,
	   "-fill" => "both");

  $w_main->after(0, $init_sub);
  # delay required??

  $initialized = 1;

  MainLoop;

  return 1;
}

sub update {
  # force screen refresh
  $c->update();
}

sub fatal_error {
  if ($initialized) {
    $_[0]->SUPER::fatal_error($_[1]);
  } else {
    die $_[1];
  }
}

sub fixed_font_default {
  # true or false: does this zio use a fixed-width font?
  return 0;
}

sub manual_status_line {
  # true or false: does this zio want to draw the status line itself?
  return 1;
}

sub create_text {
  # given a widget, create text w/specified properties.
  # automatically adds the tag for the current font in effect.
  my ($self, $widget, @args) = @_;
  push @args, ("-font" => $self->current_font()) if $self->current_font();
#  printf STDERR "ct in %s: %s\n", $widget, join ",",@args;
  return $self->last_text_id($widget->create("text", @args));
}

sub write_string {
  my ($self, $string, $x, $y) = @_;
  $self->absolute_move($x, $y) if defined($x) and defined($y);
  my $abs_y = $self->get_y();
  
#  printf STDERR "ws: \"%s\" at %d,%d; font=%s\n", $string, $abs_col, $abs_row, $self->zfont();

  my $is_f3;
  if ($self->zfont() == 3) {
    $self->fatal_error("long buf in write_string w/font 3 on") if length($string) > 1;
    $is_f3 = 1;
  }

  foreach my $list (@widgets) {
    # for each window...
    my $line = $list->[$abs_row];
    my $after = $abs_col + length($string);
    for (my $col=$abs_col; $col < $after; $col++) {
      # see if existing widgets exist at this location
      if (exists $line->{$col}) {
	# they do,
	foreach (@{$line->{$col}}) {
	  # so toss them.
	  $c->delete($_);
	}
	delete $line->{$col};
      }
    }
  }
  
  my $is_reverse = Games::Rezrov::StoryFile::font_mask() & Games::Rezrov::ZConst::STYLE_REVERSE;

  my $id;
  if ($is_f3) {
#    printf STDERR "f3: %d (%s), at %d,%d\n", ord($string), $string, $abs_col, $abs_row;
    print STDERR "reverse f3 char!\n" if $is_reverse;
    if (my $vec_list = $Games::Rezrov::FontVectors::vecs{ord($string)}) {
      # list of vectors describing how to paint this character.
      # These are grid coordinates based on section 16 of the spec, to wit:
      # 
      # 33(!):  76543210   34("):  76543210   35(#):  76543210
      #        0                  0                  0       #
      #        1                  1                  1      #
      #        2  #               2    #             2     #
      #        3 ##               3    ##            3    #
      #        4#######           4#######           4   #
      #        5 ##               5    ##            5  #
      #        6  #               6    #             6 #
      #        7                  7                  7#
      my ($x1, $y1);
      my $x_mult = $self->fixed_font_width() / 7;
#      my $y_mult = $self->line_height() / 8;
      my $y_mult = $self->line_height() / 7;
      my $si;
      foreach my $list (@{$vec_list}) {
	next unless @{$list};
	# a blank char
	my @mapped;
	my ($is_rect, $is_poly);
	if ($list->[0] eq "R") {
	  $si = 1;
	  $is_rect = 1;
	} elsif ($list->[0] eq "P") {
	  $si = 1;
	  $is_poly = 1;
	} else {
	  $si = 0;
	}
	while ($si < @{$list}) {
	  ($x1, $y1) = @{$list}[$si, $si+1];
	  $si += 2;
	  push @mapped, ($abs_x + ((8 - $x1) * $x_mult),
#			 $abs_y + ($y1 * $y_mult));
			 $abs_y + (($y1 - 4) * $y_mult));
	}
#	printf STDERR "  at: %s\n", join ",",@mapped;
	if ($is_rect) {
	  $id = $c->create("rectangle", @mapped,
			   "-fill" => $self->fg(),
			   "-outline" => undef,
			  );
	} elsif ($is_poly) {
	  $id = $c->create("polygon", @mapped,
			   "-fill" => $self->fg(),
			   "-outline" => undef,
			  );
	} else {
	  $id = $c->create("line", @mapped, "-fill" => $self->fg());
	}
	$self->track_widget($id);
      }
    } else {
      printf STDERR "Unhandled font 3 char %d (%s)\n", ord($string), $string;
      $id = $self->create_text($c, $abs_x, $abs_y,
			       "-anchor" => TEXT_ANCHOR,
			       "-text" => "*",
			       "-fill" => $self->fg());
    }
    $abs_x += $self->fixed_font_width();
    $abs_col++;
  } else {
    $id = $self->create_text($c, $abs_x, $abs_y,
			     "-anchor" => TEXT_ANCHOR,
			     "-text" => $string,
			     "-fill" => $is_reverse ? $self->bg() : $self->fg());

    #  printf STDERR "Creating %s at line %d\n", $string, $abs_row;
    $self->track_widget($id);

    my $sw = $self->string_width($string);
    $self->create_reverse($id, $sw + X_BORDER, $is_reverse) if $is_reverse or
      $self->bg() ne $self->default_bg();
    $abs_x += $sw;
    # FIX ME; if using default fonts!
    $abs_col += length($string);
  }

}

sub create_reverse {
  my ($self, $text_id, $width, $is_reverse) = @_;

#  printf STDERR "reversing: %s\n", $c->itemcget($text_id, "-text");

  unless (defined $text_id) {
    $width = $self->get_width() - $abs_x;
    $is_reverse = 0;
  }

  my $abs_y = $self->get_y();
  my $top = $abs_y;
  my $bottom = $abs_y + $self->line_height();

  my $lh2 = $self->line_height() / 2;
  $top = $abs_y - $lh2;
  $bottom = $abs_y + $lh2;

  my $id = $c->create("polygon",
		      $abs_x, $top,
		      $abs_x + $width, $top,
		      $abs_x + $width, $bottom,
		      $abs_x, $bottom,
		      "-fill" => $is_reverse ? $self->fg() : $self->bg(),
		     );
  $c->lower($id);
  $self->track_widget($id);

  $c->lower($id, $text_id) if defined $text_id;
}

sub string_width {
  # return width, in pixels, of the given string
  my $cf = $_[0]->current_font();
  if ($cf) {
    return $w_main->fontMeasure($cf, $_[1]);
  } else {
    my $id = $c->create("text", 0,0, "-text" => $_[1]);
    my ($x1, $y1, $x2, $y2) = $c->bbox($id);
    $c->delete($id);
    printf STDERR "eek! %d\n", $x2 - $x1;
    return ($x2 - $x1);
  }
}

sub newline {
#  print STDERR "nl\n";
#  carp "nl";
  Games::Rezrov::StoryFile::flush();
  if ($_[0]->bg() ne $_[0]->default_bg()) {
    # we're ending the line, and the current background color
    # differs from the default.  Fill out the rest of the line
    # the the current background color.
    print "newline fill\n";
    $_[0]->create_reverse();
  }

  my $line_height = $_[0]->line_height();
  $abs_x = X_BORDER;
  $abs_row++;
  $abs_col = 0;

  if ($abs_row >= $rows) {
    # cursor is at bottom of screen; scroll needed

    my ($id, $line, $ref);
    for (my $win = 0; $win < @widgets; $win++) {
      die "eek, unknown window $win" if 
	$win != Games::Rezrov::ZConst::LOWER_WIN and
	  $win != Games::Rezrov::ZConst::UPPER_WIN;
      my $is_lower = $win == Games::Rezrov::ZConst::LOWER_WIN;
	  
      my $ref = $widgets[$win];
      my @goner_rows;

      for (my $line=0; $line < $#{$ref}; $line++) {
	if ($is_lower) {
	  # lower window:
	  if ($line <= $upper_lines) {
	    # if a lower window line is "underneath" the upper window,
	    # delete its contents.
	    push @goner_rows, $ref->[$line];
	  }
	} else {
	  # upper window:
	  # 
	  # items created in the upper window do not scroll if they are
	  # within the current bounds of the upper window.
	  next if ($line < $upper_lines);
	  @goner_rows = $ref->[$line] if $line == $upper_lines;
	}
	$ref->[$line] = $ref->[$line + 1];
	# scroll line references up one
	
	foreach (values %{$ref->[$line]}) {
	  foreach (@{$_}) {
	    # scroll each widget on the line
	    $c->move($_, 0, - $line_height);
	    if (0 and $c->type($_) eq "text") {
	      printf "now line %d (upr=%d): %s\n",
	      $line,
	      $upper_lines,
	      $c->itemcget($_, "-text");
	    }
	  }	    
	}
      }
      $ref->[$#{$ref}] = {};
      # "blank" last line

#      printf "goners: %d\n", scalar @goner_rows;
      foreach (@goner_rows) {
	# something still funny about this...why ever more than one?
	# [bureaucracy]
	foreach (values %{$_}) {
	  $c->delete($_) foreach @{$_};
#	  print "goner: $_\n", $c->delete($_) foreach @{$_};
	}
      }

    }
    
    $abs_row--;
  }

  Games::Rezrov::StoryFile::register_newline();
  $c->update() if Games::Rezrov::ZOptions::MAXIMUM_SCROLLING();
}

sub write_zchar {
  # write an unbuffered character
  if (STANDARD_COMPLIANT_BUT_EVEN_SLOWER or $_[0]->zfont == 3) {
    # This is compliant with the spec but bogs down mighty quick.
    # Spec says the upper window output must not be buffered;
    # unfortunately this requires we create a widget for every
    # character in the upper window  :P
#    printf STDERR "unbuffered wz: \"%s\"\n", chr($_[1]);
    $_[0]->write_string(chr($_[1]));
  } else { 
    # not compliant with spec but much more efficient.
    # the various other flush() calls in the package are required
    # to make this work.
    $_[0]->SUPER::buffer_zchar($_[1]);
  }
}

sub absolute_move {
  # set absolute column, row position; independent of window!
  my ($self, $col, $row) = @_;

#  printf STDERR "am: %d,%d = %s,%s\n", $col, $row, $abs_x, $self->get_y();

  Games::Rezrov::StoryFile::flush();
  $abs_x = X_BORDER + ($col * $self->fixed_font_width());
  # $abs_x is needed because of variable-width font in lower window
  # makes column-to-pixel translations inconvenient.
  #
  # absolute Y pixel position is calculated dynamically because the
  # same line height is used for both fixed-width and variable fonts.
  #
  # when text items are created, with anchor "w" they are centered
  # vertically at the given coordinates.  So at row 0, text will
  # be drawn from  (- (font_height / 2)) to (font_height / 2).
  #
  # An earlier version just anchored text to the NW which was
  # simpler.  However, reversed text was centered funny if the font 
  # metrics were very different between fixed and variable fonts.

  $abs_row = $row;
  $abs_col = $col;
}

sub get_pixel_position {
  return ($abs_x, $_[0]->get_y());
}

sub get_pixel_geometry {
  return (get_width() - X_BORDER, get_height());
  # HACK
}

sub get_position {
  # with no arguments, return absolute X and Y coordinates (column/row).
  # With an argument, return a sub that will restore the current cursor
  # position.
  my ($self, $sub) = @_;
#  my ($x, $y, $r, $c) = ($abs_x, $abs_y, $abs_row, $abs_col);
  my ($x, $r, $c) = ($abs_x, $abs_row, $abs_col);
  if ($sub) {
    return sub {
#      print STDERR "restoring x=$x y=$y, ar=$r, ac=$c\n";
      $abs_x = $x;
#      $abs_y = $y;
      $abs_row = $r;
      $abs_col = $c;
    };
  } else {
#    printf STDERR "get_position: x=$abs_col y=$abs_row\n";
    return ($abs_col, $abs_row);
#    return (int($abs_x / $self->fixed_font_width()),
#	    int($abs_y / $self->line_height()));
  }
}

sub status_hook {
  # we're drawing the status line manually.
  # might be possible to move this back to story:
  #  - measure string widths to position?
  #  - redraw when columns change?
  my ($self, $location, $right_chunk) = @_;

  my $y = $status_line->height() / 2;
  $status_line->delete($status_line->find("all"));
  my $id = $self->create_text($status_line,
			      X_BORDER, $y,
			      "-anchor" => "w",
			      "-text" => $location,
			      "-fill" => $self->sfg());

  $id = $self->create_text($status_line,
			   200, $y,
			   "-anchor" => "e",
			   "-text" => $right_chunk,
			   "-fill" => $self->sfg());
  my ($x1, $y1, $x2, $y2) = $status_line->bbox($id);
  $status_line->move($id, $c->width() - X_BORDER - $x2, 0);
  # right-justify the text
}

sub cursor_on {
  my ($self, $x) = @_;
#  printf STDERR "cursor_on at (%d, %d), line %d\n", $x, $abs_y, $abs_row;
  $self->cursor_x($x);
  $self->cursor_status(1);
  $self->draw_cursor();
  $self->blink_init();
}

sub draw_cursor {
  my ($self) = @_;
  my $x = $self->cursor_x();
  return unless $x;
  $self->cursor_off();
  # make sure we remove old cursor
  if ($self->cursor_status()) {
    # if "blinking" only draw if on
#    my $top = $abs_y;
#    my $bottom = $abs_y + $self->line_height();

    my $lh2 = $self->line_height() / 2;
    my $abs_y = $self->get_y();
    my $top = $abs_y - $lh2;
    my $bottom = $abs_y + $lh2;

    my $cx = $self->fixed_font_width() * 0.7;
    my $id = $c->create("polygon",
			$x, $top,
			$x + $cx, $top,
			$x + $cx, $bottom,
			$x, $bottom,
			"-fill" => $self->cc());
    #  print "drawing cursor at $x w=$cx t=$top b=$bottom\n";
    $self->cursor_id($id);
  }
}

sub cursor_off {
  $c->delete($_[0]->cursor_id()) if $_[0]->cursor_id();
}

sub get_input {
  my ($self, $max, $single_char, %options) = @_;
  my $buffer = "";
  my $last_id;

  if ($self->listening) {
      $self->update();
      $buffer = $self->recognize_line();
      $self->write_string($buffer);
      $self->newline();
      return $buffer;
  }

  if ($options{"-preloaded"}) {
    # preloaded text in the buffer, but already displayed by the game; ugh.
    #
    # from sect15.html#read --
    #
    #   "Just a tremendous pain in my butt"
    #       -- Andrew Plotkin
    #   "the most unfortunate feature of the Z-machine design"
    #       -- Stefan Jokisch
    #
    my $pre = $options{"-preloaded"};
    my $last = $self->last_text_id();
    my $last_text = $c->itemcget($last, "-text");
    if ($last_text =~ /$pre$/) {
      $last_text =~ s/$pre$//;
      $c->itemconfigure($last, "-text" => $last_text);
      my $width = $self->string_width($pre);
      $last_id = $self->create_text($c,
				    $abs_x - $width,
#				    $abs_y,
				    $self->get_y(),
				    "-anchor" => TEXT_ANCHOR,
				    "-text" => $pre,
				    "-fill" => $self->fg(),
				   );
      $self->track_widget($last_id);
      $buffer = $pre;
      $self->cursor_on($abs_x);
      # start the cursor *after* the preloaded input...
      $abs_x -= $width;
      # ...and redraw the line from *before* it
    } else {
      print STDERR "miserable preload failure in get_input...\n";
    }
  } else {
    $self->cursor_on($abs_x);
  }
  my $done = 0;

  my $callback = sub {
    my $key;
    my $supplied;
    if (ref $_[0]) {
      if ($_[1]) {
	# supplied
	$supplied = 1;
	$key = $_[1];
      } else {
	$key = ord($w_main->XEvent()->A());
      }
    } else {
      # manually passed; documentation for XEvent methods???
      $key = $_[0];
      $supplied = 1;
    }

    $w_main->break() if $key == 9;
    # simple fix for weird tab key handler crash.
    # Duh.  Thanks, Oliver.

    if ($key == Games::Rezrov::ZConst::ASCII_CR or
	$key == Games::Rezrov::ZConst::ASCII_LF) {
      $done = 1;
      $self->cursor_off();
      if ($single_char) {
	$buffer = chr(Games::Rezrov::ZConst::Z_NEWLINE);
      } else {
	$self->newline();
      }
      return;
    } elsif ($key == Games::Rezrov::ZConst::ASCII_DEL or
	     $key == Games::Rezrov::ZConst::ASCII_BS) {
      if ($single_char) {
	$done = 1;
	$buffer = chr(Games::Rezrov::ZConst::Z_DELETE);
      } else {
	$buffer = substr($buffer, 0, length($buffer) - 1) if length $buffer;
      }
    } elsif ($supplied or ($key >= 32 and $key <= 126)) {
      $buffer .= chr($key);
    } else {
      printf STDERR "unhandled key code %d (%s)\n", $key, chr($key) if $key;
#      $buffer .= $key;
#      $buffer .= chr($key);
    }
    if ($single_char) {
      $done = 1;
    } else {
      my $cwin = $self->current_window();
      if ($last_id) {
	$c->delete($last_id);
      }
      $self->cursor_off();
      $last_id = $self->create_text($c,
				    $abs_x,
				    #$abs_y,
				    $self->get_y(),
				    "-anchor" => TEXT_ANCHOR,
				    "-text" => $buffer,
				    "-fill" => $self->fg());
      $self->track_widget($last_id);

      my ($x1, $y1, $x2, $y2) = $c->bbox($last_id);
      # FIX ME: get_width(), etc.
      $self->cursor_on($x2);
      $c->update();
    }
  };
  $self->bind_keys_to($callback);

  while ($done == 0) {
    $c->after(10);
    # to cut down on CPU time a little (does this help?)
    $c->update();
  }
  $self->cursor_off();
  $self->blink_init(1);
  $self->bind_keys_to(sub {});

  return $buffer;
}

sub bind_keys_to {
  my ($self, $callback) = @_;

  $w_main->bind("<Any-KeyPress>" => $callback);
  $w_main->bind("<Any-Down>" => [ $callback => Games::Rezrov::ZConst::Z_DOWN ]);
  $w_main->bind("<Any-Up>" => [ $callback => Games::Rezrov::ZConst::Z_UP ]);
  $w_main->bind("<Any-Left>" => [ $callback => Games::Rezrov::ZConst::Z_LEFT ]);
  $w_main->bind("<Any-Right>" => [ $callback => Games::Rezrov::ZConst::Z_RIGHT ]);

}

sub clear_to_eol {
  foreach my $list (@widgets) {
    # for each window's widgets...
    while (my ($column, $ids) = each %{$list->[$abs_row]}) {
      # find the widgets in the line to be cleared...
      if ($column >= $abs_col) {
	$c->delete($_) foreach (@{$ids});
	# and toss them.
	delete $list->[$abs_row]->{$column};
      }
    }
  }
}

sub set_background_color {
  $c->configure("-bg" => $_[0]->bg());
}

sub clear_screen {
  # clear the entire screen
  $c->delete($c->find("all"));
  @widgets = ();
  widget_setup();
}

sub widget_setup {
  for (my $win=0; $win < 2; $win++) {
    $widgets[$win] = [] unless defined $widgets[$win];
    my $ref = $widgets[$win];
    for (my $row = 0; $row <= $rows; $row++) {
      $ref->[$row] = {} unless defined $ref->[$row];
    }
  }
}

sub set_text_style {
  # arg is the font mask currently in effect; higher-level code
  # manages this
  my ($self, $mask) = @_;
  if ($self->dumb_fonts()) {
    return $self->current_font("");
  } else {
    my $family = ($mask & Games::Rezrov::ZConst::STYLE_FIXED) ?
      FIXED_FAMILY : $self->variable_font_family();
    my $weight = ($mask & Games::Rezrov::ZConst::STYLE_BOLD) ? "bold" : "normal";
    my $slant = ($mask & Games::Rezrov::ZConst::STYLE_ITALIC) ? "italic" : "roman";
    
    my $key = $family . "_" . $weight . "_" . $slant;
    my $fc = $self->font_cache();
    my $font;
    unless ($font = $fc->{$key}) {
#      print "new font\n";
      $font = $w_main->fontCreate("-family" => $family,
				  "-weight" => $weight,
				  "-slant" => $slant,
				  "-size" => $self->font_size());
      $fc->{$key} = $font;
    }
#    printf "%d: %s/%s/%s = %s\n", $mask, $family, $weight, $slant, $font;
    $self->current_font($font);
    return $font;
  }
}

sub groks_font_3 {
  return 1;
}

sub can_change_title {
  return 1;
}

sub can_use_color {
  return 1;
}

sub set_game_title {
  $w_main->title($_[1]);
}

sub cleanup {
  # don't just rely on DESTROY, doesn't work for interrupts
  $w_main->destroy() if $w_main;

  Tk::exit();
  # cleaner; see Tk::exit.pod.  Without, often coredumps.
  # but if we do this, will we miss a die() message elsewhere?
  
  # November 2003: Tk-804.025_beta6 segfaults on exit, WTF?
  # Didn't use to!
}

sub validate_family {
  my ($self, $family) = @_;
  my %families = map {lc($_) => 1} $w_main->fontFamilies();
  if (exists ($families{lc($family)})) {
    return $family;
  } else {
    die sprintf "%s is not a valid font family on your system.  Valid families are: %s\n", $family, join ", ", sort keys %families;
  }
}

sub blink_init {
  my ($self, $cancel) = @_;
  $w_main->afterCancel($self->blink_id()) if $self->blink_id();
  # called whenever cursor is turned on by the app; leave cursor
  # alone for X milliseconds, then blink periodically

  unless ($cancel) {
    my $blink_delay = exists $self->zio_options()->{"blink"} ?
      $self->zio_options()->{"blink"} : DEFAULT_BLINK_DELAY;
    if ($blink_delay) {
      $self->blink_id($w_main->repeat($blink_delay, [ $self => 'cursor_blinker' ]));
    }
  }
}

sub cursor_blinker {
  my ($self) = @_;
  $self->cursor_status(!$self->cursor_status());
  $self->draw_cursor();
  # needs work: if cursor is printed by the app, we should
  # leave it on for awhile...
}

sub split_window {
  $upper_lines = $_[1];
#  print STDERR "ul: $upper_lines\n";
}

sub get_height {
  return $c->height() == 1 ? $c->reqheight() : $c->height();
}

sub get_width {
  return $c->width() == 1 ? $c->reqwidth() : $c->width();
}

sub set_geometry {
  # figure out rows/columns
  my $self = shift;
  my ($cx, $cy) = $self->get_pixel_geometry();
  my $lh = $self->line_height();

  my $old_y = $self->get_y();

  my $old_rows = $rows;
  $rows = int($cy / $lh);
  widget_setup();
  my $columns = int($cx / $self->fixed_font_width());
#  printf STDERR "set_geometry: cx:%d cy:%d lh:%d geometry: %dx%d\n", $cx, $cy, $self->line_height(), $columns, $rows;
#  print STDERR "rows: $rows\n";
  Games::Rezrov::StoryFile::rows($rows);
  Games::Rezrov::StoryFile::columns($columns);

  # if window is now smaller than where cursor was last, scroll the window up and then correct the cursor row
  if ($abs_row >= $rows) {
    my ($save_col, $save_x) = ($abs_col, $abs_x);
    $self->newline for $rows .. $old_rows - 1;
    ($abs_col, $abs_x, $abs_row) = ($save_col, $save_x, $rows - 1);
  }

}

sub biggest_metric {
  my ($self, $f1, $f2, $metric) = @_;
  my $v1 = $w_main->fontMetrics($f1, $metric);
  my $v2 = $w_main->fontMetrics($f2, $metric);
#  print "$metric $v1 $v2\n";
  return $v1 > $v2 ? $v1 : $v2;
}

sub set_font {
#  printf STDERR "set_font: %s win=%s\n", $_[1], $_[0]->current_window();
  return $_[0]->zfont($_[1]);
}

sub track_widget {
#  push @{$widgets[$cwin][$abs_row]->{$abs_col}}, $_[1];
  push @{$widgets[$_[0]->current_window()][$abs_row]->{$abs_col}}, $_[1];
  # an array is required for each location, as layered widgets are
  # used to achieve "inverse video" effect
}

sub column_list {
  # print a list in "column" format
  my ($list, %options) = @_;

  my $longest = 0;
  foreach (@{$list}) {
    my $len = length($_);
    $longest = $len if $len > $longest;
  }
  $longest += 2;
  my $columns = 75 / $longest;
  my $format = ("%-" . $longest . "s") x $columns;
  my @results;
  my @list = @{$list};
  while (@list) {
    push @results, sprintf $format, splice(@list,0,$columns);
  }
  return @results;
}

sub get_y {
  # translate current row into a pixel position
  return $Y_BORDER + ($abs_row * $_[0]->line_height());
}

sub i_am_too_dumb_to_figure_this_out {
    # 9/2004:
    # Pressing the "Tab" key wreaks havoc...once pressed, program 
    # seems to think every subsequent keypress is also a tab key!
    # Maybe some queue needs to be flushed?  I dunno.

    # Anyway, we could:
    #  - instead of binding "Any-KeyPress" we could bind all the individual
    #    keys EXCEPT the tab key.  I think this would work, but there are
    #    an awful lot of symbols to bind and I'm sure I'll forget some.
    #  - unbind the tab key.  Can't get this to work (undef, " ").
    #  - bind the tab key to a null sub.  Works temporarily, but
    #    somehow subsequent Any-Keypress binds seem to override it!
    #  - cop out (this subroutine)

    my $msg = "I hate the tab key in Tk";
    if (1) {
	*Tk::Error = sub {};
	# trash the error handler to keep this quiet.
	die $msg;
	# unless we die() the tab event seems to cause the (queueing?) lockup.
    } else {
	# aborted attempt to save/restore the original Tk handler.
	# seems to work once, but tab key then causes lockups.
	unless ($Games::Rezrov::ZIO_Tk::ORIG_TK_HANDLER) {
	    $Games::Rezrov::ZIO_Tk::ORIG_TK_HANDLER = \&Tk::Error;
	}
	my $restore_sub = sub {
	    no warnings;
	    *Tk::Error = $Games::Rezrov::ZIO_Tk::ORIG_TK_HANDLER;
	    $w_main->bind("<Bogus>" => sub {});
	    # test whether original handler is restored
	};
	$w_main->after(100, $restore_sub);
	*Tk::Error = sub {};
	die $msg;
    }
}

1;
