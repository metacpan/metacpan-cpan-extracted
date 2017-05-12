package Gtk2::Hexgrid::Sprite;
use Carp;
use warnings;
use strict;

sub new{
    my $class = shift;
    my $type = shift;
    
    my $self= {
        tile => undef,
        type => $type,
        priority => 0
    };
    if ($type eq 'text'){
        $self->{text} = shift;
        $self->{size} = shift; #font size, such as 18
    }
    elsif($type eq 'image'){
        my $name = shift;
        croak 'image needs name' unless $name;
        $self->{imageName} = $name;
    }
    bless $self, $class;
    return $self;
}

#only for images (no text)
sub new_scaled{
    my ($class, $hexgrid, $filename) = @_;
    my $imagename = $filename;
    $imagename .= "~scaled";
    $hexgrid->load_image ($imagename, $filename, 1);
    my $self = new ($class, 'image', $imagename);
    $self->set_priority(0);
    return $self;
}

sub copy{
    my $self = shift;
    my %copy = %$self;
    return \%copy;
}
#attach to tile
sub attach{
    my ($self, $tile) = @_;
    $tile->add_sprite($self);
}
#detach from tile
sub detach{
    my $self = shift;
    my $tile = $self->tile;
    $tile->remove_sprite($self);
}
sub set_priority{ #place in the drawing order
    my ($self, $p) = @_;
    $self->{priority} = $p;
}
sub _set_tile{ #the tile that it it attached to
    my ($self, $tile) = @_;
    $self->{tile} = $tile;
}

sub imageName{
    shift->{imageName}
}

sub tile{
    shift->{tile}
}
sub type{
    shift->{type}
}
sub text{
    shift->{text}
}
sub size{
    shift->{size}
}
sub priority{
    shift->{priority}
}
q ! positively!
__END__

=head1 NAME

Gtk2::Hexgrid::Sprite - an object to be drawn over a tile

=head1 SYNOPSIS

 my $sprite1 = $tile->set_background("images/squid.png");
 my $sprite2 = $tile->set_text("blah", 18);
 my $sprite3 = new Gtk2::Hexgrid::Sprite("text", "blah", 15);
 my $sprite4 = new Gtk2::Hexgrid::Sprite("image", "imageName");
 $sprite4->set_priority(5);
 $sprite4->attach($tile);

=head1 DESCRIPTION

Use these if you want a background, some text, or some critters that aren't tied to a particular tile.

=head1 METHODS

=head2 new

 my $sprite3 = new Gtk2::Hexgrid::Sprite("text", "blah", 15);
 my $sprite4 = new Gtk2::Hexgrid::Sprite("image", "imageName");

The type, "text" or "image", is in the first field.
If "text", the text and font size are in the next fields.
If 'image', the image name is in the next field.
The image name is used as a key to the actual image.
Images are loaded by Gtk2::Hexgrid::load_image.

=head2 new_scaled

 my $sprite = new_mobile Gtk2::Hexgrid::Sprite($hexgrid, $filename);

Automatically loads sprite. This method works well with penguin sprites.

=head2 copy

 my $newSprite = $sprite->copy();

Returns a clone of caller sprite.

=head2 accessors

=over

=item tile

=item type

=item text

=item size

=item priority

=item imageName

=back

=head2 detach

 $sprite->detach;

Removes self from its parent and starts floating in space

=head2 attach

 $sprite->attach($tile);

Performs a detach in reverse.

=head2 set_priority

Each sprite has a priority, the default being 0. Sprites with lower
priorities are drawn before sprites with higher priorities.
I've given backgrounds a priority of -21.21, and text is 21.21. 
They are not round numbers because sprites with the same priority are
prioritized by thich sprite was attached first, and that may cause weird behavior.

=cut
