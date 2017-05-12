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
use Test::More tests => 16;
use strict;
use warnings;
use Graphics::GVG::SVG;


use constant SVG_FILE => 't_data/many_shapes.svg';

my $SVG_DATA = '';
open( my $in, '<', SVG_FILE ) or die "Can't open " . SVG_FILE . ": $!\n";
while( my $line = <$in> ) {
    $SVG_DATA .= $line;
}
close $in;


my $gvg_to_svg = Graphics::GVG::SVG->new;
my $ast = $gvg_to_svg->make_gvg( $SVG_DATA );

cmp_ok( $gvg_to_svg->width, '==', 400, "Width parsed" );
cmp_ok( $gvg_to_svg->height, '==', 400, "Height parsed" );

my @commands = @{ $ast->commands };
my @lines = grep { ref($_) eq 'Graphics::GVG::AST::Line' } @commands;
my @circles = grep { ref($_) eq 'Graphics::GVG::AST::Circle' } @commands;
my @ellipses = grep { ref($_) eq 'Graphics::GVG::AST::Ellipse' } @commands;
my @glow = grep { ref($_) eq 'Graphics::GVG::AST::Glow' } @commands;

cmp_ok( scalar @lines, '==', 9, "Lines drawn, with polygon becoming lines" );
cmp_ok( scalar @circles, '==', 1, "Circles drawn" );
cmp_ok( scalar @glow, '==', 1, "Glow effects drawn" );
cmp_ok( scalar @ellipses, '==', 1, "Ellipses drawn" );

cmp_ok( $circles[0]->cx, '==', 0.5, "Center X of circle set" );
cmp_ok( $circles[0]->cy, '==', -0.25, "Center Y of circle set" );
cmp_ok( $circles[0]->r, '==', 0.3, "Radius of circle set" );
cmp_ok( $circles[0]->color, '==', 0x993399ff, "Color of circle set" );

my @rects = grep { ref($_) eq 'Graphics::GVG::AST::Rect' }
    @{ $glow[0]->commands };
cmp_ok( scalar @rects, '==', 1, "One rect under glow" );
cmp_ok( $rects[0]->x, '==', -0.5, "X coord of rect set" );
cmp_ok( $rects[0]->y, '==', -0.53, "Y coord of rect set" );
cmp_ok( $rects[0]->width, '==', 0.465, "Width of rect set" );
cmp_ok( $rects[0]->height, '==', 0.275, "Height of rect set" );
cmp_ok( $rects[0]->color, '==', 0x829abfff, "Color of rect set" );
