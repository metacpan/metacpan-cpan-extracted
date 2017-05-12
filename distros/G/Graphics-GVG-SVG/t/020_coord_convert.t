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
use Test::More tests => 10;
use strict;
use warnings;
use Graphics::GVG::SVG;

my $svg = Graphics::GVG::SVG->new({
    width => 100,
    height => 200,
});

cmp_ok( $svg->_coord_convert_x( -1 ), '==', 0, "Convert X -1" );
cmp_ok( $svg->_coord_convert_y( -1 ), '==', 200, "Convert Y -1" );

cmp_ok( $svg->_coord_convert_x( 1 ), '==', 100, "Convert X 1" );
cmp_ok( $svg->_coord_convert_y( 1 ), '==', 0, "Convert Y 1" );

cmp_ok( $svg->_coord_convert_x( 0 ), '==', 50, "Convert X 0" );
cmp_ok( $svg->_coord_convert_y( 0 ), '==', 100, "Convert Y 0" );

cmp_ok( $svg->_coord_convert_x( 0.75 ), '==', 88, "Convert X 0.75" );
cmp_ok( $svg->_coord_convert_y( 0.75 ), '==', 25, "Convert Y 0.75" );

cmp_ok( $svg->_coord_convert_x( -0.75 ), '==', 12, "Convert X -0.75" );
cmp_ok( $svg->_coord_convert_y( -0.75 ), '==', 175, "Convert Y -0.75" );
