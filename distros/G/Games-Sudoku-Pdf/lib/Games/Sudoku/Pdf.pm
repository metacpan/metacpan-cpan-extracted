package Games::Sudoku::Pdf;

use strict;
use warnings;

our $VERSION = '0.05';

require 5.006;

use PDF::API2 '2.000';
use PDF::Table '0.9.3';
use Time::Local qw( timelocal );
$| = 1;

###########################################################
my $PDF_API2_IS_OLD  = _make_version_comparable($PDF::API2::VERSION) < 2.042 ? 1 : 0;
my $PDF_TABLE_IS_OLD = _make_version_comparable($PDF::Table::VERSION) < 1.001 ? 1 : 0;
# Both modules had some fairly recent api changes. Switches were tested to work with 
# PDF::API2 2.000 and 2.045
# PDF::Table  0.9.3 and 1.005
###########################################################

sub new {
  my $class = shift;

  bless _init({
    pageFormat      => 'A4',
    puzzlesPerPage  => '2x2',
    pageOrientation => '',
    appendFile      => '',
    extraRegion     => 'n',
    title           => '',
    author          => '',
    subject         => '',
    keywords        => '',

    quiet        => 0,
    textFont     => 'Helvetica-Oblique',
    textEncoding => undef,
    @_,
  }), $class
}

sub add_puzzle {
  # add a table object with the puzzle to the pdf
  my $self = shift;
  my %puzzle = @_;

  my $clues = $puzzle{clues} or return 0;
  my $str_len = length($clues);
  unless ($str_len == 81) {
    warn "parameter 'clues' must be a string of 81 characters (has $str_len)";
    return 0;
  }
  $clues =~ s/[^1-9]/ /g;

  my $jigsaw;
  if ($puzzle{jigsaw}) {
    $str_len = length($puzzle{jigsaw});
    unless ($str_len == 81) {
      warn "parameter 'jigsaw' must be a string of 81 characters (has $str_len)";
      return 0;
    }
    $jigsaw = _create_matrix($puzzle{jigsaw});
  }

  my $x_region  = lc ($puzzle{extraRegion} || $self->{extraRegion} || 'n');

  my $pdf = $self->{pdf};
  my $pos = $self->{nextPosOnPage}++;
  
  my $page;
  if ($pos) {
    # continue on current page
    $page = $self->{page};

  } else {
    # continue on a new page
    $page = $self->{page} = $pdf->page();

    my $pages_in_file;
    if ($PDF_API2_IS_OLD) {
      $page->mediabox(@{$self->{pageSize}});
      $pages_in_file = $pdf->pages();
    } else {
      $page->size($self->{pageSize});
      $pages_in_file = $pdf->page_count();
    }
    $self->{pagesAdded}++;
    print "\nadding page ", $self->{pagesAdded}, "\n" unless $self->{quiet};

    my $text = $page->text();
    $text->font($self->{font}, 12);
    $text->translate($self->{pageWidth} - 12, 24);

    if ($PDF_TABLE_IS_OLD) {
      $text->text_right('page ' . $pages_in_file);
    } else {
      $text->text('page ' . $pages_in_file, align => 'right');
    }
  }

  print "\radding puzzle ", $pos + 1 unless $self->{quiet};
  my $card = _create_matrix($clues);

  my $area_colors; 
  if ($x_region eq 'n' && $jigsaw) {
    $area_colors = $self->_get_area_colors($jigsaw, $self->{puzzleCount} + 1);
  }

  my $cell_props = [];
  for (my $i = 0; $i < @$card; $i++) {
    my $row = $card->[$i];
    for (my $j = 0; $j < @$row; $j++) {
      $cell_props->[$i][$j] = $self->_get_cell_prop($i, $j, $x_region, $jigsaw, $area_colors);
    }
  }

  my $settings = $self->{tableSettings};
  my $factor   = $self->{factor};
  my $pos_data = $self->{positionData}[$pos];
  my ($x, $y) = @$pos_data;

  my $pdftable = new PDF::Table;

  my ($end_page, $pages_spanned, $table_bot_y) = $pdftable->table(
    $pdf,
    $page,
    $card,
    x          => $x,
    ($PDF_TABLE_IS_OLD ? 'start_y' : 'y') => $y,
    cell_props => $cell_props,
    %$settings
  );

  if ($pages_spanned > 1) {
    warn "\aTable overflow!\n";
  }

  my ($content, $cell_size);
  if ($PDF_API2_IS_OLD) {
    $content = $page->gfx();
  } else {
    $content = $page->graphics();
  }
  if ($PDF_TABLE_IS_OLD) {
    $cell_size = $settings->{row_height};
  } else {
    $cell_size = $settings->{min_rh};
  }

  if ($jigsaw) {
    _draw_jigsaw_lines($content, $x, $y, $jigsaw, $settings->{w}, $cell_size, $factor);
  } else {
    _draw_straight_lines($content, $x, $y, $settings->{w}, $cell_size, $factor);
  }
  
  if ($puzzle{bottomLine}) {
    my $text = $end_page->text();
    $text->font($self->{font}, 12 * $factor);
    $text->translate($x, $table_bot_y - 14 * $factor);
    $text->text( $puzzle{bottomLine} );
  }
  if ($self->{nextPosOnPage} == $self->{puzzlesPerPage}) {
    $self->{nextPosOnPage} = 0;
  }
  $self->{puzzleCount}++;
}

sub read_input_file {
  my $self = shift;
  my $file = shift() or die "The file to read from must be given as first argument to read_input_file().\n";
  my %options = @_;
  my $puzzle_numbers = $options{slice};

  my (@puzzle_numbers, $next_puzzle_number);
  if ($puzzle_numbers) {
    @puzzle_numbers = sort {$a <=> $b} @$puzzle_numbers;
    $next_puzzle_number = shift @puzzle_numbers;
  }

  my $puzzles_in_file = 0;
  my $line_handler = $options{lineHandler} || sub {
    my $line = shift;
    $line =~ /^([0-9. ]{81})(?:[\|:,;\t]([1-9]{81})?)?(?:[\|:,;\t]([nNxXhHpPcCdDaAgG])?)?(?:[\|:,;\t](.+)?)?/ or return 0;
    $puzzles_in_file++;

    if ($puzzle_numbers) {
      $puzzles_in_file == $next_puzzle_number or return 0;
    }

    return {
      clues       => $1,
      bottomLine  => ($4 || sprintf "puzzle # %d", ($next_puzzle_number || $puzzles_in_file)),
      extraRegion => $3,
      jigsaw      => $2,
    }
  };

  my $hdl;
  if (ref($file) eq 'GLOB') {
    $hdl = $file;
  } else {
    open $hdl, '<', $file or die "$file: $!\n";
    $file =~ s|.*\/||;
  }

  my $pc = 0;

  while (<$hdl>) {
    chomp();
    my $puzzle = &$line_handler($_) or next;
    $self->add_puzzle(%$puzzle);
    $pc++;
    if ($puzzle_numbers) {
      $next_puzzle_number = shift(@puzzle_numbers) or last;
    }
  }
  if (ref($file) eq 'GLOB') {
    CORE::close $hdl;
    print "\n$pc out of $puzzles_in_file puzzles processed from file handle\n" unless $self->{quiet};

  } else {
    # if we got a handle, the user might want to keep it open
    print "\n$pc out of $puzzles_in_file puzzles processed from file $file\n" unless $self->{quiet};
  }
}

sub page_break {
  my $self = shift;
  $self->{nextPosOnPage} = 0;
}

sub close {
  my $self = shift;

  printf "\n%d pages with %d sudoku added.\n", $self->{pagesAdded}, $self->{puzzleCount} unless $self->{quiet};

  my $file = (shift() || $self->{appendFile}) or die "No filename for pdf output provided during ->close().\n";

  if ($PDF_API2_IS_OLD) {
    $self->{pdf}->info(ModDate => 'D:' . _format_time_w_zone_offset());
    $self->{pdf}->saveas($file);
    $self->{pdf}->release();
  } else {
    $self->{pdf}->modified('D:' . _format_time_w_zone_offset());
    $self->{pdf}->save($file);
    $self->{pdf}->close();
  }
  $self->{pdf} = undef;

  print "$file written\n" unless $self->{quiet};
}

#########################################################################

sub _init {
  my $params = shift;

  $params->{creator} = __PACKAGE__ . ' v. ' . $VERSION;

  my $pdf;
  if ($params->{appendFile}) {
    $pdf = PDF::API2->open($params->{appendFile});
  } else {
    $pdf = PDF::API2->new();
  }

  if ($PDF_API2_IS_OLD) {
    $params->{font} = $pdf->corefont($params->{textFont}, -encode => $params->{textEncoding});
    my %info_hash = ();
    foreach my $kw (qw(creator title author subject keywords)) {
      $info_hash{ucfirst $kw} = $params->{$kw} if $params->{$kw};
    }
    $info_hash{CreationDate} = 'D:' . _format_time_w_zone_offset();
    $pdf->info(%info_hash);

  } else {
    $params->{font} = $pdf->font($params->{textFont}, -encode => $params->{textEncoding});
    $pdf->created('D:' . _format_time_w_zone_offset());
    $params->{creator}  and $pdf->creator($params->{creator});
    $params->{title}    and $pdf->title($params->{title});
    $params->{author}   and $pdf->author($params->{author});
    $params->{subject}  and $pdf->subject($params->{subject});
    $params->{keywords} and $pdf->keywords($params->{keywords});
  }
  $params->{pdf} = $pdf;

  my $media_size = [PDF::API2::Util::page_size($params->{pageFormat})];
  $media_size->[2] && $media_size->[3] or die "could not determine the page size!";

  if ($params->{pageOrientation}) {
    if (($params->{pageOrientation} eq 'landscape' and $media_size->[2] < $media_size->[3])
      || ($params->{pageOrientation} eq 'portrait'  and $media_size->[2] > $media_size->[3])) {
      # rotate media
      my $temp = $media_size->[3];
      $media_size->[3] = $media_size->[2];
      $media_size->[2] = $temp;
    }
  }

  $params->{pageWidth}  = $media_size->[2];
  $params->{pageHeight} = $media_size->[3];
  $params->{pageSize} = $media_size;

  my $puzzles_per_page = $params->{puzzlesPerPage};

  my ($h_puzzles_per_page, $v_puzzles_per_page);

  if ($puzzles_per_page =~ /^(\d+)x(\d+)$/i) {
    $h_puzzles_per_page = $1;
    $v_puzzles_per_page = $2;
    $params->{puzzlesPerPage} = $1 * $2;
  } elsif ($puzzles_per_page eq '1') {
    $h_puzzles_per_page = 1;
    $v_puzzles_per_page = 1;
  } elsif ($puzzles_per_page eq '2') {
    $h_puzzles_per_page = 1;
    $v_puzzles_per_page = 2;
  } elsif ($puzzles_per_page eq '3') {
    $h_puzzles_per_page = 2;
    $v_puzzles_per_page = 1;
  } elsif ($puzzles_per_page eq '4') {
    $h_puzzles_per_page = 2;
    $v_puzzles_per_page = 2;
  } else {
    my $page_ratio = $params->{pageHeight} / $params->{pageWidth};
    my $v_pages = $params->{puzzlesPerPage} / $page_ratio;
    die "You might rather want to specify 'puzzlesPerPage' as a layout, like e.g. '2x3' (WxH)\n";
  }

  _add_table_settings($params);
  _add_table_properties($params);
  _add_table_positions($params, $h_puzzles_per_page, $v_puzzles_per_page);

  $params->{puzzleCount} = 
  $params->{pagesAdded}  = 
  $params->{nextPosOnPage} = 0;

  return $params
}

sub _add_table_settings {
  my ($params) = shift;

  # intialization of parameters for the PDF::Table->table() method
  # some values will get overwritten during init()  !
  my $font = $PDF_API2_IS_OLD ?
      $params->{pdf}->corefont('Helvetica-Bold') : $params->{pdf}->font('Helvetica-Bold');

  $params->{tableSettings} = $PDF_TABLE_IS_OLD ? {
    start_h       => 280, # with 279, the table will be broken up, even when exactly 279 gets returned on a dry run (ink => 0)
    w             => 279,

    next_h        => 500,
    next_y        => 700,

    border         => 1,
    padding_top    => 1.5,
    padding_bottom => 7.5,
    row_height     => 31,
    font           => $font,
    font_size      => 22,
    column_props  => [
      (({min_w => 31, justify => 'center'}) x 9)
    ],

  } : {
    h             => 280, # with 279, the table will be broken up, even when exactly 279 gets returned on a dry run (ink => 0)
    w             => 279,

    next_h        => 500,
    next_y        => 700,

    border_w       => 1,
    # following 2 values should omit the table's outer borders,  but don't work
    #h_border_w     => 0,
    #v_border_w     => 0,
    padding        => 0,
    padding_top    => 1.5,
    min_rh         => 31,
    font           => $font,
    font_size      => 22,
    # global size and justify came stepwise in recent versions 
    #size           => join(' ', ((31) x 9)),
    #justify        => 'center',
    column_props  => [
      (({min_w => 31, justify => 'center'}) x 9)
    ],
  };
}

sub _add_table_positions{
  my ($params, $h_puzzles_per_page, $v_puzzles_per_page) = @_;

  my $trim = 12;
  my $trim_top = 30;
  my $trim_bottom = 35;
  my $h_spacing = 12;
  # the preset values estimate 2x2 puzzles, calculate a min vertical space by scaling fontsize + padding
  my $v_spacing = 2 * ($params->{tableSettings}{font_size} + 3) / $v_puzzles_per_page;
  my $h_size = ($params->{pageWidth} - 2 * $trim - (($h_puzzles_per_page - 1) * $h_spacing)) / $h_puzzles_per_page;
  my $v_size = (($params->{pageHeight} - ($trim_top + $trim_bottom)) - ($v_puzzles_per_page * $v_spacing)) / $v_puzzles_per_page;

  my ($table_size, $cell_size);
  if ($h_size < $v_size) {
    $cell_size = int $h_size / 9;
  } else {
    $cell_size = int $v_size / 9;
  }
  $table_size = $cell_size * 9;

  $h_spacing = $h_puzzles_per_page > 1 ? 
    int ($params->{pageWidth} - 2 * $trim - ($h_puzzles_per_page * $table_size)) / ($h_puzzles_per_page - 1)
    : 0;
  $v_spacing = $v_puzzles_per_page > 1 ?
    int (($params->{pageHeight} - ($trim_top + $trim_bottom)) - ($v_puzzles_per_page * $table_size)) / ($v_puzzles_per_page)
    : 0;

  my @positions = ();
  my $x = $trim;
  my $y = $params->{pageHeight} - $trim_top;
  for (my $r = 0; $r < $v_puzzles_per_page; $r++) {
    $x = $trim;
    for (my $c = 0; $c < $h_puzzles_per_page; $c++) {
      push @positions, [
        $x, $y, 
      ];
      $x += ($table_size + $h_spacing);
    }
    $y -= ($table_size + $v_spacing);
  }
  $params->{positionData} = \@positions;
  $params->{factor} = _scale_table($params->{tableSettings}, $table_size, $cell_size);
  
  return $params
}

sub _scale_table {
  my ($settings, $table_size, $cell_size) = @_;

  my $factor = $table_size / $settings->{w};
  return 1 if $factor == 1;

  if ($PDF_TABLE_IS_OLD) {
    $settings->{start_h}         = $table_size + 1;
    $settings->{w}               = $table_size;
    $settings->{row_height}      = $cell_size;
    $settings->{border}         *= $factor;
    $settings->{font_size}      *= $factor;
    $settings->{padding_top}    *= $factor if $settings->{padding_top};
    $settings->{padding_bottom} *= $factor if $settings->{padding_bottom};
    $settings->{column_props}    = [
      (({min_w => $cell_size, justify => 'center'}) x 9)
    ],

  } else {
    $settings->{h}            = $table_size + 1;
    $settings->{w}            = $table_size;
    $settings->{min_rh}       = $cell_size;
    $settings->{border_w}    *= $factor;
    $settings->{font_size}   *= $factor;
    $settings->{padding_top} *= $factor if $settings->{padding_top};
    $settings->{column_props}    = [
      (({min_w => $cell_size, justify => 'center'}) x 9)
    ],
  }
  return $factor
}

sub _add_table_properties {
  my $params = shift;

  $params->{patternProp} = {
    # color of extraRegion
    background_color => '#6666ff',
  };

  $params->{greyProp} = {
    # color of odd 3x3 boxes
    # '#e6e6e6' is to light, almost invisible in print!
    background_color => '#d0d0d0',
  };

  $params->{whiteProp} = {
    # default cell color (undefined would be transparent)
    background_color => '#ffffff',
  };

  $params->{colorPattern} = {
    # colors used in c-variant
    '00' => '#ff6666', # red
    '01' => '#808080', # dark grey
    '02' => '#66ff66', # green
    '10' => '#c0c0c0', # light grey
    '11' => '#66ffff', # light blue
    '12' => '#b266ff', # purple
    '20' => '#ffff66', # yellow
    '21' => '#ff66ff', # magenta
    '22' => '#ffffff', # white
  };

  $params->{areaColors} = {
    # color sets used in jigsaw puzzles without extraRegion
    '3' => [
      '#ffab99', # red
      '#99ff99', # green
      '#99bcff', # light blue
    ],
    '4' => [
      '#fff199', # yellow
      '#99ff99', # green
      '#99bcff', # light blue
      '#ffab99', # red
    ],
  };

  return $params
}

#########################################################################

sub _create_matrix {
  # put the string of 81 chars into a 9x9 array
  my $line = shift() or return undef;

  my @numbers = split //, $line;

  my @matrix = ();
  while (@numbers) {
    push @matrix, [ splice @numbers, 0, 9 ];
  }

  \@matrix
}

sub _is_pattern_area {
  my $self = shift;
  my ($r, $c, $v) = @_;

  if ($v eq 'n') {
    # standard
    return 0;
  } elsif ($v eq 'x') {
    # x-sudoku
    return (($r == $c) || ($r == 8 - $c)) ? $self->{patternProp} : 0;
  } elsif ($v eq 'h') {
    # hyper
    return ($r=~/^[123567]$/ && $c=~/^[123567]$/) ? $self->{patternProp} : 0;
  } elsif ($v eq 'p') {
    # percent
    return (($r == 8 - $c) || ($r=~/^[123]$/ && $c=~/^[123]$/) || ($r=~/^[567]$/ && $c=~/^[567]$/)) ? $self->{patternProp} : 0;
  } elsif ($v eq 'd') {
    # center dot
    return ($r=~/^[147]$/ && $c=~/^[147]$/) ? $self->{patternProp} : 0;
  } elsif ($v eq 'a') {
    # asterisk
    my $cmp = $r.$c;
    return ($cmp =~ /^(14|22|26|41|44|47|62|66|74)$/) ? $self->{patternProp} : 0;
  } elsif ($v eq 'g') {
    # girandola
    my $cmp = $r.$c;
    return ($cmp =~ /^(00|08|14|41|44|47|74|80|88)$/) ? $self->{patternProp} : 0;
  } elsif ($v eq 'c') {
    # color
    return {
      background_color => $self->{colorPattern}{$r%3 . $c%3}
    };
  } else {
    die "don't know about pattern '$v'";
  }
}

sub _is_grey_block {
  my ($r, $c) = @_;
  return (($r>2 && $r<6) xor ($c>2 && $c<6));
}

sub _get_cell_prop {
  my $self = shift;
  my ($i, $j, $variant, $grid, $area_colors) = @_;

  if (my $prop = $self->_is_pattern_area($i, $j, $variant)) {
    return $prop;

  } elsif (! $grid) {
    return _is_grey_block($i, $j) ? $self->{greyProp} : $self->{whiteProp};

  } elsif ($variant eq 'n') {
    return {
      background_color => $area_colors->{$grid->[$i][$j]},
    };
  }

  return $self->{whiteProp};
}

# determining the colors for jigsaw lines puzzles is anything but trivial,
# at least if we want to use as little colors as possible.
sub _get_area_colors {
  my $self = shift;
  my $areas = shift() or return undef;
  my $puzzle_number = shift();

  my $adjoins_with = {};
  my $size = @$areas;
  for (my $i = 0; $i < $size; $i++) {
    for (my $j = 0; $j < $size; $j++) {
      my $a = $areas->[$i][$j];

      if ($j < $size - 1) {
        my $r = $areas->[$i][$j+1];
        if ($r != $a) {
          $adjoins_with->{$a}{$r} = 1;
          $adjoins_with->{$r}{$a} = 1;
        }
      }

      if ($i < $size - 1) {
        my $d = $areas->[$i+1][$j];
        if ($d != $a) {
          $adjoins_with->{$a}{$d} = 1;
          $adjoins_with->{$d}{$a} = 1;
        }
      }
    }
  }

  my $area_to_color = {};
  my $assigned_colors = {};
  my $max_color = 0;
  my $most_neighbours = 0;
  # sort areas by number of neighbours, descending
  # secondary sort by area index, else  don't use the minimal number of colors
  foreach my $area (sort {
       scalar(keys %{$adjoins_with->{$b}}) <=> scalar(keys %{$adjoins_with->{$a}})
       || $a <=> $b 
     } keys %$adjoins_with) {
    $most_neighbours ||= $area;

    foreach my $color (0 .. 3) {
      my $conflict = 0;
      foreach my $neighbour (keys %{$adjoins_with->{$area}}) {
        my $c = $area_to_color->{$neighbour};
        if (defined($c) && $c == $color) {
          $conflict = 1;
          last;
        }
      }
      unless ($conflict) {
        $area_to_color->{$area} = $color;
        if ($color > $max_color) {
          $max_color = $color;
        }
        last;
      }
    }
  }
  my $colors_used = $max_color + 1;
  if ($colors_used == 2) {
    warn "[puzzle #$puzzle_number] only 2 colors needed: replacing color of area $most_neighbours with 3rd color\n";
    $area_to_color->{$most_neighbours} = 2;
    $colors_used = 3;

  } elsif ($colors_used != 3 && $colors_used != 4) {
    die "\nfatal: an unprepared number $colors_used of colors are used:\n";
  }

  foreach my $a (keys %$area_to_color) {
    $area_to_color->{$a} = $self->{areaColors}{$colors_used}[$area_to_color->{$a}];
  }

  return $area_to_color;
}
  
sub _draw_straight_lines {
  my ($content, $x, $y, , $table_size, $cell_size, $factor) = @_;

  if ($PDF_API2_IS_OLD) {
    $content->linewidth(3 * $factor);
    $content->linecap(2);
  } else {
    $content->line_width(3 * $factor);
    $content->line_cap(2);
  }

  # 4 vertical lines
  $content->move($x, $y);
  $content->vline($y-$table_size);
  $content->move($x+($cell_size*3), $y);
  $content->vline($y-$table_size);
  $content->move($x+($cell_size*6), $y);
  $content->vline($y-$table_size);
  $content->move($x+$table_size, $y);
  $content->vline($y-$table_size);

  # 4 horizontal lines
  $content->move($x, $y);
  $content->hline($x+$table_size);
  $content->move($x, $y-($cell_size*3));
  $content->hline($x+$table_size);
  $content->move($x, $y-($cell_size*6));
  $content->hline($x+$table_size);
  $content->move($x, $y-$table_size);
  $content->hline($x+$table_size);

  $content->stroke();
}

sub _draw_jigsaw_lines {
  my ($content, $x, $y, $grid, $table_size, $cell_size, $factor) = @_;

  if ($PDF_API2_IS_OLD) {
    $content->linewidth(3 * $factor);
    $content->linecap(2);
  } else {
    $content->line_width(3 * $factor);
    $content->line_cap(2);
  }

  # outer lines
  $content->move($x, $y);
  $content->vline($y-$table_size);
  $content->move($x+$table_size, $y);
  $content->vline($y-$table_size);
  $content->move($x, $y);
  $content->hline($x+$table_size);
  $content->move($x, $y-$table_size);
  $content->hline($x+$table_size);

  $content->stroke();

  # jigsaw lines
  if ($PDF_API2_IS_OLD) {
    $content->linecap(0);
  } else {
    $content->line_cap(0);
  }

  for (my $i = 0; $i < 9; $i++) {
    my $my = $y - ($i*$cell_size);
    for (my $j = 0; $j < 9; $j++) {
      my $mx = $x + ($j*$cell_size);
      my $this_area = $grid->[$i][$j];

      if ($i < 8) {
        if ($grid->[$i+1][$j] != $this_area) {
          $content->move($mx, $my-$cell_size);
          $content->hline($mx+$cell_size);
        }
      }

      if ($j < 8) {
        if ($grid->[$i][$j+1] != $this_area) {
          $content->move($mx+$cell_size, $my);
          $content->vline($my-$cell_size);
        }
      }
    }
  }

  $content->stroke();
}

sub _format_time_w_zone_offset {
  my $epoch = shift() || time();

  my $offset_sec = $epoch - timelocal( gmtime $epoch );
  my $sign = ($offset_sec =~ s/^-//) ? '-' : ($offset_sec > 0 ) ? '+' : 'Z';

  my $offset = '';
  if  ($offset_sec > 0) {
    my $offset_hrs = int $offset_sec / 3600;
    my $offset_min = int( ($offset_sec % 3600) / 60);
    $offset = sprintf '%02d\'%02d', $offset_hrs, $offset_min;
    # Time offset ought to be: [-+Z] (hh') (mm')
    # API2 until v2.041 gave a correct format example in the pod, but no validation took place.
    # From v2.042 - 2.044 introduced a (faulty) date validation which _required_ a _leading_ 
    # apostrophe with offset minutes but croaked on the trailing offset mm' apostrophe.
    # Now both apostrophes are optional since v2.045.
    if ($PDF::API2::VERSION < 2.042 || $PDF::API2::VERSION > 2.044) {
      # (no validation || 'tolerant' validation) => pass correct format
      $offset .= "'";
    }
  } # or else just return Z(ulu), to avoid any confusion

  my @lt = localtime($epoch);
  return sprintf('%d%02d%02d%02d%02d%02d%s%s', 
    $lt[5]+1900, $lt[4]+1, @lt[3,2,1,0], $sign, $offset)
}

sub _make_version_comparable {
  my $v = shift;
  $v =~ s/^(v?[0-9]+(?:\.[0-9]+)).*$/$1/;
  if ($v =~ s/^v//) {
    $v =~ s/^\./\.0/;
  }
  return $v
}

1;

=encoding UTF-8

=head1 NAME

Games::Sudoku::Pdf - Produce pdf files from your digital Sudoku sources or collections. 

=head1 DESCRIPTION

An easy way to create pdf files of 9x9 Sudoku puzzles from various sources, which you can give to your friends or print out and pencil solve at the beach.
Sixteen variants of 9x9 Sudoku are supported. (See the output of scripts/example.pl.)
Just specify how many puzzles (columns x rows) to arrange per page and the positioning and scaling will be adapted automatically.

=head1 SYNOPSIS

  my $writer = Games::Sudoku::Pdf->new(%options);

  $writer->add_puzzle(
    clues      => '.9.46.....85...4.7..........3.2.8.4...9...1...6.1.4.5..........3.4...92.....49.8.', 
    jigsaw     => '111222333141122333141226663441522563745555563745885966744488969777889969777888999', 
    extraRegion => 'g',
    bottomLine  => 'jigsaw #5 from Daisy (very hard!)',
  );

  $writer->read_input_file('./all-17-clues-sudoku.txt', slice => [5..9, 7..25]);

  $writer->close();

  >sudoku2pdf my_sudokus.txt > my_sudokus.pdf

=head1 METHODS

=head2 new()

  Games::Sudoku::Pdf->new( %options )

Returns the writer object. The following options are available:

=head3 pageFormat default 'A4'

Find possible values in L<PDF::API2::Resource::PaperSizes>.

=head3 pageOrientation

Possible values are 'portrait' or 'landscape'.
Default is the resp. format's definiton in L<PDF::API2::Resource::PaperSizes>.

=head3 puzzlesPerPage default 4 (resolved to '2x2')

Specifies the number of Sudoku per page, their size and positions.
You will probably want to give the WxH notation.
If you specify e.g. '1x5', 5 small Sudoku will be placed at the left side, leaving place for your manual notes to the right.
Once you specify 2 or more columns, they will get equally distributed from left to right.

=head3 appendFile

You can specify path and name of any existing pdf file, to which the new pages shall be appended.

=head3 title, author, subject, keywords 

Any of these four optional values will be written to the pdf meta data fields.

=head3 extraRegion default none

For Sudoku sporting an 'extra region' (X-, Hyper-, Percent- ...) this parameter can be given globally here,
or for each puzzle L<added|/"add_puzzle()">. 
The following variants are recognized:

=over 4

=item x X-Sudoku

=item h Hyper Sudoku

=item p Percent Sudoku

=item c Color Sudoku

Just one fixed version is currently possible (colors 1-9):

  +-------------------+
  | 1 2 3 1 2 3 1 2 3 |
  | 4 5 6 4 5 6 4 5 6 |
  | 7 8 9 7 8 9 7 8 9 |
  | 1 2 3 1 2 3 1 2 3 |
  | 4 5 6 4 5 6 4 5 6 |
  | 7 8 9 7 8 9 7 8 9 |
  | 1 2 3 1 2 3 1 2 3 |
  | 4 5 6 4 5 6 4 5 6 |
  | 7 8 9 7 8 9 7 8 9 |
  +-------------------+

=item d Center Dot Sudoku

=item a Asterisk Sudoku

=item g Girandola Sudoku

=back

For an overview take a look at the script and output of L<scripts/example.pl>.

=head2 add_puzzle()

  $writer->add_puzzle(%options)

Adds the next puzzle to the pdf. The options are:

=head3 clues mandatory

A string of 81 characters, the common Sudoku exchange format. Given clues as numbers 1-9, empty cells denoted by C<.>, C<0>, C<space> or any non-digit.

=head3 jigsaw optional

Instead of regular 3x3 boxes with straight sides, the puzzle can be broken up into irregular shapes.
These may be provided by a string of 81 characters with the numbers 1-9 whose positions form 9 contiguous areas in the puzzle matrix.
Refer to L<example.pl>.

=head3 extraRegion default none

A single letter of xhpcdag, as described in L<extraRegion|/"extraRegion default none"> above.

=head3 bottomLine default none

A short string which will be put beneath the puzzle.
You may want to provide the puzzle's source, its estimated difficulty, a number or anything else.
Because we use the pdf corefonts, only latin1 is supported.

It is up to you and your Sudoku sources, that the given clues together with the other optional parameters provided 
defines a proper puzzle with exactly one solution.

=head2 read_input_file()

  $writer->read_input_file($input_file, %options)

A convenience method to slurp an entire text file with your puzzle collection.
The $input_file may be a file name or an open handle. The %options are:

=head3 slice optional

An array reference that contains the numbers of the puzzle lines that will be processed.
Only lines starting with a string of 81 givens are counted. Or, if you provided a L<lineHandler|/"lineHandler optional">, for which the handler returned a hashref.

=head3 lineHandler optional

A reference to your custom subroutine thats given the chomp-ed line and has to return a hashref that will be fed to L<add_puzzle()|/"add_puzzle()">.
If the return value is false, the line is skipped.

If no custom line handler is provided, lines are expected to follow the format

  <81 char givens> [<delim> [<81 char jigsaw>] [<delim> [<1 char extraRegion>] [<delim> [<bottomLine>]]]]

Delimiters can be C<'|', ':', ',', ';', E<lt>tabE<gt>>.
For any standard Sudoku, the givens alone are sufficient.
See the 4 parameter's descriptions to L<add_puzzle()|/"add_puzzle()">.

Note: If this somewhat limited input format does not suit you, take a look at the commandline script L<sudoku2pdf|/"sudoku2pdf">.

=head2 page_break()

  $writer->page_break()

Continue adding puzzles on a new page with otherwise unchanged settings. 
There will be B<no> empty pages inserted by repeated calls.

=head2 close()

  $writer->close( $output_file )

Writes the pdf to file and frees memory.
The $output_file may be omitted if an L<'appendFile'|/"appendFile"> was specified in L<new()|/"new()"> and if that file is supposed to be replaced.
B<Any existing files will get overwritten without a warning!>

=head1 SCRIPTS

=head2 sudoku2pdf

After installation of Games::Sudoku::Pdf this command line script should be in your path.
Flexible input options are available. Invoke C<E<gt>sudoku2pdf -h> for details.

=head1 DEPENDENCIES

=over 4

=item * L<PDF::API2>

=item * L<PDF::Table>

=item * L<Time::Local>

=back

=head1 SEE ALSO

L<Games::Sudoku::PatternSolver::Generator>, L<Games::Sudoku::Html>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2024 by Steffen Heinrich

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
