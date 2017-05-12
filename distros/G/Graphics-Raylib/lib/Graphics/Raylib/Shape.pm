use strict;
use warnings;
package Graphics::Raylib::Shape;

# ABSTRACT: Collection of drawable shapes
our $VERSION = '0.002'; # VERSION

use List::Util qw(min max);
use Graphics::Raylib::XS qw(:all);

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Shape - Collection of drawable shapes


=head1 SYNOPSIS

    use Graphics::Raylib::Pixel;
    use Graphics::Raylib::Circle;
    use Graphics::Raylib::Rectangle;
    use Graphics::Raylib::Triangle;
    use Graphics::Raylib::Poly;

    # example
    
    my $rect = Graphics::Raylib::Rectangle(
        pos   => [0,0],
        size  => [10,10],
        color => Graphics::Raylib::Rectange::MAROON,
    )->draw;

=head1 DESCRIPTION

Basic geometric shapes that can be drawn while in a C<Graphics::Raylib::draw> block.

Coordinates and width/height pairs are represented as array-refs to 2 elements

=head1 METHODS AND ARGUMENTS

=over 4

=item draw()

Call this on any of the following shapes while in a C<Graphics::Raylib::draw> block in order to draw the shape.

Wrap-around progress bar example:
    
    use Graphics::Raylib;
    use Graphics::Raylib::Shape;
    use Graphics::Raylib::Color;
    
    my $block_size = 50;

    my $g = Graphics::Raylib->window($block_size*10, $block_size, "Test");

    $g->fps(5);

    my $rect = Graphics::Raylib::Shape->rectangle(
        pos => [1,0], size => [$block_size, $block_size],
        color => Graphics::Raylib::Color::DARKGREEN
    );

    my $i = 0;
    while (!$g->exiting) {
        Graphics::Raylib::draw {
            $g->clear;

            $rect->draw;
        };

        $i %= 10;
        $rect->{pos} = [$i * $block_size, 0];
    }

=cut

=item pixel( pos => [$x, $y], color => $color )

Prepares a single pixel for drawing.

=cut

{
    package Graphics::Raylib::Shape::Pixel;
    use Graphics::Raylib::XS qw(DrawPixel);
    sub draw { DrawPixel(@{$_[0]->{pos}}, $_[0]->{color} ) }
}
sub pixel {
	my $class = shift;
    
    my $self = { @_ };

	bless $self, 'Graphics::Raylib::Shape::Pixel';
	return $self;
}


=item line( start => [$x, $y], end => [$x, $y], color => $color )

Prepares a line for drawing.

=cut

{
    package Graphics::Raylib::Shape::Line;
    use Graphics::Raylib::XS qw(DrawLine);
    sub draw { DrawLine(@{$_[0]->{start}}, @{$_[0]->{end}}, $_[0]->{color} ) }
}
sub line {
	my $class = shift;
    
    my $self = { @_ };

	bless $self, 'Graphics::Raylib::Shape::Line';
	return $self;
}



=item circle( center => [$x, $y], radius => $r, color => $color )

Prepares a circle for drawing.

=cut


{
    package Graphics::Raylib::Shape::Circle;
    use Graphics::Raylib::XS qw(DrawCircle);
    sub draw { DrawCircle( @{$_[0]->{center}}, $_[0]->{radius}, $_[0]->{color} ) }
}
sub circle {
	my $class = shift;
    
    my $self = { @_ };

	bless $self, 'Graphics::Raylib::Shape::Circle';
	return $self;
}


=item rectangle( pos => [$x, $y], size => [$width, $height], color => $color )

Prepares a solid color rectangle for drawing. if $color is an arrayref of 2 Colors, the fill color will be a gradient of those two.

=cut

{
    package Graphics::Raylib::Shape::Rectangle;
    use Graphics::Raylib::XS qw(DrawRectangle DrawRectangleGradient);
    sub draw {
        if (ref($_[0]->{color}) ne 'ARRAY') {
            DrawRectangle( @{$_[0]->{pos}}, @{$_[0]->{size}}, $_[0]->{color} )
        } else {
            DrawRectangleGradient( @{$_[0]->{pos}}, @{$_[0]->{size}}, @{$_[0]->{color}} )
        }
    }
}

sub rectangle {
	my $class = shift;
    
    my $self = { @_ };

	bless $self, 'Graphics::Raylib::Shape::Rectangle';
	return $self;
}


=item triangle( vertices => [ [$x1,$y1], [$x2,$y2], [$x3,$y3] ], color => $color )

Prepares a triangle for drawing.

=cut

{
    package Graphics::Raylib::Shape::Triangle;
    use Graphics::Raylib::XS qw(DrawTriangle);
    sub draw {
        my @v = @{$_[0]->{vertices}};
        DrawTriangle( @{$v[0]}, @{$v[1]}, @{$v[2]}, $_[0]->{color} );
    }
}

sub triangle {
	my $class = shift;
    
    my $self = { @_ };

	bless $self, 'Graphics::Raylib::Shape::Triangle';
	return $self;
}

{
    package Graphics::Raylib::Shape::Polygon;
    # TODO: missing
}

=item bitmap( matrix => $AoA, width => $screen_width, height => $screen_height, color => $color )

Prepares a matrix for printing. C<$AoA> is an array of arrays ref. C<$screen_width> and C<$screenheight> are the size of the area on which the Matrix should be drawn. It defaults to the screen size.

if C<$color> is a C<Graphics::Raylib::Color>, it will be used to color all positive $AoA elements. The space occupied by negative and zero elements stays at background color.

if C<$color> is a code reference, It will be evaluated for each matrix element, with the element's value as argument. The return type of the code reference will be used for the color. Return C<undef>, for omitting the element.

Example:
    
    use PDL;
    use PDL::Matrix;

    my $pdl = mpdl [
                     [0, 1, 1, 1, 0],
                     [1, 0, 0, 0, 0],
                     [0, 1, 1, 1 ,0],
                     [0, 0, 0, 0 ,1],
                     [0, 1, 1, 1 ,0],
                   ];

    my $g = Graphics::Raylib->window(240, 240);

    $g->fps(10);

    my $i = 0;
    while (!$g->exiting)
    {

        my $bitmap = Graphics::Raylib::Shape->bitmap(
            matrix => unpdl($gen),
            color  => Graphics::Raylib::Color::YELLOW;
        );

        Graphics::Raylib::draw {
            $g->clear(Graphics::Raylib::Color::BLACK);

            $bitmap->draw;
        };


        # now do some operations on $pdl, to get next iteration

    }

See the game of life example at L<Graphics::Raylib> for a more complete example.

=cut

{
    package Graphics::Raylib::Shape::Bitmap;
    sub draw {
        my $self = shift;
        my $matrix = $self->{matrix};

        for my $i ( 0 .. $#$matrix ) {
            for my $j ( 0 .. $#{ $matrix->[$i] } ) {
                my $color = $self->{color}($matrix->[$i][$j]);
                Graphics::Raylib::Shape->rectangle(
                    pos   => [$j*$self->{width}, $i*$self->{height}],
                    size  => [$self->{width}, $self->{height}],
                    color => $color,
                )->draw if defined $color;
            }
        }
    }
}


sub bitmap {
	my $class = shift;
    
    my $self = { @_ };

    unless (defined $self->{height} && defined $self->{width}) {
        my $maxlen = max map { scalar @$_ } @{$self->{matrix}};

        # cell sizes
        $self->{width} = GetScreenWidth()  / ($maxlen-1);
        $self->{height}   = GetScreenHeight() / $#{$self->{matrix}};
    }
    my $color = $self->{color};
    $self->{color} = sub { pop > 0 ? $color : undef }
        unless ref($color) eq 'CODE';


    bless $self, 'Graphics::Raylib::Shape::Bitmap';
    return $self;
}

1;

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Graphics-Raylib>

=head1 SEE ALSO

L<Graphics::Raylib>  L<Graphics::Raylib::Color>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
