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
#!/usr/bin/perl
use strict;
use warnings;
use Graphics::GVG;
use Graphics::GVG::SVG;

my $INPUT_GVG_FILE = shift or die "Need input GVG file\n";
die "Input file $INPUT_GVG_FILE does not exist\n" if ! -e $INPUT_GVG_FILE;


sub get_file
{
    my ($file) = @_;

    open( my $in, '<', $file ) or die "Can't open $file: $!\n";
    my $contents = '';
    while( <$in> ) {
        $contents .= $_;
    }
    close $in;

    return $contents;
}


{
    my $gvg_contents = get_file( $INPUT_GVG_FILE );

    my $gvg = Graphics::GVG->new;
    my $ast = $gvg->parse( $gvg_contents );

    my $gvg_to_svg = Graphics::GVG::SVG->new;
    my $svg = $gvg_to_svg->make_svg( $ast );

    print $svg->xmlify;
}
