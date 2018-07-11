use strict;
use warnings;
package Graphics::Raylib::Texture;

# ABSTRACT: Drawable Texture from Image
our $VERSION = '0.021'; # VERSION

use List::Util qw(min max);
use Graphics::Raylib::XS qw(:all);
use Graphics::Raylib::Color;
use Graphics::Raylib::Util qw(rectangle vector);

use Carp;

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Texture - Drawable Texture from Image


=head1 VERSION

version 0.021

=head1 SYNOPSIS

    use Graphics::Raylib '+family';
    use PDL;
    use PDL::Matrix;

    my $pdl = mpdl[
                     [0, 1, 1, 1, 0],
                     [1, 0, 0, 0, 0],
                     [0, 1, 1, 1 ,0],
                     [0, 0, 0, 0 ,1],
                     [0, 1, 1, 1 ,0],
                   ];

    my $g = Graphics::Raylib->window(240, 240);
    $g->fps(60);

    my $img = Graphics::Raylib::Texture->new(matrix => unpdl($pdl), color => YELLOW, transposed => 1);

    while (!$g->exiting) {
        $img->matrix = unpdl($pdl);
        $img->rotation -= 1;

        Graphics::Raylib::draw {
            $g->clear(BLACK);
            $img->draw;
        };


        # now do some operations on $pdl, to get next iteration
    }

=head1 DESCRIPTION

For drawing images

=head1 METHODS AND ARGUMENTS

=over 4

=item new( file => $filename, [width => $imgwidth, height => imgheight] ] )
=item new( pixels => $str, [width => $imgwidth, height => imgheight] ] )
=item new( bytes => $rawbytes, [width => $imgwidth, height => imgheight] ] )
=item new( imager => $imager, [width => $imgwidth, height => imgheight] ] )

Prepares the image the for drawing. The image may be specified as C<file> name, by its C<bytes>, an instance of L<Imager> or L<Graph::Easy> or as a series of C<pixels>. C<pixels>' value may be either an array ref of array refs or a string. In all cases except for C<< pixels => string >>, the C<size> can be omitted and it will be inferred from the image.

Specifying C<< fullscreen  => 1 >> overrides C<height> and C<width>.

=cut

sub new {
    my $class = shift;

    my $self = {
        uninitialized => 0, rotation => 0, x => 0, y => 0,
        transposed => 0,
        retexture => 1,
        fullscreen => 0,
        tint => Graphics::Raylib::Color::WHITE,
        color => Graphics::Raylib::Color::GOLD,
        @_
    };

    bless $self, $class;

    if ($self->{fullscreen}) {
        $self->{width}  = GetScreenWidth();
        $self->{height} = GetScreenHeight();
    }


    if (!$self->{texture}) {
        $self->{image} = defined $self->{file}     ? LoadImage($self->{file})
                       : defined $self->{matrix}   ? load_image_from_array($self)
                       : defined $self->{bytes}    ? load_bytes($self->{bytes}, $self->{width}, $self->{height}, $self->{format})
                       : defined $self->{imager}   ? load_imager($self->{imager})
                       #                       : defined $self->{gd_image} ? load_gd_image($self->{gd_image})
                       :                             $self->{image};
        $self->texturize;
    }

    defined $self->{texture} or croak "One of keys(qw(file bytes pixels imager graph_easy)) requires a value!";

    return $self;
}

sub load { goto &new }

=item new( matrix => $AoA, color => $color, [ width => $image_width, height => $image_height, transposed => 0, $rotate => 0 ])

Creates a texture out of a matrix for printing. C<$AoA> is an array of arrays ref. C<$image_width> and C<$image_height> are the size of the area on which the Matrix should be drawn. It's optional defaults to the screen size.

If C<$color> is a C<Graphics::Raylib::Color>, it will be used to color all positive $AoA elements. The space occupied by negative and zero elements stays at background color.

if C<$color> is a code reference, It will be evaluated for each matrix element, with the element's value as argument. The return type of the code reference will be used for the color. Return C<undef>, for omitting the element (drawing it transparently). C<$color == undef> is an unsafe but faster shorthand for C<$color = sub { shift }>.

C<< transposed => >> determines whether the image should be drawn transposed ( x,y flipped ). It's more effecient than transposing in a separate step.

C<< rotate => >> sets an angle (in degrees) for rotation. Rotation origin is the center of the image.

See the game of life example at L<Graphics::Raylib> (or C<t/30-game-of-life.t>) for a more complete example.

=cut

sub load_image_from_array {
    my $self = shift;
    $self->{transposed} = $self->{transposed} // $self->{transpose};

    my $color = $self->{color};
    if (defined $color) {
        my $c = $color;
        $color = ref($color) eq 'CODE' ? $color : sub { (shift // 0) > 0 ? $c : undef };
    }

    my $func = $self->{transposed} && $self->{uninitialized} ? \&LoadImageFromAV_transposed_uninitialized_mem
             : $self->{transposed}                           ? \&LoadImageFromAV_transposed
             :                        $self->{uninitialized} ? \&LoadImageFromAV_uninitialized_mem
             :                                                 \&LoadImageFromAV;

    $self->retexture;
    return $func->($self->{matrix}, $color);
}

sub load_imager {
    my $imager = shift;
    my $data;
    $imager->write(data => \$data, type => 'raw');
    return load_bytes($data, 100, 100);#$imager->getwidth, $imager->getheight);
}
sub load_bytes {
    my $bytes  = shift;
    my $width  = shift // croak "Width must be specified";
    my $height = shift // croak "Height must be specified";
    my $format = shift // UNCOMPRESSED_R8G8B8;

    my $pixels = unpack $Graphics::Raylib::Util::PTR_PACK_FMT, pack('P', $bytes);
    bless \$pixels, "ColorPtr";

    return LoadImagePro($pixels, $width, $height, $format);
}

sub texturize {
    my $self = shift;

    if (!$self->{texture}) {
        $self->{texture} = LoadTextureFromImage($self->{image});
    } elsif ($self->{retexture}) {
        UpdateTextureFromImage($self->{texture}, $self->{image});
    }

    $self->{retexture} = 0;
    return $self->{texture};
}

sub matrix :lvalue {
    my $self = shift;
    defined $self->{matrix}
        or croak "Graphics::Raylib::Texture instance has no underlying matrix";

    $self->{reload_image_from_array} = 1;
    $self->{matrix}
}
sub rotation :lvalue {
    my $self = shift;

    $self->{rotation};
}
sub color :lvalue { $_[0]->{color}  }
sub DESTROY {
      my $self = shift;
      UnloadTexture($self->{texture}) if defined $self->{texture};
      UnloadImage($self->{image}) if defined $self->{image};
}

=item draw()

Call this while in a C<Graphics::Raylib::draw> block in order to draw the image to screen.

By default, the texture will be drawn centered.

=cut

sub draw {
    my $self = shift;
    my %args = ( fancy => 1, x => $self->{x}, y => $self->{y}, @_ );
    if ($self->{reload_image_from_array}) {
        UnloadImage($self->{image}) if defined $self->{image};
        $self->{image} = load_image_from_array($self);
        $self->{reload_image_from_array} = 0;
    }
    my $texture = texturize($self);

    if ($args{fancy}) {
        my $sourceRec = rectangle(x => 0, y => 0, width => $texture->width, height => $texture->height);
        my ($width,$height) = ($self->{width}//$texture->width,$self->{height}//$texture->height);
        my $origin    = vector($width/2, $height/2);
        my $destRec   = rectangle(x => $origin->x + $args{x}, y => $origin->y + $args{y}, width => $width, height => $height);

        DrawTexturePro(
            $texture,
            $sourceRec, $destRec, $origin,
            $self->{rotation}, $self->{tint}
        );
    } else {
        DrawTexture($texture, 0, 0, $self->{tint});
    }
}


=item flip( vertical => 1, horizontal => 0)

Flip the image in the specified orientation

=cut

sub flip {
    my $self = shift;

    my %args = (vertical => 1, horizontal => 0, @_);

    ImageFlipVertical($self->{image})   if $args{vertical};
    ImageFlipHorizontal($self->{image}) if $args{horizontal};
    $self->retexture;
    return $self;
}

=item image

lvalue subroutine returning the image's underlying C<Graphics::Raylib::XS::Image>

=cut

sub image :lvalue {
    my $self = shift;
    $self->{image}
}


=item retexture

Reload texture from image

=cut

sub retexture {
    my $self = shift;
    my $retexture = $self->{retexture};
    $self->{retexture} = 1;
    return $retexture;
}

1;

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics::Raylib>  L<Graphics::Raylib::Shape>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
