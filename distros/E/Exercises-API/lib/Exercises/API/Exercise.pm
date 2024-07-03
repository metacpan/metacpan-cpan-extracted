package Exercises::API::Exercise;

use v5.38;
use strict;
use warnings;
use Moose;

has 'name' => (
    isa => 'Str',
    is  => 'rw'
);

has 'type' => (
    isa => 'Str',
    is  => 'rw'
);

has 'muscle' => (
    isa => 'Str',
    is  => 'rw'
);

has 'equipment' => (
    isa => 'Str',
    is  => 'rw'
);

has 'difficulty' => (
    isa => 'Str',
    is  => 'rw'
);

has 'instructions' => (
    isa => 'Str',
    is  => 'rw'
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exercises::API::Exercise

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    [
        {
            "name": "Incline Hammer Curls",
            "type": "strength",
            "muscle": "biceps",
            "equipment": "dumbbell",
            "difficulty": "beginner",
            "instructions": "Seat yourself on an incline bench with a dumbbell in each hand. You should pressed firmly against he back with your feet together. Allow the dumbbells to hang straight down at your side, holding them with a neutral grip. This will be your starting position. Initiate the movement by flexing at the elbow, attempting to keep the upper arm stationary. Continue to the top of the movement and pause, then slowly return to the start position."
        },
        {
            "name": "Wide-grip barbell curl",
            "type": "strength",
            "muscle": "biceps",
            "equipment": "barbell",
            "difficulty": "beginner",
            "instructions": "Stand up with your torso upright while holding a barbell at the wide outer handle. The palm of your hands should be facing forward. The elbows should be close to the torso. This will be your starting position. While holding the upper arms stationary, curl the weights forward while contracting the biceps as you breathe out. Tip: Only the forearms should move. Continue the movement until your biceps are fully contracted and the bar is at shoulder level. Hold the contracted position for a second and squeeze the biceps hard. Slowly begin to bring the bar back to starting position as your breathe in. Repeat for the recommended amount of repetitions.  Variations:  You can also perform this movement using an E-Z bar or E-Z attachment hooked to a low pulley. This variation seems to really provide a good contraction at the top of the movement. You may also use the closer grip for variety purposes."
        },
        ...
    ]

=head1 DESCRIPTION

This class is used to store each exercise into an object.

=head1 Attributes

=head2 name

Name of exercise.

=head2 type

Exercise type.

=head2 muscle

Muscle group targeted by the exercise.

=head2 equipment

Equipment need to complete the exercise.

=head2 difficulty

Difficulty level of the exercise.

=head2 instructions

Instructions to explain how to complete the exercise.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Rayhan Alcena.

This is free software, licensed under:

  The MIT (X11) License

=cut
