use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 3;
use List::AllUtils qw(firstidx);
use constant EPS     => 1e-3;
use Lingua::Orthon;

my $orthon = Lingua::Orthon->new(match_level => 1);
my $val;

my @strings = (qw/condition
conditions
coalition
cognition
conditional
conditioned
conditioner
conduction
contrition
conviction
recondition
rendition
addition
audition
collation
collision
commotion
conception
concoction
conditioners
concretion
pistachio
distraction
hibachi
mustache
Mustached
mustaches
pigtail
pistil
pitch
pitched
pitcher
pitches
pitching
psychic
psycho
abstain
abstraction
antacid
attach
attache
attached/);

my $test_str;
my @sample = ();

for my $test( ['condition', 2.4], ['PISTACHIO', 4.3] ) {
    @sample = @strings;
    my $idx = firstidx { lc $_ eq lc $test->[0] } @sample;
    splice(@sample, $idx, 1 ) if defined $idx;
    $val = $orthon->old(test => $test->[0], sample => \@sample, lim => 20);
    ok(
        about_equal($val, $test->[1]),
        'Levenshtein Distance calculation failed' . "\n\texpected = $test->[1]\n\tobserved = $val"
    );
}

$orthon = Lingua::Orthon->new(match_level => 3);
my $test = 'pistachio';
@sample = map { lc $_ } @strings;
my $idx = firstidx { $_ eq $test } @sample;
splice(@sample, $idx, 1 ) if defined $idx;
$val = $orthon->old(test => $test, sample => \@sample, lim => 20);
ok(
        about_equal($val, 4.3),
        'Levenshtein Distance calculation failed' . "\n\texpected = 4.3\n\tobserved = $val"
    );

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

1;
