# Copyright (c) 2017  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Graphics::GVG::OpenGLRenderer;
$Graphics::GVG::OpenGLRenderer::VERSION = '0.3';
# ABSTRACT: Turn a GVG file into OpenGL code
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Data::UUID;
use Imager::Color;
use Math::Trig 'pi';

with 'Graphics::GVG::Renderer';

has [qw{ circle_segments ellipse_segments }] => (
    is => 'rw',
    isa => 'Int',
    default => 40,
);


sub make_pack
{
    my ($self) = @_;
    my $uuid = Data::UUID->new->create_hex;
    my $pack = __PACKAGE__ . '::' . $uuid;
    return $pack;
}

sub make_opening_code
{
    my ($self, $pack) = @_;

    my $code = 'package ' . $pack . ';';
    $code .= q!
        use strict;
        use warnings;
        use OpenGL qw(:all);

        sub new
        {
            my ($class) = @_;
            my $self = {};
            bless $self => $class;
            return $self;
        }

        sub draw {
    !;
    return $code;
}

sub make_closing_code
{
    my ($self, $pack) = @_;
    my $code = 'return; }';
    $code .= '1;';
    return $code;
}

sub make_line
{
    my ($self, $cmd) = @_;
    my $x1 = $cmd->x1;
    my $y1 = $cmd->y1;
    my $x2 = $cmd->x2;
    my $y2 = $cmd->y2;
    my $color = $cmd->color;
    my ($red, $green, $blue, $alpha) = $self->_int_to_opengl_color( $color );

    my $make_line_sub = sub {
        my ($width, $red, $green, $blue, $alpha) = @_;
        my $code = qq!
            glLineWidth( $width );
            glColor4ub( $red, $green, $blue, $alpha );
            glBegin( GL_LINES );
                glVertex2f( $x1, $y1 );
                glVertex2f( $x2, $y2 );
            glEnd();
        !;
        return $code;
    };

    my $code = '';
    if( $self->glow_count > 0 ) {
        # TODO not really getting the effect I was hoping for. Play around 
        # with it later.
        my @colors1 = $self->_brighten( 2.0, $red, $green, $blue, $alpha );
        my @colors2 = ($red, $green, $blue, $alpha);
        my @colors3 = $self->_brighten( 0.7, $red, $green, $blue, $alpha );
        $code = $make_line_sub->( 5.0, @colors3 );
        $code .= $make_line_sub->( 2.0, @colors2 );
        #$code .= $make_line_sub->( 1.0, @colors1 );
    }
    else {
        $code = $make_line_sub->( 1.0, $red, $green, $blue, $alpha );
    }

    return $code;
}

sub make_rect
{
    my ($self, $cmd) = @_;
    my $x = $cmd->x;
    my $y = $cmd->y;
    my $width = $cmd->width;
    my $height = $cmd->height;
    my $color = $cmd->color;
    my ($red, $green, $blue, $alpha) = $self->_int_to_opengl_color( $color );

    my $make_rect_sub = sub {
        my ($width, $red, $green, $blue, $alpha) = @_;
        my $far_x = $x + $width;
        my $far_y = $y + $height;
        my $code = qq!
            glLineWidth( $width );
            glColor4ub( $red, $green, $blue, $alpha );
            glBegin( GL_LINES );
                glVertex2f( $x, $y );
                glVertex2f( $far_x, $y );

                glVertex2f( $far_x, $y );
                glVertex2f( $far_x, $far_y );

                glVertex2f( $far_x, $far_y );
                glVertex2f( $x, $far_y );

                glVertex2f( $x, $far_y );
                glVertex2f( $x, $y );
            glEnd();
        !;
        return $code;
    };

    my $code = '';
    if( $self->glow_count > 0 ) {
        # TODO
        $code = $make_rect_sub->( 1.0, $red, $green, $blue, $alpha );
    }
    else {
        $code = $make_rect_sub->( 1.0, $red, $green, $blue, $alpha );
    }

    return $code;
}

sub make_circle
{
    my ($self, $cmd) = @_;
    my $cx = $cmd->cx;
    my $cy = $cmd->cy;
    my $r = $cmd->r;
    my $color = $cmd->color;

    my $poly = Graphics::GVG::AST::Polygon->new({
        cx => $cx,
        cy => $cy,
        r => $r,
        sides => $self->circle_segments,
        rotate => 0,
        color => $cmd->color,
    });

    return $self->make_poly( $poly );
}

sub make_ellipse
{
    my ($self, $cmd) = @_;
    my $cx = $cmd->cx;
    my $cy = $cmd->cy;
    my $rx = $cmd->rx;
    my $ry = $cmd->ry;
    my $color = $cmd->color;
    my $num_segments = $self->ellipse_segments;
    my ($red, $green, $blue, $alpha) = $self->_int_to_opengl_color( $color );

    # See:
    # http://stackoverflow.com/questions/5886628/effecient-way-to-draw-ellipse-with-opengl-or-d3d
    my $make_cmd_sub = sub {
        my ($width, $red, $green, $blue, $alpha) = @_;
        my $theta = 2 * pi / $num_segments;
        my $c = cos( $theta );
        my $s = sin( $theta );
        my $t;

        my $x = 1;
        my $y = 0;

        my $code = qq!
            glLineWidth( $width );
            glColor4ub( $red, $green, $blue, $alpha );
            glBegin(GL_LINE_LOOP);
        !;
        foreach my $i (0 .. $num_segments) {
            my $set_x = $x * $rx + $cx;
            my $set_y = $y * $ry + $cy;
            $code .= qq!
                    glVertex2f( $set_x, $set_y );
            !;

            $t = $x;
            $x = $c * $x - $s * $y;
            $y = $s * $t + $c * $y;
        }

        $code .= q!
            glEnd();
        !;
        return $code;
    };

    my $code = '';
    if( $self->glow_count > 0 ) {
        # TODO
        $code = $make_cmd_sub->( 1.0, $red, $green, $blue, $alpha );
    }
    else {
        $code = $make_cmd_sub->( 1.0, $red, $green, $blue, $alpha );
    }
    return $code;
}

sub make_poly
{
    my ($self, $cmd) = @_;
    my @coords = @{ $cmd->coords };
    my $color = $cmd->color;
    my ($red, $green, $blue, $alpha) = $self->_int_to_opengl_color( $color );

    my $make_code_sub = sub {
        my ($width, $red, $green, $blue, $alpha) = @_;
        my $code = qq!
            glLineWidth( $width );
            glColor4ub( $red, $green, $blue, $alpha );
            glBegin( GL_LINES );
        !;

        foreach my $i (0 .. $#coords - 1) {
            my $x1 = $coords[$i][0];
            my $y1 = $coords[$i][1];
            my $x2 = $coords[$i+1][0];
            my $y2 = $coords[$i+1][1];

            $code .= qq!
                glVertex2f( $x1, $y1 );
                glVertex2f( $x2, $y2 );
            !;
        }
        $code .= qq!
                glVertex2f( $coords[-1][0], $coords[-1][1] );
                glVertex2f( $coords[0][0], $coords[0][1] );
            glEnd();
        !;
        return $code;
    };

    my $code = '';
    if( $self->glow_count > 0 ) {
        # TODO
        $code = $make_code_sub->( 1.0, $red, $green, $blue, $alpha );
    }
    else {
        $code = $make_code_sub->( 1.0, $red, $green, $blue, $alpha );
    }

    return $code;
}

sub _int_to_opengl_color
{
    my ($self, $color) = @_;
    my $red = ($color >> 24) & 0xFF;
    my $green = ($color >> 16) & 0xFF;
    my $blue = ($color >> 8) & 0xFF;
    my $alpha = $color & 0xFF;
    return ($red, $green, $blue, $alpha);
}

sub _brighten
{
    my ($self, $multiplier, $red, $green, $blue, $alpha) = @_;
    my $color = Imager::Color->new( $red, $green, $blue, $alpha );
    my ($h, $s, $v, $new_alpha) = $color->hsv;

    $v *= $multiplier;
    $v = 1.0 if $v > 1.0;

    my $hsv_color = Imager::Color->new(
        hue => $h,
        v => $v,
        s => $s,
        alpha => $new_alpha,
    );
    return $hsv_color->rgba;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Graphics::GVG::OpenGLRenderer - Take a GVG file and turn it into Perl/OpenGL code

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 circle_segments / ellipse_segments

In OpenGL, circles aren't really circles. They're polygons with a large number 
of sides, which blur together enough to look like a circle.

These attributes control how many sides those polygons will have. A circle or 
ellipse that appears larger on the screen will need to be rendered with a 
larger number of sides to maintain the illusion.

The default is 40 for both.

=head1 METHODS

=head2 make_drawer_obj

  my $opengl = $renderer->make_drawer_obj( $ast );

Given an L<Graphics::GVG::AST> object, generates a new Perl object that, when 
you call its C<draw()> method, will output the GVG description to OpenGL.

The package will be uniquely created under C<Graphics::GVG::OpenGLRenderer>.

=head2 make_code

  my $pack_code = $renderer->make_code( $ast );

Given an L<Graphics::GVG::AST> object, returns the code that can be used to 
create the same kind of Perl object made by C<make_drawer_obj()>.

=head1 LICENSE

    Copyright (c) 2016  Timm Murray
    All rights reserved.

    Redistribution and use in source and binary forms, with or without 
    modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, 
          this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright 
          notice, this list of conditions and the following disclaimer in the 
          documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.

=cut
