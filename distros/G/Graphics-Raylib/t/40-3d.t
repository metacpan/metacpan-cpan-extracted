=begin comment

   raylib [core] example - Initialize 3d mode

   This example has been created using raylib 1.0 (www.raylib.com)
   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)

   Copyright (c) 2014 Ramon Santamaria (@raysan5)

=cut

# NOTE This is referenced as Graphics::Raylib::XS example in docs,
#      so don't edit to use Graphics::Raylib::Util::camera
use Test::More;

use Graphics::Raylib '+family';
use Graphics::Raylib::XS ':all';
use Graphics::Raylib::Util 'vector';

my $g = Graphics::Raylib->window(400, 225);
plan skip_all => 'No graphic device' if !$g or defined $ENV{NO_GRAPHICAL_TEST} or defined $ENV{NO_GRAPHICAL_TESTS};


my $camera = \(${vector(0, 10, 10)}.${vector(0, 0, 0)}.${vector(0, 1, 0)}.pack('f', 45.0));
bless $camera, 'Graphics::Raylib::XS::Camera';
# alternatively:
# my $camera = Graphics::Raylib::Util::camera(
#     position => [0,10,10], target => [0,0,0], up => [0,1,0], fovy => 45.0
# );

my $cubePosition = vector(0, 0, 0);

$g->fps(60);

#while (!$g->exiting) {
    Graphics::Raylib::draw {
        $g->clear;

        Begin3dMode($camera);

        DrawCube($cubePosition, 2.0, 2.0, 2.0, RED);
        DrawCubeWires($cubePosition, 2.0, 2.0, 2.0, MAROON);
        DrawGrid(10, 1.0);

        End3dMode();

        DrawText("Welcome to the third dimension!", 10, 40, 20, DARKGRAY);
        Graphics::Raylib::Text::FPS->draw;
    };
#}
sleep 1;
ok 1;
done_testing
