#!/usr/bin/env perl
=pod

raylib - sample game: snake

Sample game developed by Ian Eito, Albert Martos and Ramon Santamaria

This game has been created using raylib v1.3 (www.raylib.com)
raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)

Copyright (c) 2015 Ramon Santamaria (@raysan5)

=cut

use strict;
use warnings;

use Graphics::Raylib '+family';
use Graphics::Raylib::XS ':all';
use Graphics::Raylib::Util qw(vector rectangle);
use Cwd 'abs_path';
use Getopt::Std;
use File::Basename 'dirname';

getopts 's', \my %opts;

use constant SNAKE_LENGTH => 256;
use constant SQUARE_SIZE  =>  31;

# Global Variables Declaration
use constant screenWidth  => 800;
use constant screenHeight => 450;

my ($framesCounter, $gameOver, $pause);

my (%fruit, @snake, @snakePosition, $allowMove, %offset, $counterTail);

# Initialization
my $g = Graphics::Raylib->window(screenWidth, screenHeight);

unless ($opts{s}) {
    InitAudioDevice();
    $fruit{sound} = LoadSound("share/coin.wav");
}
InitGame();

$g->fps(60);

# Main game loop
while (!$g->exiting) {    # Detect window close button or ESC key
    # Update and Draw
    UpdateDrawFrame();
}

# De-Initialization
UnloadGame();         # Unload loaded data (textures, sounds, models...)

# Module Functions Definitions (local)

# Initialize game variables
sub InitGame {
    $framesCounter = 0;
    $gameOver = 0;
    $pause = 0;

    $counterTail = 1;
    $allowMove = 0;

    $offset{x} = screenWidth%SQUARE_SIZE;
    $offset{y} = screenHeight%SQUARE_SIZE;

    for (my $i = 0; $i < SNAKE_LENGTH; $i++) {
        $snake[$i]{position} = vector($offset{x}/2, $offset{y}/2);
        $snake[$i]{size}     = vector(SQUARE_SIZE, SQUARE_SIZE);
        $snake[$i]{speed}    = vector(SQUARE_SIZE, 0);

        $snake[$i]{color} = $i == 0 ? DARKBLUE : BLUE;
    }

    for (my $i = 0; $i < SNAKE_LENGTH; $i++) {
        $snakePosition[$i] = vector(0, 0);
    }

    $fruit{size}   = vector(SQUARE_SIZE, SQUARE_SIZE);
    $fruit{color}  = SKYBLUE;
    $fruit{active} = 0;
    PlaySound($fruit{sound}) if defined $fruit{sound};
}

# Update game (one frame)
sub UpdateGame {
    if ($gameOver) {
        if (IsKeyPressed(KEY_ENTER)) {
            InitGame();
            $gameOver = 0;
        }
        return;
    }

    $pause = !$pause if IsKeyPressed(ord('P'));

    if (!$pause) {
        # control
        if (IsKeyPressed(KEY_RIGHT) && ($snake[0]{speed}->x == 0) && $allowMove) {
            $snake[0]{speed} = vector(SQUARE_SIZE, 0);
            $allowMove = 0;
        }
        if (IsKeyPressed(KEY_LEFT) && ($snake[0]{speed}->x == 0) && $allowMove) {
            $snake[0]{speed} = vector(-SQUARE_SIZE, 0);
            $allowMove = 0;
        }
        if (IsKeyPressed(KEY_UP) && ($snake[0]{speed}->y == 0) && $allowMove) {
            $snake[0]{speed} = vector(0, -SQUARE_SIZE);
            $allowMove = 0;
        }
        if (IsKeyPressed(KEY_DOWN) && ($snake[0]{speed}->y == 0) && $allowMove) {
            $snake[0]{speed} = vector(0, SQUARE_SIZE);
            $allowMove = 0;
        }

        # movement
        for (my $i = 0; $i < $counterTail; $i++) {
            $snakePosition[$i] = $snake[$i]{position};
        }

        if (($framesCounter%5) == 0) {
            for (my $i = 0; $i < $counterTail; $i++) {
                if ($i == 0) {
                    $snake[0]{position} += $snake[0]{speed};
                    $allowMove = 1;
                } else {
                    $snake[$i]{position} = $snakePosition[$i-1];
                }
            }
        }

        # wall behaviour
        if ((($snake[0]{position}->x) > (screenWidth  - $offset{x})) ||
            (($snake[0]{position}->y) > (screenHeight - $offset{y})) ||
            ($snake[0]{position}->x < 0) || ($snake[0]{position}->y < 0)) {
            $gameOver = 1;
        }

        # collision with yourself
        for (my $i = 1; $i < $counterTail; $i++) {
            if ($snake[0]{position} == $snake[$i]{position}) {
                $gameOver = 1;
            }
        }

        # TODO: review logic: fruit.position calculation
        if (!$fruit{active}) {
            $fruit{active} = 1;
            $fruit{position} = vector(GetRandomValue(0, (screenWidth/SQUARE_SIZE) - 1)*SQUARE_SIZE + $offset{x}/2, GetRandomValue(0, (screenHeight/SQUARE_SIZE) - 1)*SQUARE_SIZE + $offset{y}/2);

            for (my $i = 0; $i < $counterTail; $i++) {
                while ($fruit{position} == $snake[$i]{position}) {
                    $fruit{position} = vector(GetRandomValue(0, (screenWidth/SQUARE_SIZE) - 1)*SQUARE_SIZE, GetRandomValue(0, (screenHeight/SQUARE_SIZE) - 1)*SQUARE_SIZE);
                    $i = 0;
                }
            }
        }

        # collision
        if (($snake[0]{position}->x < ($fruit{position}->x + $fruit{size}->x)
        &&  ($snake[0]{position}->x + $snake[0]{size}->x) > $fruit{position}->x)
        &&  ($snake[0]{position}->y < ($fruit{position}->y + $fruit{size}->y)
        &&  ($snake[0]{position}->y + $snake[0]{size}->y) > $fruit{position}->y)) {
            $snake[$counterTail]{position} = $snakePosition[$counterTail - 1];
            $counterTail += 1;
            $fruit{active} = 0;
            PlaySound($fruit{sound}) if defined $fruit{sound};
        }

        $framesCounter++;
    }
}

# Draw game (one frame)
sub DrawGame {
    Graphics::Raylib::draw {
        $g->clear;

        if ($gameOver) {
            DrawText("PRESS [ENTER] TO PLAY AGAIN", GetScreenWidth()/2 - MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20)/2, GetScreenHeight()/2 - 50, 20, GRAY);
            return;
        }

        # Draw grid lines
        for (my $i = 0; $i < screenWidth/SQUARE_SIZE + 1; $i++) {
            DrawLineV(vector(SQUARE_SIZE*$i + $offset{x}/2, $offset{y}/2), vector(SQUARE_SIZE*$i + $offset{x}/2, screenHeight - $offset{y}/2), LIGHTGRAY);
        }

        for (my $i = 0; $i < screenHeight/SQUARE_SIZE + 1; $i++) {
            DrawLineV(vector($offset{x}/2, SQUARE_SIZE*$i + $offset{y}/2), vector(screenWidth - $offset{x}/2, SQUARE_SIZE*$i + $offset{y}/2), LIGHTGRAY);
        }

        # Draw snake
        for (my $i = 0; $i < $counterTail; $i++) {
            DrawRectangleV($snake[$i]{position}, $snake[$i]{size}, $snake[$i]{color});
        }

        # Draw fruit to pick
        DrawRectangleV($fruit{position}, $fruit{size}, $fruit{color});

        DrawText("GAME PAUSED", screenWidth/2 - MeasureText("GAME PAUSED", 40)/2, screenHeight/2 - 40, 40, GRAY) if $pause;
    }
}

# Unload game variables
sub UnloadGame {
    # TODO: Unload all dynamic loaded data (textures, sounds, models...)
    if (defined $fruit{sound}) {
        UnloadSound($fruit{sound});
        CloseAudioDevice();
    }
}

# Update and Draw (one frame)
sub UpdateDrawFrame {
    UpdateGame();
    DrawGame();
}
