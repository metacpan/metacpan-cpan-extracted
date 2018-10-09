=begin comment

   raylib [core] example - Initialize 3d mode

   This example has been created using raylib 1.0 (www.raylib.com)
   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)

   Copyright (c) 2014 Ramon Santamaria (@raysan5)

=cut

# NOTE This is referenced as Graphics::Raylib::XS example in docs,
#      so don't edit to use Graphics::Raylib::Util::camera3d
use Test::More;

use Graphics::Raylib '+family';
use Graphics::Raylib::XS ':all';
use Graphics::Raylib::Util 'vector';

my $g = Graphics::Raylib->window(400, 225);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};


my $camera = \(${vector(0, 10, 10)}.${vector(0, 0, 0)}.${vector(0, 1, 0)}.pack('f2', 45.0, 0));
bless $camera, 'Graphics::Raylib::XS::Camera3D';
# alternatively:
# my $camera = Graphics::Raylib::Util::camera3d(
#     position => [0,10,10], target => [0,0,0], up => [0,1,0], fovy => 45.0
# );

my $cubePosition = vector(0, 0, 0);

$g->fps(60);
my $i = 0;
while (!$g->exiting && $i++ != 60) {
    Graphics::Raylib::draw {
        $g->clear;

        BeginMode3D($camera);

        DrawCube($cubePosition, 2.0, 2.0, 2.0, RED);
        DrawCubeWires($cubePosition, 2.0, 2.0, 2.0, MAROON);
        DrawGrid(10, 1.0);

        EndMode3D();

        DrawText("Welcome to the third dimension!", 10, 40, 20, DARKGRAY);
        Graphics::Raylib::Text::FPS->draw;
    };
}
sleep 1;
ok 1;
done_testing
