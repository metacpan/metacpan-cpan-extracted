package Gtk2::Hexgrid;

our $VERSION = '0.06';

use warnings;
use strict;
use Carp;
use Gtk2;
use Cairo;
use POSIX qw(ceil floor);
use Gtk2::Hexgrid::Tile;
use base 'Gtk2::EventBox';

sub new{
    my $class = shift;
    my ($w,$h, $lineSize, $border, $evenRowsFirst, $evenRowsLast, $r,$g,$b) = @_;
    
    ($r,$g,$b) = (0,.4,0) unless defined($r) and defined($g) and defined($b);
    
    my $self= new Gtk2::EventBox->new;
    $self->{images} = {}; #cache for sprites
    $self->{w} = $w;
    $self->{h} = $h;
    $self->{linesize} = $lineSize;
    $self->{border} = $border;
    $self->{evenFirst} = $evenRowsFirst != 0; #these may need to be 1 or 0
    $self->{evenLast} = $evenRowsLast != 0;
    $self->{gameBoard} = Gtk2::DrawingArea->new;
    my @dimensions = _calc_board_dimensions($w, $h, $lineSize, 
                        $border, $evenRowsFirst, $evenRowsLast);
    $self->{gameBoard}->size (@dimensions);
    $self->add($self->{gameBoard});
    
    $self->{gameBoard}->signal_connect ("expose_event" => \&_expose_event, $self);
    $self->signal_connect ("button_press_event" => \&_button_press_cb, $self);
    #init tiles
    for my $row(0..$h){
        my @thisRow;
        for my $col(0..$w){
            next unless tile_exists($self, $col, $row);
            my $tile= new Gtk2::Hexgrid::Tile($self, $col, $row, $r,$g,$b);
            push @thisRow, $tile; #what data should this be?
        }
        push @{$self->{tiles}}, \@thisRow;
    }
    
    bless $self, $class;
    return $self;
}

sub redraw_board{
    my $self = shift;
    $self->{gameBoard}->queue_draw;
}

sub get_cairo_context{
    my $self = shift;
    my $drawable= $self->{gameBoard}->window;
    return Gtk2::Gdk::Cairo::Context->create ($drawable);
}

#(in pixels)
sub _calc_board_dimensions{
    my ($w,$h, $ls, $border, $evenFirst, $evenLast) = @_;
    my $pixelsW = $ls*3*($w-1) + $ls*2;
    $pixelsW += $ls*1.5 unless $evenFirst;
    $pixelsW += $ls*1.5 unless $evenLast;
    my $pixelsH = $ls*(sqrt(3)/2)*($h+1);
    $pixelsW += $border*2;
    $pixelsH += $border*2;
    return ($pixelsW, $pixelsH);
}

# direction: -1 is n, 0 ne, 1 se, 2 s, 3 sw, 4 nw, .....
# direction wraps around.
sub next_tile_by_direction{
    my ($self, $col,$row, $dir) = @_;
    croak 'usage: $hexgrid->next_tile_by_direction($col, $row, $direction)'
        unless (ref($self) && defined($col) && defined($row) && defined($dir));
    $dir %= 6;
    return $self->get_tile($col, $row+2) if $dir==2;
    return $self->get_tile($col, $row-2) if $dir==5;
    my $otherCol = ($row&1 ^ $self->{evenFirst}) ? $col-1 : $col+1;
    if ($otherCol > $col){
        return $self->get_tile($col+1, $row-1) if $dir==0;
        return $self->get_tile($col+1, $row+1) if $dir==1;
        return $self->get_tile($col, $row+1) if $dir==3;
        return $self->get_tile($col, $row-1) if $dir==4;
        croak "why did I die";
    }
    return $self->get_tile($col, $row-1) if $dir==0;
    return $self->get_tile($col, $row+1) if $dir==1;
    return $self->get_tile($col-1, $row+1) if $dir==3;
    return $self->get_tile($col-1, $row-1) if $dir==4;
    croak "you've killed me!";
}

sub next_col_row_by_direction{
    my ($self, $col,$row, $dir) = @_;
    croak 'usage: $hexgrid->next_col_row_by_direction($col, $row, $direction)'
        unless (ref($self) && defined($col) && defined($row) && defined($dir));
    $dir %= 6;
    return ($col, $row+2) if $dir==2;
    return ($col, $row-2) if $dir==5;
    my $otherCol = ($row&1 ^ $self->{evenFirst}) ? $col-1 : $col+1;
    if ($otherCol > $col){
        return ($col+1, $row-1) if $dir==0;
        return ($col+1, $row+1) if $dir==1;
        return ($col, $row+1) if $dir==3;
        return ($col, $row-1) if $dir==4;
        croak "why did I die";
    }
    return ($col, $row-1) if $dir==0;
    return ($col, $row+1) if $dir==1;
    return ($col-1, $row+1) if $dir==3;
    return ($col-1, $row-1) if $dir==4;
    croak "you've killed me!";
}

sub get_adjacent_tile_coordinates{
    my ($self, $col,$row) = @_;
    croak 'usage: $hexgrid->get_adjacent_tile_coordinates($col, $row)'
        unless (ref($self) && defined($col) && defined($row));
    my @tiles;
    push @tiles, [$col, $row-2];
    push @tiles, [$col, $row+2];
    push @tiles, [$col, $row-1];
    push @tiles, [$col, $row+1];
    my $otherCol = ($row&1 ^ $self->{evenFirst}) ? $col-1 : $col+1;
    push @tiles, [$otherCol, $row-1];
    push @tiles, [$otherCol, $row+1];
    return @tiles;
}

sub get_adjacent_tiles{
    my ($self, $col,$row) = @_;
    croak 'usage: $hexgrid->get_adjacent_tiles($col, $row)'
        unless (ref($self) && defined($col) && defined($row));
    my @co = $self->get_adjacent_tile_coordinates($col,$row);
    my @tiles;
    for my $c (@co){
        my $tile = $self->get_tile($c->[0], $c->[1]);
        push @tiles, $tile if $tile;
    }
    return @tiles;
}

sub tiles_adjacent{
    my ($self, $col1,$row1,$col2,$row2) = @_;
    croak 'usage: $hexgrid->tiles_adjacent($col1,$row1,$col2,$row2)' 
        unless (ref($self) && defined($row1) && defined($row2) && defined($col1) && defined($col2));
    my @tiles = $self->get_adjacent_tile_coordinates($col1,$row1);
    for my $T (@tiles){
        if ($T->[0]==$col2 && $T->[1]==$row2){
            return 1
        }
    }
    return 0
}

#imagine 6 spokes extending outward at the corners, and looping back around
#dealing with coordinates rather than tiles, as it could run into undefined space and back
sub get_ring{
    my ($self, $col, $row, $radius) = @_;
    return $self->get_tile($col, $row) if $radius==0;
    my @corners = map{[$col, $row]} (0..5);
    my @tiles_co;
    #for my $ring (1..$radius){
    for my $dir(0..5){
        for (1..$radius){
            my @co = $self->next_col_row_by_direction(@{$corners[$dir]}[0,1], $dir);
            $corners[$dir] = \@co;
        }
        my @tmp = @{$corners[$dir]};
        for (1..$radius){
            @tmp = $self->next_col_row_by_direction(@tmp, $dir+2);
            push @tiles_co, [@tmp];
        }
    }
    my @tiles = grep {defined $_} map {$self->get_tile(@$_)} @tiles_co;
    #map {print STDERR join (',',@$_), "\n"} @tiles_co;
    return @tiles;
}
sub get_tiles_in_range{
    my ($self, $col, $row, $range) = @_;
    my @tiles;
    for my $radius (0..$range){
        push @tiles, $self->get_ring($col, $row, $radius);
    }
    return @tiles;
}

sub get_tile_center{
    my ($self, $col, $row) = @_;
    croak 'usage: $hexgrid->get_tile_center($col,$row)' 
        unless (ref($self) && defined($col) && defined($row));
    my $ls = $self->{linesize};
    my $evenFirst = $self->{evenFirst};
    my $evenLast = $self->{evenLast};
    #center of tile at upper left corner
    my $x0 = $ls;
    my $y0 = $ls * sqrt(3)/2;
    my $oddRow = $row&1;
    if(($oddRow and $evenFirst) or not ($oddRow or $evenFirst)){
        $x0 += $ls*1.5;
    }
    $x0 += $ls*$col*3;
    $y0 += $ls*$row*sqrt(3)/2;
    $x0 += $self->{border};
    $y0 += $self->{border};
    return ($x0,$y0);
}

sub _distBetweenRows{
    my $ls=shift;
    ($ls *sqrt(3)/2)
}
sub _distBetweenCols{ #more like horizontal distance between diagonal lines
    my $ls=shift;
    ($ls *1.5)
}

sub _dist{
    sqrt(($_[0]-$_[2])**2 + ($_[1]-$_[3])**2)
}

sub get_col_row_from_XY{
    my ($self, $x, $y) = @_;
    croak 'usage: $hexgrid->get_col_row_from_XY($x,$y)' 
        unless (ref($self) && defined($x) && defined($y));
    my $ls = $self->{linesize};
    my ($bestDist,$bestCol,$bestRow) = ($ls*50,-8,-8); #values to be replaced
    my ($startRow,$startCol) = (-2,-1);
    my $endRow = $self->{h} + 1;
    my $endCol = $self->{w};
    for my $row ($startRow..$endRow){
        for my $col ($startCol..$endCol){
            my ($centerX,$centerY) = $self->get_tile_center($col,$row);
            my $dist = _dist($centerX,$centerY, $x, $y);
            if ($dist < $bestDist){
                ($bestDist,$bestCol,$bestRow) = ($dist, $col,$row);
            }
        }
    }
    return ($bestCol,$bestRow)
}

sub get_tile_from_XY{
    my ($self, $x, $y) = @_;
    croak 'usage: $hexgrid->get_tile_from_XY($x,$y)' 
        unless (ref($self) && defined($x) && defined($y));
    my ($col,$row) = $self->get_col_row_from_XY($x,$y);
    my $tile = $self->get_tile($col,$row);
    return $tile;
}
#this func translates mouseclicks to another coordinate system.
#consider the area beside each diagonal line on the grid to be a chunk.
#this figures out what chunk x and y belong to, and then what side of the diag it is on
# fix this if you need to get nonexistant tile coordinates on a potentially infinite plane
sub _get_col_row_from_XY_fast_broken{
    my ($self, $x, $y) = @_;
    my $ls = $self->{linesize};
    my ($c0x, $c0y) = $self->get_tile_center(0,0);
    my $relativeY = ($y - $c0y); #y dist from tile 0,0
    my $relativeX = ($x - $c0x); #x dist from tile 0,0
    unless ($self->{evenFirst}){ #rounded corner--origin is 1 chunk to left
        $relativeX += distBetweenCols($ls);
    }
    # the row could be either $vert or $vert+1
    # column could be either $horiz/2 or ($horiz+1)/2
    # use pythagorian to find out the truth
    my $vert = floor ($relativeY / distBetweenRows($ls));
    my $horiz = ($relativeX / distBetweenCols($ls));
    my ($x1,$x2,$y1,$y2);
    ($x1, $x2) = (floor($horiz/2) , floor(($horiz+1)/2));
    if($self->{evenFirst} != ($vert&2)){ #right tile lower than left
        ($y1,$y2) = ($vert, $vert+1);
    }
    else{ #right tile is higher
        ($y1,$y2) = ($vert+1, $vert);
    }
    my @center1 = $self->get_tile_center($x1,$y1);
    my @center2 = $self->get_tile_center($x2,$y2);
    my $dist1 = dist(@center1, $x, $y);
    my $dist2 = dist(@center2, $x, $y);
    if ($dist1<$dist2){
        return ($x1,$y1)
    }
    return ($x2,$y2)
}

sub tile_exists{
    my ($self, $col,$row) = @_;
    croak 'usage: $hexgrid->tile_exists($col,$row)' 
        unless (ref($self) && defined($col) && defined($row));
    my $evenFirst = $self->{evenFirst};
    my $evenLast = $self->{evenLast};
    return 0 if $row <0;
    return 0 if $col <0;
    return 0 if $row >= $self->{h}; # obvious case
    my $oddRow = $row&1;
    unless ($oddRow){ #even rows are always of size $hexgrid->{w}
        return 0 if $col >= $self->{w};
        return 1;
    }#only odd rows left
    if ($evenFirst != $evenLast){ #odd rows = even rows
        return 0 if $col >= $self->{w};
    }
    elsif ($evenFirst == 0){ ##odd rows = even rows+1
        return 0 if $col >= $self->{w} +1
    }
    elsif ($evenFirst == 1){ ##odd rows = even rows-1
        return 0 if $col >= $self->{w} -1
    }
    return 1;
}

sub get_all_tiles{
    my $self = shift;
    croak 'usage: $hexgrid->get_all_tiles;' 
        unless ref($self);
    my ($w,$h) = @{$self}{'w','h'};
    my @tiles;
    for my $row (0..$h-1){
        for my $col (0..$w){
            if ($self->tile_exists($col,$row)){
                my $tile = $self->get_tile($col,$row);
                push (@tiles, $tile) if $tile;
            }
        }
    }
    return @tiles;
}

sub get_tile{
    my ($self, $col,$row) = @_;
    croak 'usage: $hexgrid->get_tile($col, $row)' 
        unless (ref($self) && defined($col) && defined($row));
    return undef unless $self->tile_exists($col,$row);
    my $tile = $self->{tiles}->[$row][$col];
    return $tile;
}

#return the total number of tiles
sub num_tiles{
    my $self = shift;
    return $self->{numTiles} if $self->{numTiles};
    $self->{numTiles} = scalar $self->get_all_tiles;
    return $self->{numTiles};
}

#corners of the grid can be 1 or 2 tiles
sub nw_corner{
    my $self = shift;
    return $self->get_tile(0,0) if $self->{evenFirst};
    return ($self->get_tile(0,0), $self->get_tile(0,1));
}
sub ne_corner{
    my $self = shift;
    my @tiles = $self->get_tile($self->{w}-1,0);
    unless($self->{evenLast}){
        push @tiles, $self->get_tile ($self->{w}-$self->{evenFirst}, 1);
    }
    return @tiles;
}
sub sw_corner{
    my $self = shift;
    my @tiles = $self->get_tile (0, $self->{h}-1);
    if ($self->{evenFirst} ^ ($self->{h}%2)){
        push @tiles, $self->get_tile(0,$self->{h}-2)
    }
    return @tiles
}
#if this needs debugging, try looking at the coordinates on the example.
sub se_corner{
    my $self = shift;
    my @tiles; # = $self->get_tile (0, $self->{h}-1);
    #return undef;
    if ($self->{evenLast}){
        push @tiles, $self->get_tile ($self->{w}-1, $self->{h}-1);
        unless ($self->{h}%2){
            push @tiles, $self->get_tile ($self->{w}-1, $self->{h}-2);
        }
    }
    else{ #odd last
        if ($self->{h}%2){
            push @tiles, $self->get_tile ($self->{w}-1, $self->{h}-1);
            push @tiles, $self->get_tile ($self->{w}, $self->{h}-2);
        }
        else{
            push @tiles, $self->get_tile ($self->{w}, $self->{h}-1);
        }
    }
    return @tiles
}

sub tile_w{
    return shift->{linesize}*2
}
sub tile_h{
    return shift->{linesize}*sqrt(3)
}

sub load_image{
    my ($self, $imagename, $filename, $scale_to_tile) = @_;
    croak 'usage: $hexgrid->load_image($imagename, $filename, $scale_to_tile)' 
            unless (ref($self) && defined($imagename) && defined($filename));
    croak "file $filename not found" unless -e $filename;
    
    return if $self->{images}->{$imagename};
    my $surface = Cairo::ImageSurface->create_from_png ($filename);
    if($scale_to_tile){
        my $format = $surface->get_format;
        my $cur_w= $surface->get_width;
        my $cur_h= $surface->get_height;
        my $to_w = $self->tile_w;
        my $to_h = $self->tile_h;
        my $scaledSurf = Cairo::ImageSurface->create ($format, $to_w, $to_h);
        my $cr = Cairo::Context->create ($scaledSurf);
        $cr->scale($to_w/$cur_w, $to_h/$cur_h);
        $cr->set_source_surface ($surface, 0, 0);
        $cr->paint;
        $surface = $scaledSurf;
    }
    $self->{images}->{$imagename} = $surface;
}

sub get_image{
    my ($self, $name) = @_;
    croak 'usage: $hexgrid->get_image($imagename)' 
        unless (ref($self) && defined($name));
    return $self->{images}->{$name}
}

sub _draw_sprite{
    my ($self, $cr, $sprite) = @_;
    my $type = $sprite->type;
    my $tile = $sprite->tile;
    my ($col, $row) = $tile->colrow;
    unless($self->tile_exists($col, $row)){
        carp "tile at $col $row doesn't exist" and return;
    }
    my ($x, $y) = $self->get_tile_center($col, $row);
   # warn $type;
    if($type eq 'text'){
        my $text = $sprite->text;
        my $fontSize = $sprite->size;
        $cr->select_font_face ('sans', 'normal', 'normal');
        $cr->set_font_size ($fontSize);
        $cr->set_source_rgb (0, .0, .0);
        my $extents = $cr->text_extents($text);
        my ($w, $h) = @{$extents}{qw/width height/};
        $x -= $w/2;
        $y += $h/2;
        $cr->move_to($x, $y);
        $cr->show_text($text);
    }
    elsif($type eq 'image'){
        my $imagename = $sprite->imageName;
        my $image = $self->get_image($imagename);
        $cr->set_source_rgb (.5,.5,.5);
        my $w = $image->get_width;
        my $h = $image->get_height;
        $x -= $w/2;
        $y -= $h/2;
        #$cr->move_to($x, $y);
        $cr->set_source_surface ($image, int $x, int $y);
        $cr->paint;
    }
}

sub draw_tile{
    my ($self, $cr, $col,$row, $r,$g,$b) = @_;
    croak 'usage: $hexgrid->draw_tile($cr, $cr(optional), $col, $row, $r,$g,$b(optional))' 
        unless (ref($self) && defined($col) && defined($row));
    return 0 unless $self->tile_exists($col,$row);
    
    my $tile = $self->get_tile($col, $row);
    unless (defined($r) and defined($g) and defined($b)){
        ($r,$g,$b) = @{$tile}{'r','g','b'};
    }
    $cr = $self->get_cairo_context unless ($cr);
    my $ls=$self->{linesize};
    my ($topX, $topY) = ($ls/2, -$ls * sqrt(3)/2); #upper right corner
    my ($sideX, $sideY) = ($ls, 0);  #right-side corner
    #draw lines around tile center
    my ($cx, $cy) = get_tile_center($self, $col,$row);
    $cr->move_to($cx+$topX, $cy+$topY); #start at top-right
    $cr->line_to($cx+$sideX, $cy+$sideY);
    $cr->line_to($cx+$topX, $cy-$topY);
    $cr->line_to($cx-$topX, $cy-$topY);
    $cr->line_to($cx-$sideX, $cy-$sideY);
    $cr->line_to($cx-$topX, $cy+$topY);
    my $path= $cr->copy_path;
    $cr->set_source_rgb($r, $g, $b);
    $cr->fill;
    
    #draw sprites
    $cr->append_path($path);
    $cr->clip;
    my $sprites = $tile->sprites;
    $self->_draw_sprite($cr, $_) for (@$sprites);
    $cr->reset_clip;
    
    #stroke hex border
    $cr->append_path($path);
    $cr->close_path;
    $cr->set_source_rgb (0, .0, .0);
    $cr->set_line_width (2);
    $cr->stroke;
}
sub draw_tile_ref{
    my ($self, $tile, $r,$g,$b) = @_;
    croak 'usage: $hexgrid->draw_tile_ref($tile)' ."   OR\n".
          'usage: $hexgrid->draw_tile_ref($tile, $r,$g,$b)'
        unless (ref($self) && ref($tile));
    $self->draw_tile (undef, $tile->colrow, $r,$g,$b)
}

sub _expose_event{
    my ($widget, $eventexpose, $hexgrid) = @_;
    my $cr = get_cairo_context($hexgrid);
    
    my @area= $eventexpose->area->values;
    my $tiles = $hexgrid->{tiles};
    for my $rownum (0..$#$tiles){
        my $row= $tiles->[$rownum];
        for my $colnum(0..@$row){
            my $tile = $row->[$colnum];
            if($hexgrid->tile_exists($colnum,$rownum)){
                draw_tile($hexgrid, $cr, $colnum,$rownum);
            }
        }
    }
}

sub on_click{
    my ($self, $func) = @_;
    croak 'usage: $hexgrid->on_click(\&func)' 
        unless (ref($self) && ref($func) eq 'CODE');
    $self->{onClick} = $func;
}

sub _button_press_cb{
    # $widget is an eventbox
    my ($widget, $event, $hexgrid) = @_;
    my ($x, $y)= $event->coords;
    my ($col, $row)= get_col_row_from_XY ($hexgrid, $x, $y);
    if ($hexgrid->{onClick}){
        $hexgrid->{onClick}->($col,$row, $x, $y) ;
    }
}
q ! positively!;
__END__

=head1 NAME

Gtk2::Hexgrid - a grid of hexagons

=head1 SYNOPSIS

    use Gtk2 -init;
    use Gtk2::Hexgrid;
    
    my ($w, $h) = (4, 6);
    my $linesize = 35;
    my $border = 30;
    my $evenRowsFirst = 1;
    my $evenRowsLast = 0;
    my $hexgrid = Gtk2::Hexgrid->new ($w, $h, 
                        $linesize, $border, 
                        $evenRowsFirst, $evenRowsLast);
    
    my $window = Gtk2::Window->new;
    $window->add($hexgrid);
    $window->show_all;
    
    Gtk2->main;

=head1 DESCRIPTION

Gtk2::Hexgrid is a widget for displaying hexgrids. Choose the dimensions, tile size, tile colors, alignment, border stuff, give it text to display.

This widget only supports vertical orientation (definite columns)

Currently there is no support for sprites or textures. (TODO)

The grid coordinates may seem screwy. Think of the rows as being very thin and the columns as being very thick. As long as there are methods supplied for adjacent tiles, pathfinding, etc., it shouldn't matter at all. (pathfinding is TODO) See example program for a demonstration.

=head1 OBJECT HIERARCHY

    Glib::Object
    +--- Gtk2::Object
         +--- Gtk2::Widget
           +--- Gtk2::Container
             +--- Gtk2::Bin
              +--- Gtk2::EventBox
                 +--- Gtk2::Hexgrid

=head1 METHODS

=head2 new

  my $hexgrid = Gtk2::Hexgrid->new(
                        $w,
                        $h, 
                        $linesize,
                        $border, 
                        $evenRowsFirst,
                        $evenRowsLast,
                        $r,$g,$b);

Creates and returns a new Gtk2::Hexgrid widget.

=over

=item * $w

The number of hexes in the even rows

=item * $h

Number of rows

=item * $linesize

Hexagons have 6 lines under optimal conditions. $linesize is their length in pixels.

=item * $border

Space between the grid and the widget boundary (drawable) 

=item * $evenRowsFirst

Upper-right corner to be "rounded" (see example prog)

=item * $evenRowsLast

Upper-left corner to be "rounded" (see example prog)

=item * $r,$g,$b

Color. Range is from 0 to 1.

=back

=head2 tile_exists

 $hexgrid->tile_exists($col,$row);

Returns 0 if tile does not exist, else 1

=head2 draw_tile

 $hexgrid->draw_tile($cr, $col,$row, $r,$g,$b);

Ignore the $cr if you please. $r $g $b are between 0 and 1.
Ignore $r,$g,$b if you want the tile's color

=head2 draw_tile_ref

 $hexgrid->draw_tile($tile, $r,$g,$b);

Ignore $r,$g,$b if you want the tile's color

=head2 redraw_board

 $hexgrid->redraw_board;

Redraw the board.

=head2 load_image

 $hexgrid->load_image ($imagename, $filename, $scale_to_tile_size);

This function loads a PNG file. If $scale_to_tile_size is set, it scales to tile size.
Note that $tile->set_background also loads a png file, and it caches automatically.

=head2 get_image

 $hexgrid->get_image($imagename);

Returns the cairo image named $imagename. This is probably different from its filename. This method is mostly internal.

=head2 on_click

 $hexgrid->on_click(
      sub{
          my ($col, $row, $x, $y) = @_;
          $hexgrid->draw_tile(undef, $col,$row, 0, .4, 0);
      }
 );

Give widget something to do when clicked.
Callback function is called with tile coordinates and pixel coordinates.

=head2 get_tile

 $hexgrid->get_tile($col, $row);

Returns a tile object.

=head2 num_tiles

Returns the number of tiles in this hexgrid.

=head2 get_all_tiles

Returns all tile objects of this hexgrid.

=head2 get_ring

 $hexgrid->get_tiles_in_range($col, $row, $radius);

Returns all tiles that are exactly a particular distance
from the specified coordinates.

=head2 get_tiles_in_range

 $hexgrid->get_tiles_in_range($col, $row, $range);

Returns all tiles within a particular distance of the specified coordinates.

=head2 get_tile_from_XY, get_col_row_from_XY

 $hexgrid->get_col_row_from_XY($x, $y);

$x and $y are pixel coordinates
Returns the column and row of the tile
If $x and $y are not inside a tile, this function will return coordinates of a nonexistant tile.
It may not be correct coordinates if $x and $y are far from any tile.

 $hexgrid->get_tile_from_XY($x, $y);

Returns a tile object

=head2 get_tile_center

 $hexgrid->get_tile_center($col, $row);

Returns the pixel coordinates to the center of the tile

=head2 get_adjacent_tile_coordinates

 my @adj = $hexgrid->get_adjacent_tile_coordinates($col, $row);

Returns a list of 6 array references containing col and row of adjacent tiles

=head2 get_adjacent_tiles

 my @adj = $hexgrid->get_adjacent_tiles($col, $row);

Returns a list of adjacent tile objects

=head2 tiles_adjacent

 my ($col1,$row1,$col2,$row2) = (4,5,4,7);
 die unless $hexgrid->tiles_adjacent($col1,$row1,$col2,$row2);

Rreturns 1 if tiles are adjacent, else 0.
In case you're wondering, the above snippet lives. See the example for proof.

=head2 next_tile_by_direction

 $hexgrid->next_tile_by_direction($col,$row, $direction);

This will return a tile adjacent to the given coordinates in the given direction. If there is no tile, it will return undef.
As for $direction, 0 is northeast, 1 southeast, 2 south, etc. Don't worry about going over 5 or under 0.
$tile->northeast is a simpler way to do this.

=head2 next_col_row_by_direction

 $hexgrid->next_col_row_by_direction($col,$row, $direction);

This function exists because next_tile_by_direction will return undef if the tile does not exist. There are no such limits to this one.

=head2 Corners

These will return the one or two tiles at a corner of the grid.

=over

=item ne_corner

=item nw_corner

=item se_corner

=item sw_corner

=back

=head2 tile_w

Returns the width of any tile.

=head2 tile_h

Returns the height of any tile.

=head2 get_cairo_context

Lets you mess up this widget using cairo.

=head1 Other hexmap libraries

I started this lib before I saw the hexmap library: L<http://hexmap.sourceforge.net>. 
It supposedly has perl bindings.

There are other implementations in wesnoth and freeciv. Services such as google codesearch will turn up a few more.

=head1 AUTHOR

Zach Morgan, C<< <zpmorgan of google's most popular mail service> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Zach Morgan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
