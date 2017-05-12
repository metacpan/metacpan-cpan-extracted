#!perl
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
use strict;
use warnings;
use Graphics::GVG;
use Graphics::GVG::SVG;
use Getopt::Long 'GetOptions';

use constant WIDTH => 400;
use constant HEIGHT => 400;


my $GVG_FILE = '';
GetOptions(
    'input=s' => \$GVG_FILE,
);
die "Need GVG file to show\n" unless $GVG_FILE;


sub make_ast
{
    my ($gvg_file) = @_;
    my $gvg_script = '';
    open( my $in, '<', $gvg_file ) or die "Can't open $gvg_file: $!\n";
    while(<$in>) {
        $gvg_script .= $_;
    }
    close $in;

    my $gvg_parser = Graphics::GVG->new;
    my $ast = $gvg_parser->parse( $gvg_script );

    return $ast;
}

{
    my $ast = make_ast( $GVG_FILE );

    my $gvg_to_svg = Graphics::GVG::SVG->new;
    my $svg = $gvg_to_svg->make_svg( $ast );

    print $svg->xmlify;
}
__END__


=head1 render_svg.pl

    render_svg.pl --input circle.gvg 

=head1 DESCRIPTION

Takes a GVG input script and converts it to SVG.

=head1 OPTIONS

=head2 --input <circle.gvg>

Path to the GVG script to use. Required.

=cut
