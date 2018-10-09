use strict;
use warnings;
package Graphics::Raylib::Shape;

# ABSTRACT: Collection of drawable shapes
our $VERSION = '0.023'; # VERSION

use List::Util qw(min max);
use Graphics::Raylib::XS qw(:all);
use Graphics::Raylib::Color;
use Graphics::Raylib::Util;
use Graphics::Raylib::Texture;

use Carp;

=pod

=encoding utf8

=head1 NAME

Graphics::Raylib::Shape - Collection of drawable shapes


=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use Graphics::Raylib::Shape::Pixel;
    use Graphics::Raylib::Shape::Circle;
    use Graphics::Raylib::Shape::Rectangle;
    use Graphics::Raylib::Shape::Triangle;

    # example

    Graphics::Raylib::draw {
        Graphics::Raylib::Rectangle(
            position => [0,0],
            size     => [10,10],
            color    => Graphics::Raylib::Color::MAROON,
        )->draw;
    };

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
        position => [1,0], size => [$block_size, $block_size],
        color => Graphics::Raylib::Color::DARKGREEN
    );

    my $i = 0;
    while (!$g->exiting) {
        Graphics::Raylib::draw {
            $g->clear;

            $rect->draw;
        };

        $i %= 10;
        $rect->{position} = [$i * $block_size, 0];
    }

=cut

=item pixel( position => [$x, $y], color => $color )

Prepares a single pixel for drawing.

=cut

{
    package Graphics::Raylib::Shape::Pixel;
    use Graphics::Raylib::XS qw(DrawPixel);
    sub draw { DrawPixel(@{$_[0]->{position}}, $_[0]->{color} ) }
    sub color :lvalue { $_[0]->{color}  }
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
    sub color :lvalue { $_[0]->{color}  }
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
    sub color :lvalue { $_[0]->{color}  }
}
sub circle {
    my $class = shift;

    my $self = { @_ };

    bless $self, 'Graphics::Raylib::Shape::Circle';
    return $self;
}


=item rectangle( position => [$x, $y], size => [$width, $height], color => $color )

Prepares a solid color rectangle for drawing. if $color is an arrayref of 2 Colors, the fill color will be a gradient of those two.

=cut

{
    package Graphics::Raylib::Shape::Rectangle;
    use Graphics::Raylib::XS qw(DrawRectangle DrawRectangleGradientV);
    sub draw {
        if (ref($_[0]->{color}) ne 'ARRAY') {
            DrawRectangle( @{$_[0]->{position}}, @{$_[0]->{size}}, $_[0]->{color} )
        } else {
            DrawRectangleGradientV( @{$_[0]->{position}}, @{$_[0]->{size}}, @{$_[0]->{color}} )
        }
    }
    sub color :lvalue { $_[0]->{color}  }
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
    sub color :lvalue { $_[0]->{color}  }
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
    sub color :lvalue { $_[0]->{color}  }
}

=begin comment

deprecated

=end comment

=cut

sub bitmap {
    my $class = shift;

    carp "Graphics::Raylib::Shape::Bitmap is deprecated. Use Graphics::Raylib::Texture instead";

    return Graphics::Raylib::Texture->new(
        fullscreen => 1,
        @_
    );
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
