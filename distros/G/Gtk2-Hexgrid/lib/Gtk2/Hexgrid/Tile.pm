package Gtk2::Hexgrid::Tile;
use warnings;
use strict;
use Gtk2::Hexgrid::Sprite;

# hexgrid->{tiles} # LoL of tiles
# tiles will have their color and coordinates, and tiles will be accessible through \@tiles
# tiles will have a list of sprites, sprites will reference their tile
# sprites will be accessable through \%sprites if they have a name(boat2,red1, etc)

sub new{
    my $class = shift;
    my ($hexgrid, $col, $row, $r, $g, $b) = @_;
    my $self = {
        hexgrid => $hexgrid, #constant
        col => $col, #constant
        row => $row, #constant
        r => $r,
        g => $g,
        b => $b,
        sprites => []
    };
    
    bless $self, $class;
    return $self;
}
sub draw{
    my ($self) = shift;
    $self->{hexgrid}->draw_tile_ref($self, @_)
}

sub has_sprite{
    my ($self, $sprite) = @_;
    my $sprites = $self->{sprites};
    return scalar grep {$_ == $sprite} @{$self->{sprites}};
}

sub remove_sprite{
    my ($self, $sprite) = @_;
    my $numSprites = scalar @{$self->{sprites}};
    @{$self->{sprites}} = grep {$_ != $sprite} @{$self->{sprites}};
    if($numSprites == @{$self->{sprites}}) {#make sure that an sprite was actually removed
        carp ("remove_sprite called with an sprite that was not attached to tile " . $self->col . ", " . $self->row);
        return;
    }
    $sprite->_set_tile(undef);
}

sub add_sprite{
    my ($self, $sprite) = @_;
    $sprite->_set_tile($self);
    push @{$self->{sprites}}, $sprite;
    #sort sprites into order of drawing
    @{$self->{sprites}} = 
        sort{$a->{priority} <=> $b->{priority}} 
          @{$self->{sprites}};
}

sub destroy_text{
    my ($self) = shift;
    @{$self->{sprites}} = grep {$_->type() ne "text"} @{$self->{sprites}};
}
sub destroy_background{
    my ($self) = shift;
    @{$self->{sprites}} = grep {$_->priority() != -21.21} @{$self->{sprites}};    
}

sub set_text{
    my ($self, $text, $size) = @_;
#    $self->destroy_text;
    my $sprite = new Gtk2::Hexgrid::Sprite('text', $text, $size);
    $sprite->set_priority(21.21);
    $self->add_sprite($sprite);
    return $sprite;
}

sub set_background{
    my ($self, $filename) = @_;
    my $imagename = $filename.'~scaled';
    $self->{hexgrid}->load_image ($imagename, $filename, 1);
    my $sprite = new Gtk2::Hexgrid::Sprite ('image', $imagename);
    $sprite->set_priority(-21.21);
    $self->destroy_background;
    $self->add_sprite($sprite);
    return $sprite;
}

sub get_adjacent{
    my $self = shift;
    return $self->{hexgrid}->get_adjacent_tiles($self->colrow);
}
sub get_center{
    my $self = shift;
    return $self->{hexgrid}->get_tile_center($self->colrow);
}

sub set_color{
    my ($self, $r, $g, $b) = @_;
    @{$self}{qw/r g b/} = ($r, $g, $b);
}

sub next_by_direction{
    my $self= shift;
    my $dir = shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, $dir);
}

sub ne{ #northeast
    my $self= shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, 0);
}
sub se{ #southeast
    my $self= shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, 1);
}
sub s{
    my $self= shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, 2);
}
sub sw{
    my $self= shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, 3);
}
sub nw{
    my $self= shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, 4);
}
sub n{
    my $self= shift;
    $self->{hexgrid}->next_tile_by_direction($self->{col}, $self->{row}, 5);
}
*north = *n;
*northeast = *ne;
*southeast = *se;
*south = *s;
*southwest = *sw;
*northwest = *nw;

sub col{
    shift->{col}
}
sub row{
    shift->{row}
}
sub colrow{
    @{shift()}{qw/col row/}
}
sub rgb{
    @{shift()}{qw/r g b/}
}
sub sprites{
    shift->{sprites}
}
sub hexgrid{
    shift->{hexgrid}
}
sub background{
    return shift->sprites->[0]->imageName;
}

q ! positively!
__END__

=head1 NAME

Gtk2::Hexgrid::Tile - a hexagonal tile from a Hexgrid

=head1 SYNOPSIS

 my @tiles = $hexgrid->get_all_tiles;
 my $tile = $hexgrid->get_tile(3,5);
 my $column = $tile->col;
 my ($col, $row) = $tile->colrow;
 my ($r, $g, $b) = $tile->rgb;
 $tile->set_color(.1, .65, .35);
 $tile->set_text('Clowndog', 13);
 $tile->destroy_text;
 $tile2 = $tile->southwest;

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

 my $tile = new Gtk2::Hexgrid::Tile ($hexgrid, $col, $row, $r, $g, $b)

There's probably no reason to learn the constructor:
Tiles are automatically generated with your hexgrid.
$hexgrid, $col, $row are there so it knows.
$r, $g, $b are it's default color, and it may be changed later.

=head1 METHODS

=head2 accessors

=over

=item rgb

=item col

=item row

=item colrow

=item hexgrid

=item background

=item sprites

=back

=head2 get_adjacent

See Gtk2::Hexgrid::get_adjacent_tiles

=head2 get_center

See Gtk2::Hexgrid::get_tile_center

=head2 relative locating

Methods are provided to find whatever tile is adjacent in a specific direction.
These return the adjacent tile if it exists, else undef.

 $tile->north
 $tile->n
 $tile->northeast
 $tile->ne
 etc...

=over

=item north

=item n

=item northeast

=item ne

=item southeast

=item se

=item south

=item s

=item southwest

=item sw

=item northwest

=item nw

=item next_by_direction

=back

=head2 set_background

 $tile->set_background("data/onion.png");

Loads a png file, scales it to tile size, and has $tile draw it first
whenever it needs drawn.

Backgrounds are cached, so dont worry about loading the same file more than once
Backgrounds are given a low (-21.21) priority so that they are drawn first.

Not redrawn automatically.

=head2 set_color

 $tile->set_color($r, $g, $b);

Cairo colors (range is 0 to 1). Not redrawn automatically

=head2 set_text

 my $size = 14
 $tile->set_text('uoewriu', $size) = @_;

Text is given a priority of 21.21. If you want to paint over it, 
give something a higher prioriry.
Not redrawn automatically.

=head2 add_sprite

 $tile->add_sprite($sprite);

Attaches $sprite to $tile.

=head2 remove_sprite

 $tile->remove_sprite($sprite);

Removes $sprite from $tile.

=head2 has_sprite

 $tile->has_sprite($sprite);

Returns true if $sprite is attached to $tile, else false.

=head2 destroy_background

 $tile->destroy_background;

Removes background sprites from tile.  Actually, it believes that all
sprites with a -21.21 priority are background.

=head2 destroy_text

 $tile->destroy_text;

Removes all text sprites from tile.  Actually, it believes that all
sprites with a 21.21 priority are text sprites.

=head2 draw

 $tile->draw();
 $tile->draw($r, $g, $b);

Draws tile using tile's color unless another color is given.
Associated with $hexgrid->draw_tile and $hexgrid->draw_tile_ref.

=cut
