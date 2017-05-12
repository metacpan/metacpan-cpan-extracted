use strict;
use Test::More tests => 15;
use GD::Chord::Piano;

my $im = GD::Chord::Piano->new;

eval { $im->chord(); };
like($@, qr/no chord/, 'no chord');

eval { $im->chord('H'); };
like($@, qr/undefined chord/, 'undefined chord H');

eval { $im->chord('C#b9'); }; # maybe C#-9
like($@, qr/undefined kind of chord/, 'undefined kind of chord C#b9');


is(
    $im->generate('C', (0,4,7))->png,
    $im->chord('C')->png,
    "C"
);
is(
    $im->generate('Cm', (0,3,7))->png,
    $im->chord('Cm')->png,
    "Cm"
);
is(
    $im->generate('C7', (0,4,7,10))->png,
    $im->chord('C7')->png,
    "C7"
);
is(
    $im->generate('C7(9,13)', (0,4,7,10,14,21))->png,
    $im->chord('C7(9,13)')->png,
    "C7(9,13)"
);
is(
    $im->generate('Cadd4', (0,4,5,7))->png,
    $im->chord('Cadd4')->png,
    "Cadd4"
);
is(
    $im->generate('C#add4', (1,5,6,8))->png,
    $im->chord('C#add4')->png,
    "C#add4"
);
is(
    $im->generate('Dadd4', (2,6,7,9))->png,
    $im->chord('Dadd4')->png,
    "Dadd4"
);

is(
    $im->generate('C#', (1,5,8))->png,
    $im->chord('C#')->png,
    "C"
);

is(
    $im->gen('D7', (2,6,9,12))->png,
    $im->chord('D7')->png,
    "D7"
);


is(
    $im->generate('B7(9,13)', (11,15,18,21,13,20))->png,
    $im->chord('B7(9,13)')->png,
    "B7(9,13)"
);


$im->interlaced(0);
is(
    $im->generate('C', (0,4,7))->png,
    $im->chord('C')->png,
    "C"
);


is(66, scalar(@{$im->all_chords}), "all_chord");

