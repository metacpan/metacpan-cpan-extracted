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
use Test::More tests => 1;
use strict;
use Graphics::GVG;
use Graphics::GVG::AST;
use Graphics::GVG::AST::Line;

my $GVG_SCRIPT = <<'END';
    %color = #993399ff;
    circle( %color, 0.5, 0.25, 0.3 );

    glow {
        %color = #33ff33ff;
        line( %color, 0.25, 0.25, 0.75, 0.75 );
        line( %color, 0.75, 0.75, 0.75, -0.75 );
        line( %color, 0.75, -0.75, 0.25, 0.25 );
    }

    %color = #88aa88ff;
    poly( %color, -0.25, -0.25, 0.6, 6, 0 );
END


my $gvg = Graphics::GVG->new;
my $ast = $gvg->parse( $GVG_SCRIPT );
my $gvg_string = $ast->to_string;

my $expect_gvg = <<'END';
circle( #993399ff, 0.5, 0.25, 0.3 );
glow {
line( #33ff33ff, 0.25, 0.25, 0.75, 0.75 );
line( #33ff33ff, 0.75, 0.75, 0.75, -0.75 );
line( #33ff33ff, 0.75, -0.75, 0.25, 0.25 );
}
poly( #88aa88ff, -0.25, -0.25, 0.6, 6, 0 );
END
cmp_ok( $expect_gvg, 'eq', $gvg_string, "Can output AST as a GVG script" );
