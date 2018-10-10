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
package Game::Asset::GVG::OpenGL;
$Game::Asset::GVG::OpenGL::VERSION = '0.2';
# ABSTRACT: Load GVG files from a Game::Asset archive and convert to OpenGL
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Graphics::GVG;
use Graphics::GVG::OpenGLRenderer;


use constant type => 'opengl';

with 'Game::Asset::Type';


has 'opengl' => (
    is => 'ro',
    writer => '_set_opengl',
);

sub _process_content
{
    my ($self, $content) = @_;
    my $gvg = Graphics::GVG->new; # TODO include paths
    my $ast = $gvg->parse( $content );

    my $renderer = Graphics::GVG::OpenGLRenderer->new;
    my $obj = $renderer->make_obj( $ast );
    $self->_set_opengl( $obj );

    return;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Game::Asset::GVG::OpenGL - Load GVG files from a Game::Asset archive and convert to OpenGL 

=head1 SYNOPSIS

    my $asset = Game::Asset->new({
        file => 't_data/test.zip',
    });
    my $opengl = $asset->get_by_name( 'test' );
    
    my $opengl_obj = $opengl->opengl;
    # Setup an OpenGL context, then do:
    $opengl_obj->draw;


    # In your index.yml for the Game::Asset archive, add:
    gvg: Game::Asset::GVG::OpenGL

=head1 DESCRIPTION

L<Game::Asset> loads files and gives them to you as Perl objects. 
L<Graphics::GVG::OpenGLRenderer> takes GVG files and turns them into a Perl 
class that can be used to render the vectors in OpenGL. This module glues the 
two together.

=head1 ATTRIBUTES

=head2 opengl

Returns the object which can be used to draw the data in the GVG file using 
OpenGL. Once an OpenGL context is set, you can call C<draw()> on this 
object to draw the GVG.

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
