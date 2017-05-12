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
use Test::More tests => 4;
use strict;
use Graphics::GVG;
use Graphics::GVG::AST;
use Graphics::GVG::AST::Polygon;
use Math::Trig qw{ deg2rad pi };

my $LINES = <<'END';
    poly( #ff33ff00, 0, 0, 4.3, 6, 30.2 );
END


my $gvg = Graphics::GVG->new;
isa_ok( $gvg, 'Graphics::GVG' );

my $ast = $gvg->parse( $LINES );
isa_ok( $ast, 'Graphics::GVG::AST' );


my $expect_ast = Graphics::GVG::AST->new;
my $poly_ast = Graphics::GVG::AST::Polygon->new({
    cx => 0,
    cy => 0,
    r => 4.3,
    sides => 6,
    rotate => 30.2,
    color => 0xff33ff00,
});
$expect_ast->push_command( $poly_ast );

is_deeply( $ast, $expect_ast );

# See:
# http://stackoverflow.com/questions/7198144/how-to-draw-a-n-sided-regular-polygon-in-cartesian-coordinates
my $x_sub = sub {
    my ($side) = @_;
    return 4.3 * cos( 2 * pi * $side / 6 + deg2rad(30.2) );
};
my $y_sub = sub {
    my ($side) = @_;
    return 4.3 * sin( 2 * pi * $side / 6 + deg2rad(30.2) );
};
is_deeply( $poly_ast->coords, [
    map {[ $x_sub->( $_ ), $y_sub->( $_ ) ]} (1..6)
]);
