#!perl
# Copyright (c) 2017  Timm Murray
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
use Games::Chipmunk;
use SDL;
use SDLx::App; 
use SDL::Event;
use SDL::Events;
use SDL::Surface;
use SDL::Video;
use Graphics::GVG;
use Graphics::GVG::OpenGLRenderer;
use OpenGL qw(:all);

use constant STEP_TIME => 0.1;
use constant WIDTH => 800;
use constant HEIGHT => 800;
use constant TITLE => 'Games::Chipmunk Pachinko Example';

use constant BALL_RADIUS => WIDTH / 20;
use constant PIN_START_Y => 200;
use constant PIN_START_X => 10;
use constant PIN_EVEN_OFFSET => 50;
use constant PIN_X_SPACING => 100;
use constant PIN_Y_SPACING => 80;
use constant PIN_ROWS => 5;
use constant PIN_COLS => 10;

my $GRAVITY = cpv( 0, 100 );
my $SPACE;


package Local::StaticCircle;
use Moose;
use OpenGL qw(:all);
use Games::Chipmunk;
use Math::Trig 'deg2rad';

has 'r' => (
    is => 'ro',
    isa => 'Int',
    default => 1,
);
has 'x' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);
has 'y' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);
has 'space' => (
    is => 'ro',
    required => 1,
);
has 'friction' => (
    is => 'ro',
    isa => 'Maybe[Num]',
);
has '_cp_shape' => (
    is => 'rw',
);
has '_cp_body' => (
    is => 'rw',
);

sub BUILD
{
    my ($self) = @_;

    my $x = $self->x;
    my $y = $self->y;
    my $radius = $self->r;
    my $space = $self->space;

    my $body = $self->_make_body( $radius, $CPV_ZERO, $space );
    cpBodySetPosition( $body, cpv( $x, $y ) );

    my $shape = cpCircleShapeNew(
        $body,
        $radius,
        $CPV_ZERO,
    );
    cpShapeSetFriction( $shape, $self->friction )
        if defined $self->friction;

    cpSpaceAddShape( $space, $shape );
    $self->_cp_shape( $shape );
    $self->_cp_body( $body );
    return $self;
}

sub _make_body
{
    my ($self, $radius, $cpv, $space) = @_;
    my $body = cpSpaceGetStaticBody( $space );
    return $body;
}

sub draw
{
    my ($self, $app) = @_;
    my $x = main::screen_to_opengl_coord_x( $self->x );
    my $y = main::screen_to_opengl_coord_y( $self->y );
    my $r = main::screen_to_opengl_coord_abs( $self->r );

    glLineWidth( 1 );
    glColor4ub( 255, 0, 255, 255 );

    glBegin( GL_LINE_LOOP );
    foreach my $i (0 .. 359) {
        my $rad = deg2rad( $i );
        glVertex2f( cos($rad) * $r + $x, sin($rad) * $r + $y );
    }
    glEnd();
    return;
}

sub apply_physics
{
    my ($self, $delta_t) = @_;
    # Static body, do nothing
    return;
}

sub DEMOLISH
{
    my ($self) = @_;
    cpShapeFree( $self->_cp_shape );
    # Static bodies do not need to free the body, it's automatic in Chipmunk
    return;
}


package Local::Circle;
use Moose;
use Games::Chipmunk;
extends 'Local::StaticCircle';

sub _make_body
{
    my ($self, $radius, $cpv, $space) = @_;
    my $moment = cpMomentForCircle( 1, 0, $radius, $CPV_ZERO );
    my $body = cpBodyNew( 1, $moment );
    cpSpaceAddBody( $space, $body );
    return $body;
}

sub apply_physics
{
    my ($self, $delta_t) = @_;
    my $pos = cpBodyGetPosition( $self->_cp_body );
    $self->x( $pos->x );
    $self->y( $pos->y );
    return;
}

sub DEMOLISH
{
    my ($self) = @_;
    cpBodyFree( $self->_cp_body );
    return;
}


package Local::Line;
use Moose;
use OpenGL qw(:all);
use Games::Chipmunk;

has 'x1' => (
    is => 'ro',
    isa => 'Int',
    default => 0,
);
has 'y1' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);
has 'x2' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);
has 'y2' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);
has 'space' => (
    is => 'ro',
    required => 1,
);
has '_cp_shape' => (
    is => 'rw',
);
has 'friction' => (
    is => 'ro',
    isa => 'Maybe[Num]',
);

sub BUILD
{
    my ($self) = @_;

    my $space = $self->space;
    my $segment = cpSegmentShapeNew(
        cpSpaceGetStaticBody( $space ),
        cpv( $self->x1, $self->y1 ),
        cpv( $self->x2, $self->y2 ),
        0,
    );
    $self->_cp_shape( $segment );
    cpShapeSetFriction( $segment, $self->friction )
        if defined $self->friction;

    cpSpaceAddShape( $space, $segment );
    return $self;
}

sub draw
{
    my ($self, $app) = @_;
    my $x1 = main::screen_to_opengl_coord_x( $self->x1 );
    my $x2 = main::screen_to_opengl_coord_x( $self->x2 );
    my $y1 = main::screen_to_opengl_coord_y( $self->y1 );
    my $y2 = main::screen_to_opengl_coord_y( $self->y2 );

    glLineWidth( 1 );
    glColor4ub( 255, 255, 0, 255 );

    glBegin( GL_LINES );
        glVertex2f( $x1, $y1 );
        glVertex2f( $x2, $y2 );
    glEnd();

    return;
}

sub apply_physics
{
    my ($self, $delta_t) = @_;
    # Does not move
    return;
}

sub DEMOLISH
{
    my ($self) = @_;
    cpShapeFree( $self->_cp_shape );
    return;
}



package main;
my @shapes;


sub screen_to_opengl_coord_x
{
    my ($coord) = @_;
    return map_range( 0, WIDTH, -1, 1, $coord );
}

sub screen_to_opengl_coord_abs
{
    my ($coord) = @_;
    return map_range( 0, WIDTH, 0, 1, $coord ) * 2;
}

sub screen_to_opengl_coord_y
{
    my ($coord) = @_;
    return map_range( HEIGHT, 0, -1, 1, $coord );
}

sub map_range
{
    my ($input_start, $input_end, $output_start, $output_end, $input) = @_;
    # See: http://stackoverflow.com/questions/5731863/mapping-a-numeric-range-onto-another
    my $input_range = $input_end - $input_start;
    my $output_range = $output_end - $output_start;

    my $output = ($input - $input_start)
        * $output_range / $input_range + $output_start;
    return $output;
}

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
	gluPerspective( 20.0, WIDTH / HEIGHT, 1.0, 100.0 );

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

    return $app;
}

{
    my $space;

    sub make_physics
    {
        $space = cpSpaceNew();
        cpSpaceSetGravity($space, $GRAVITY);

        my $ground = Local::Line->new({
            x1 => 0,
            y1 => HEIGHT - 80,
            x2 => WIDTH,
            y2 => HEIGHT - 10,
            space => $space,
            friction => 0.2,
        });
        push @shapes, $ground;

        my $left_wall = Local::Line->new({
            x1 => 0,
            y1 => 0,
            x2 => 0,
            y2 => HEIGHT,
            space => $space,
            friction => 0.2,
        });
        push @shapes, $left_wall;

        my $right_wall = Local::Line->new({
            x1 => WIDTH,
            y1 => 0,
            x2 => WIDTH,
            y2 => HEIGHT,
            space => $space,
            friction => 0.2,
        });
        push @shapes, $right_wall;

        make_pins( PIN_ROWS, PIN_COLS );

        return;
    }

    sub make_pins
    {
        my ($rows, $cols) = @_;

        my $y = PIN_START_Y;
        foreach my $row (1 .. $rows) {
            my $x = PIN_START_X;
            $x += PIN_EVEN_OFFSET if $row % 2 == 0; # offset even rows

            foreach my $col (1 .. $cols) {
                my $pin = Local::StaticCircle->new({
                    x => $x,
                    y => $y,
                    r => 3,
                    space => $space,
                    friction => 0.1,
                });
                push @shapes, $pin;

                $x += PIN_X_SPACING;
            }

            $y += PIN_Y_SPACING;
        }

        return;
    }

    sub cleanup
    {
        # Force everything to go out of scope
        undef $_ for @shapes;
        cpSpaceFree($space);
    }

    sub on_move
    {
        my ($step, $app, $t) = @_;
        cpSpaceStep( $space, $step );

        foreach my $shape (@shapes) {
            $shape->apply_physics( $step );
        }

        return;
    }

    sub on_event
    {
        my ($event, $app) = @_;

        if( $event->type == SDL_MOUSEBUTTONDOWN 
            && $event->button_button == SDL_BUTTON_LEFT ) {
            my $x = $event->button_x;
            my $y = $event->button_y;

            my $ball = Local::Circle->new({
                x => $x,
                y => $y,
                r => BALL_RADIUS,
                space => $space,
                friction => 0.1,
            });
            push @shapes, $ball;
        }

        return;
    }
}

sub on_show
{
    my ($delta, $app) = @_;

	glClear( GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT() );
	glLoadIdentity();
	glTranslatef( 0, 0, -6.0 );
	glColor3d( 1, 1, 1 );

    foreach my $shape (@shapes) {
        glPushMatrix();
        $shape->draw( $app );
        glPopMatrix();
    }

    $app->sync;
    return;
}


{
    my $app = make_app();
    make_physics();
    $app->run();
    cleanup();
}
