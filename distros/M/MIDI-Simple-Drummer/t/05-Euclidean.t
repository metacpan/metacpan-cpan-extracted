#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('MIDI::Simple::Drummer::Euclidean') }

my $d = eval { MIDI::Simple::Drummer::Euclidean->new };
isa_ok $d, 'MIDI::Simple::Drummer::Euclidean';
ok !$@, 'created with no arguments';

my $x = $d->patterns(0);
is $x, undef, 'get unknown pattern is undef';
my $y = sub { $d->note($d->EIGHTH, $d->strike) };
$x = $d->patterns('y', $y);
is_deeply $x, $y, 'set y pattern';

$x = $d->euclid();
is_deeply $x, [qw(x x x x)], 'euclid';

$d->beats(6);

for ( 0 .. $d->phrases) {
    $d->beat(-name => 1);
}
done_testing();
__END__

$x = $d->euclid();
is_deeply $x, [qw(x . x x x .)], 'euclid';
$d->rotate($x);
is_deeply $x, [qw(x x x . x .)], 'rotate';

# Change-up the beat with a user defined one
$d->{-rhythm} = [qw(x x . . x)];
for ( 0 .. $d->phrases) {
    $d->beat(-name => 1);
}

$x = $d->write('Euclidean-Drummer.mid');
ok $x eq 'Euclidean-Drummer.mid' && -e $x, 'named write';
#unlink $x;
#ok !-e $x, 'removed';

done_testing();
