use 5.010;
use warnings;
use Test::More;
use diagnostics;

use IO::Prompter;

if (!-t *STDIN || !-t *STDERR) {
    plan('skip_all' => 'Non-interactive test environment');
}
elsif (!eval { require Term::ReadKey }) {
    plan('skip_all' => 'Term::ReadKey not available');
    exit;
}
else {
    plan('no_plan');
}

my %ok = (
    'Pure prompt'       => 0,
    'Assignment prompt' => 0,
    '$_ unaffected'     => 0,
    'Dynamic echo'      => 0,
);

if (prompt -i, "\n\tEnter an integer (should echo stars): ",
                -echo=>'*',
                -out=>\*STDERR
) {
    $ok{'Pure prompt'} = m{ ^ \s* [+-]? \d++ \s* $ }x;
}

$_ = 'UNDERBAR';
if (my $input = prompt "\tEnter an integer (should echo nothing): ", -i, -_e, -out=>\*STDERR) {
    $ok{'Assignment prompt'} = $input =~ m{ ^ \s* [+-]? \d++ \s* $ }x;
    $ok{'$_ unaffected'} = $_ eq 'UNDERBAR';
}

if (prompt "\tEnter your name (SHouLD eCHo iN HoSTaGe CaSe): ",
           -echo => sub{ /[aeiou]/i ? lc : uc },
           -out=>\*STDERR
) {
    $ok{'Dynamic echo'} = 1;
}



for my $test (keys %ok) {
    ok $ok{$test} => $test;
}


