# Copyright (c) 2016  Timm Murray
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
package Graphics::GVG::SVG;
$Graphics::GVG::SVG::VERSION = '0.4';
# ABSTRACT: Convert GVG into SVG
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Graphics::GVG::AST;
use Graphics::GVG::AST::Line;
use Graphics::GVG::AST::Circle;
use Graphics::GVG::AST::Ellipse;
use Graphics::GVG::AST::Glow;
use Graphics::GVG::AST::Polygon;
use Graphics::GVG::AST::Rect;
use SVG;
use XML::LibXML;


has 'width' => (
    is => 'ro',
    isa => 'Int',
    default => 400,
    writer => '_set_width',
);
has 'height' => (
    is => 'ro',
    isa => 'Int',
    default => 400,
    writer => '_set_height',
);

sub make_svg
{
    my ($self, $ast) = @_;
    my $svg = SVG->new(
        width => $self->width,
        height => $self->height,
    );
    my $group = $svg->group(
        id => 'main_group',
    );
    $self->_ast_to_svg( $ast, $group );

    return $svg;
}

sub make_gvg
{
    my ($self, $svg_data) = @_;
    my $xml = XML::LibXML->load_xml( string => $svg_data );

    my ($svg_tag) = $xml->getElementsByTagName( 'svg' );
    my $width = $svg_tag->getAttribute( 'width' );
    my $height = $svg_tag->getAttribute( 'height' );
    # Ignore units
    ($width) = $width =~ /\A(\d+)/x;
    ($height) = $height =~ /\A(\d+)/x;
    $self->_set_width( $width );
    $self->_set_height( $height );

    my $ast = $self->_svg_to_ast( $xml );
    return $ast;
}

sub _svg_to_ast
{
    my ($self, $xml) = @_;
    my $main_group = $xml->getElementById( 'main_group' );
    my $ast = Graphics::GVG::AST->new;

    $self->_svg_to_ast_handle_lines( $xml, $ast );
    $self->_svg_to_ast_handle_circles( $xml, $ast );
    $self->_svg_to_ast_handle_polygons( $xml, $ast );
    $self->_svg_to_ast_handle_rects( $xml, $ast );
    $self->_svg_to_ast_handle_ellipses( $xml, $ast );

    return $ast;
}

sub _svg_to_ast_handle_lines
{
    my ($self, $xml, $ast) = @_;
    my @nodes = $xml->getElementsByTagName( 'line' );
    
    foreach my $node (@nodes) {
        my $x1 = $self->_svg_coord_convert_x( $node->getAttribute( 'x1' ) );
        my $y1 = $self->_svg_coord_convert_y( $node->getAttribute( 'y1' ) );
        my $x2 = $self->_svg_coord_convert_x( $node->getAttribute( 'x2' ) );
        my $y2 = $self->_svg_coord_convert_y( $node->getAttribute( 'y2' ) );
        my $cmd = Graphics::GVG::AST::Line->new({
            x1 => $x1,
            y1 => $y1,
            x2 => $x2,
            y2 => $y2,
            color => $self->_get_color_for_element( $node ),
        });

        my $push_to = $self->_svg_decide_type( $ast, $node );
        $push_to->push_command( $cmd );
    }
    return;
}

sub _svg_to_ast_handle_circles
{
    my ($self, $xml, $ast) = @_;
    my @nodes = $xml->getElementsByTagName( 'circle' );

    foreach my $node (@nodes) {
        my $cmd = Graphics::GVG::AST::Circle->new({
            cx => $self->_svg_coord_convert_x( $node->getAttribute( 'cx' ) ),
            cy => $self->_svg_coord_convert_y( $node->getAttribute( 'cy' ) ),
            # Arbitrarily use width
            r => $self->_svg_convert_width( $node->getAttribute( 'r' ) ),
            color => $self->_get_color_for_element( $node ),
        });

        my $push_to = $self->_svg_decide_type( $ast, $node );
        $push_to->push_command( $cmd );
    }
    return;
}

sub _svg_to_ast_handle_polygons
{
    my ($self, $xml, $ast) = @_;
    my @nodes = $xml->getElementsByTagName( 'polygon' );

    foreach my $node (@nodes) {
        my $color = $self->_get_color_for_element( $node );
        $self->_svg_convert_polygon_to_lines( $node, $ast );
    }
    return;
}

sub _svg_to_ast_handle_rects
{
    my ($self, $xml, $ast) = @_;
    my @nodes = $xml->getElementsByTagName( 'rect' );

    foreach my $node (@nodes) {
        my $cmd = Graphics::GVG::AST::Rect->new({
            x => $self->_svg_coord_convert_x( $node->getAttribute( 'x' ) ),
            y => $self->_svg_coord_convert_y( $node->getAttribute( 'y' ) ),
            width => $self->_svg_convert_width( 
                $node->getAttribute( 'width' ) ),
            height => $self->_svg_convert_height(
                $node->getAttribute( 'height' ) ),
            color => $self->_get_color_for_element( $node ),
        });

        my $push_to = $self->_svg_decide_type( $ast, $node );
        $push_to->push_command( $cmd );
    }
    return;
}

sub _svg_to_ast_handle_ellipses
{
    my ($self, $xml, $ast) = @_;
    my @nodes = $xml->getElementsByTagName( 'ellipse' );

    foreach my $node (@nodes) {
        my $cmd = Graphics::GVG::AST::Ellipse->new({
            cx => $self->_svg_coord_convert_x( $node->getAttribute( 'cx' ) ),
            cy => $self->_svg_coord_convert_y( $node->getAttribute( 'cy' ) ),
            rx => $self->_svg_convert_width( $node->getAttribute( 'rx' ) ),
            ry => $self->_svg_convert_height( $node->getAttribute( 'ry' ) ),
            color => $self->_get_color_for_element( $node ),
        });

        my $push_to = $self->_svg_decide_type( $ast, $node );
        $push_to->push_command( $cmd );
    }
    return;
}

sub _svg_convert_polygon_to_lines
{
    my ($self, $poly, $ast) = @_;
    my $color = $self->_get_color_for_element( $poly );
    my $points_str = $poly->getAttribute( 'points' );
    my @points = split /\s+/, $points_str;

    foreach my $i (0 .. $#points) {
        my $next_i = $i == $#points
            ? 0
            : $i + 1;
        my ($x1, $y1) = $points[$i] =~ /\A (\d+),(\d+) \z/x;
        my ($x2, $y2) = $points[$next_i] =~ /\A (\d+),(\d+) \z/x;

        my $cmd = Graphics::GVG::AST::Line->new({
            x1 => $self->_svg_coord_convert_x( $x1 ),
            y1 => $self->_svg_coord_convert_y( $y1 ),
            x2 => $self->_svg_coord_convert_x( $x2 ),
            y2 => $self->_svg_coord_convert_y( $y2 ),
            color => $color,
        });

        my $push_to = $self->_svg_decide_type( $ast, $poly );
        $push_to->push_command( $cmd );
    }

    return;
}

sub _svg_decide_type
{
    my ($self, $ast, $node) = @_;
    my $class = $node->getAttribute( 'class' );
    return $ast if ! defined $class;

    my $type = $ast;
    my %classes = map { $_ => 1 }
        split /\s+/, $class;

    if( exists $classes{glow} ) {
        $type = Graphics::GVG::AST::Glow->new;
        $ast->push_command( $type );
    }

    return $type;
}

sub _get_color_for_element
{
    my ($self, $node) = @_;
    # There are many ways to set the color in SVG, but Inkscape sets it in 
    # using the stroke selector using the CSS style attribute. Since we're 
    # mainly targeting Inkscape, we'll go with that.
    my $style = $node->getAttribute( 'style' );
    my ($hex_color) = $style =~ /stroke: \s* \#([0-9abcdefABCDEF]+)/x;
    my $color = hex $hex_color;
    $color <<= 8;
    $color |= 0x000000ff;
    return $color;
}

sub _ast_to_svg
{
    my ($self, $ast, $group) = @_;

    foreach my $cmd (@{ $ast->commands }) {
        my $ret = '';
        if(! ref $cmd ) {
            warn "Not a ref, don't know what to do with '$_'\n";
        }
        elsif( $cmd->isa( 'Graphics::GVG::AST::Line' ) ) {
            $self->_draw_line( $cmd, $group );
        }
        elsif( $cmd->isa( 'Graphics::GVG::AST::Rect' ) ) {
            $self->_draw_rect( $cmd, $group );
        }
        elsif( $cmd->isa( 'Graphics::GVG::AST::Polygon' ) ) {
            $self->_draw_poly( $cmd, $group );
        }
        elsif( $cmd->isa( 'Graphics::GVG::AST::Circle' ) ) {
            $self->_draw_circle( $cmd, $group );
        }
        elsif( $cmd->isa( 'Graphics::GVG::AST::Ellipse' ) ) {
            $self->_draw_ellipse( $cmd, $group );
        }
        elsif( $cmd->isa( 'Graphics::GVG::AST::Glow' ) ) {
            $self->_ast_to_svg( $cmd, $group );
        }
        else {
            warn "Don't know what to do with " . ref($_) . "\n";
        }
    }

    return;
}

sub _draw_line
{
    my ($self, $cmd, $group) = @_;
    $group->line(
        x1 => $self->_coord_convert_x( $cmd->x1 ),
        y1 => $self->_coord_convert_y( $cmd->y1 ),
        x2 => $self->_coord_convert_x( $cmd->x2 ),
        y2 => $self->_coord_convert_y( $cmd->y2 ),
        style => {
            $self->_default_style,
            stroke => $self->_color_to_style( $cmd->color ),
        },
    );
    return;
}

sub _draw_rect
{
    my ($self, $cmd, $group) = @_;
    $group->rect(
        x => $self->_coord_convert_x( $cmd->x ),
        y => $self->_coord_convert_y( $cmd->y ),
        width => $self->_coord_convert_x( $cmd->x ),
        height => $self->_coord_convert_y( $cmd->y ),
        style => {
            $self->_default_style,
            stroke => $self->_color_to_style( $cmd->color ),
        },
    );
    return;
}

sub _draw_poly
{
    my ($self, $cmd, $group) = @_;
    my (@x_coords, @y_coords);
    foreach my $coords (@{ $cmd->coords }) {
        push @x_coords, $self->_coord_convert_x( $coords->[0] );
        push @y_coords, $self->_coord_convert_y( $coords->[1] );
    }

    my $points = $group->get_path(
        x => \@x_coords,
        y => \@y_coords,
        -type => 'polygon',
    );
    $group->polygon(
        %$points,
        style => {
            $self->_default_style,
            stroke => $self->_color_to_style( $cmd->color ),
        },
    );
    return;
}

sub _draw_circle
{
    my ($self, $cmd, $group) = @_;
    $group->circle(
        cx => $self->_coord_convert_x( $cmd->cx ),
        cy => $self->_coord_convert_y( $cmd->cy ),
        # Arbitrarily say the radius is according to the x coord.
        r => $self->_coord_convert_abs( $cmd->r, $self->width / 2 ),
        style => {
            $self->_default_style,
            stroke => $self->_color_to_style( $cmd->color ),
        },
    );
    return;
}

sub _draw_ellipse
{
    my ($self, $cmd, $group) = @_;
    $group->circle(
        cx => $self->_coord_convert_x( $cmd->cx ),
        cy => $self->_coord_convert_y( $cmd->cy ),
        rx => $self->_coord_convert_x( $cmd->rx ),
        ry => $self->_coord_convert_y( $cmd->ry ),
        style => {
            $self->_default_style,
            stroke => $self->_color_to_style( $cmd->color ),
        },
    );
    return;
}

sub _default_style
{
    my ($self) = @_;
    my %style = (
        fill => 'none',
    );
    return %style;
}

sub _color_to_style
{
    my ($self, $color) = @_;
    my $rgb = $color >> 8;
    my $hex = sprintf '%x', $rgb;
    return '#' . $hex;
}

sub _coord_convert_x
{
    my ($self, $coord) = @_;
    return $self->_coord_convert( $coord, $self->width );
}

sub _coord_convert_y
{
    my ($self, $coord) = @_;
    my $normalized_coord = (-($coord - 1)) / 2;
    my $final_coord = sprintf '%.0f', $self->height * $normalized_coord;
    return $final_coord;
}

sub _coord_convert_abs
{
    my ($self, $coord, $total_size) = @_;
    return $coord * $total_size;
}

sub _svg_coord_convert_x
{
    my ($self, $coord) = @_;
    my $new_coord = (($coord / $self->width) * 2) - 1;
    return $new_coord;
}

sub _svg_coord_convert_y
{
    my ($self, $coord) = @_;
    my $half_height = $self->height / 2;
    my $new_coord = -(($coord - $half_height) / $half_height);
    return $new_coord;
}

sub _svg_convert_width
{
    my ($self, $coord) = @_;
    my $new_coord = $coord / ($self->width / 2);
    return $new_coord;
}

sub _svg_convert_height
{
    my ($self, $coord) = @_;
    my $new_coord = $coord / ($self->height / 2);
    return $new_coord;
}

sub _coord_convert
{
    my ($self, $coord, $max) = @_;
    my $percent = ($coord + 1) / 2;
    my $final_coord = sprintf '%.0f', $max * $percent;
    return $final_coord;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Graphics::GVG::SVG - Convert GVG into SVG

=head1 SYNOPSIS

    use Graphics::GVG;
    use Graphics::GVG::SVG;
    
    my $SCRIPT = <<'END';
        %color = #993399ff;
        circle( %color, 0.5, 0.25, 0.3 );

        glow {
            line( %color, 0.25, 0.25, 0.75, 0.75 );
            line( %color, 0.75, 0.75, 0.75, -0.75 );
            line( %color, 0.75, -0.75, 0.25, 0.25 );
        }

        %color = #88aa88ff;
        poly( %color, -0.25, -0.25, 0.6, 6, 0 );
    END
    
    
    my $gvg = Graphics::GVG->new;
    my $ast = $gvg->parse( $SCRIPT );
    
    my $gvg_to_svg = Graphics::GVG::SVG->new;
    my $svg = $gvg_to_svg->make_svg( $ast );

=head1 DESCRIPTION

Takes a L<Graphics::GVG::AST> and converts it into an SVG

=head1 METHODS

=head2 make_svg

  $gvg_to_svg->make_svg( $ast );

Takes a L<Graphics::GVG::AST> object.  Returns the same representation as an 
L<SVG> object.

=head1 SEE ALSO

=over 4

=item * L<Graphics::GVG>

=item * L<SVG>

=back

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
