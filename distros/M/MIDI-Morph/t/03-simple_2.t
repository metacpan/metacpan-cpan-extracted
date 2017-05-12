use Test::More tests => 4;

use MIDI::Morph;

my $m = MIDI::Morph->new(
    from => [['note', 0,  50,  0, 60, 0]],
    to   => [['note', 50, 100, 0, 72, 100]]);
isa_ok($m, 'MIDI::Morph');

foreach (qw(0 0.5 1)) {
    is_deeply($m->Morph($_),
        [['note', $_ * 50, 50 + ($_ * 50), 0, 60 + ($_ * 12), $_ * 100]]);
}
