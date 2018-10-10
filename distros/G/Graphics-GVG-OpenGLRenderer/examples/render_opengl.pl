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
use SDL;
use SDLx::App; 
use SDL::Event;
use SDL::Events;
use SDL::Surface;
use SDL::Video;
use Graphics::GVG;
use Graphics::GVG::OpenGLRenderer;
use Math::Trig 'deg2rad';
use OpenGL qw(:all);
use Getopt::Long 'GetOptions';

use constant STEP_TIME => 0.1;
use constant WIDTH => 800;
use constant HEIGHT => 600;
use constant TITLE => 'Graphics::GVG OpenGL Render';

my $GVG_OPENGL = undef;

my $GVG_FILE = '';
my $ROTATE = 0;
my $DO_DUMP = 0;
my $SCALE = 1.0;
GetOptions(
    'rotate=i' => \$ROTATE,
    'scale=f' => \$SCALE,
    'input=s' => \$GVG_FILE,
    'dump' => \$DO_DUMP,
);
die "Need GVG file to show\n" unless $GVG_FILE;


sub make_app
{
    my $app = SDLx::App->new(
        title => TITLE,
        width => WIDTH,
        height => HEIGHT,
        depth => 24,
        gl => 1,
        exit_on_quit => 1,
        dt => STEP_TIME,
        min_t => 1 / 60,
    );
    $app->add_event_handler( \&on_event );
    $app->add_move_handler( \&on_move );
    $app->add_show_handler( \&on_show );

    $app->attribute( SDL_GL_RED_SIZE() );
    $app->attribute( SDL_GL_GREEN_SIZE() );
    $app->attribute( SDL_GL_BLUE_SIZE() );
    $app->attribute( SDL_GL_DEPTH_SIZE() );
    $app->attribute( SDL_GL_DOUBLEBUFFER() );
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glLoadIdentity();

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glShadeModel(GL_SMOOTH);
	glClearDepth(1.0);
	glDisable(GL_DEPTH_TEST);
	glBlendFunc( GL_SRC_ALPHA, GL_ONE );
	glEnable(GL_BLEND);

	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );

	glEnable(GL_TEXTURE_2D);

	glViewport( 0, 0, WIDTH, HEIGHT );
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective( 45.0, WIDTH / HEIGHT, 1.0, 100.0 );

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

    return $app;
}

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

sub make_drawer
{
    my ($ast) = @_;

    my $renderer = Graphics::GVG::OpenGLRenderer->new;
    my $drawer = $renderer->make_obj( $ast );

    return $drawer;
}

sub make_code
{
    my ($ast) = @_;

    my $renderer = Graphics::GVG::OpenGLRenderer->new;
    my ($code) = $renderer->make_code( $ast );

    return $code;
}

sub on_move
{
    my ($step, $app, $t) = @_;
    return;
}

sub on_event
{
    my ($event, $app) = @_;

    return;
}

sub on_show
{
    my ($delta, $app) = @_;

	glClear( GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT() );
	glLoadIdentity();
	glTranslatef( 0, 0, -6.0 );
	glColor3d( 1, 1, 1 );

    glPushMatrix();
        glRotatef( $ROTATE, 0.0, 0.0, 1.0 );
        glScalef( $SCALE, $SCALE, $SCALE );
        $GVG_OPENGL->draw;
    glPopMatrix();

    $app->sync;
    return;
}


{
    my $ast = make_ast( $GVG_FILE );

    if( $DO_DUMP ) {
        my $code = make_code( $ast );
        print $code;
    }
    else {
        $GVG_OPENGL = make_drawer( $ast );
        my $app = make_app();
        $app->run();
    }
}
__END__


=head1 render_opengl.pl

    render_opengl.pl \
        --input circle.gvg \
        --scale 0.4 \
        --rotate 30 \
        --dump

=head1 DESCRIPTION

Takes a GVG input script and converts it to OpenGL. By default, it opens a 
window and displays the output. Alternatively, it can also dump the Perl code 
that was generated to display the vector image.

=head1 OPTIONS

=head2 --input <circle.gvg>

Path to the GVG script to use. Required.

=head2 --scale <0.4>

Scales the displayed image.  Default is 1.0.

=head2 --rotate <30>

Rotate the displayed image by the specified number of degrees. Default is 0.

=head2 --dump

If specified, the generated Perl code will be dumped, rather than showing the 
OpenGL output in a window.
