use Test::More tests => 4;

use MIDI::Morph;

my $m = MIDI::Morph->new(
    from => [['note', 0, 92, 0, 60, 100]],
    to   => [['note', 0, 92, 0, 60, 100]]);
isa_ok($m, 'MIDI::Morph');

foreach (qw(0 0.5 1)) {
    is_deeply($m->Morph($_), [['note', 0, 92, 0, 60, 100]]);
}
