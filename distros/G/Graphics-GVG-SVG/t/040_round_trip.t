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
use Test::More tests => 19;
use strict;
use warnings;
use Graphics::GVG;
use Graphics::GVG::SVG;

my $SCRIPT = <<'END';
    circle( #993399ff, 0.5, 0.25, 0.3 );
    line( #993399ff, 0.25, 0.25, -0.75, -0.75 );
END


my $gvg = Graphics::GVG->new;
my $convert_ast = $gvg->parse( $SCRIPT );
my $gvg_to_svg = Graphics::GVG::SVG->new;
my $svg = $gvg_to_svg->make_svg( $convert_ast );

my ($group) = $svg->getFirstChild->getFirstChild;
my @svg_lines = $group->getElements( 'line' );
my @svg_circles = $group->getElements( 'circle' );

cmp_ok( scalar @svg_lines, '==', 1, "Lines drawn in SVG" );
cmp_ok( scalar @svg_circles, '==', 1, "Circles drawn in SVG" );

cmp_ok( $svg_circles[0]->getAttribute( 'r' ), '==', 60,
    "SVG Circle has correct radius" );
cmp_ok( $svg_circles[0]->getAttribute( 'cx' ), '==', 300,
    "SVG Circle has correct x coord" );
cmp_ok( $svg_circles[0]->getAttribute( 'cy' ), '==', 150,
    "SVG Circle has correct y coord" );

cmp_ok( $svg_lines[0]->getAttribute( 'x1' ), '==', 250,
    "SVG Line has correct x1" );
cmp_ok( $svg_lines[0]->getAttribute( 'y1' ), '==', 150,
    "SVG Line has correct y1" );
cmp_ok( $svg_lines[0]->getAttribute( 'x2' ), '==', 50,
    "SVG Line has correct x2" );
cmp_ok( $svg_lines[0]->getAttribute( 'y2' ), '==', 350,
    "SVG Line has correct y2" );


my $ast = $gvg_to_svg->make_gvg( $svg->xmlify( -standalone => 'no' ) );
my @commands = @{ $ast->commands };
my @lines = grep { ref($_) eq 'Graphics::GVG::AST::Line' } @commands;
my @circles = grep { ref($_) eq 'Graphics::GVG::AST::Circle' } @commands;

cmp_ok( scalar @lines, '==', 1, "Lines drawn" );
cmp_ok( scalar @circles, '==', 1, "Circles drawn" );

cmp_ok( $circles[0]->cx, '==', 0.5, "Center X of circle set" );
cmp_ok( $circles[0]->cy, '==', 0.25, "Center Y of circle set" );
cmp_ok( $circles[0]->r, '==', 0.3, "Radius of circle set" );
cmp_ok( $circles[0]->color, '==', 0x993399ff, "Color of circle set" );

cmp_ok( $lines[0]->x1, '==', 0.25, "X1 of line set" );
cmp_ok( $lines[0]->y1, '==', 0.25, "Y1 of line set" );
cmp_ok( $lines[0]->x2, '==', -0.75, "X2 of line set" );
cmp_ok( $lines[0]->y2, '==', -0.75, "Y1 of line set" );
