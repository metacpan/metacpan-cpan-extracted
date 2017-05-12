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
use Test::More tests => 3;
use strict;
use Graphics::GVG;
use Graphics::GVG::AST;
use Graphics::GVG::AST::Line;

my $LINES = <<'END';
    line( #ff33ff00, 0, 0, 1, 1 );
    line( #ff33ff00, 1, 1, -1, -1 );
    line( #ff33ff00, -1, -1, 0, 0 );
END


my $gvg = Graphics::GVG->new;
isa_ok( $gvg, 'Graphics::GVG' );

my $ast = $gvg->parse( $LINES );
isa_ok( $ast, 'Graphics::GVG::AST' );


my @lines = map { Graphics::GVG::AST::Line->new({
    x1 => $_->[0],
    y1 => $_->[1],
    x2 => $_->[2],
    y2 => $_->[3],
    color => 0xff33ff00,
}) } (
    [ 0, 0, 1, 1 ],
    [ 1, 1, -1, -1 ],
    [ -1, -1, 0, 0 ],
);
my $expect_ast = Graphics::GVG::AST->new({
    commands => \@lines,
});

is_deeply( $ast, $expect_ast );
