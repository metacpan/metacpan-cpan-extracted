use Test::More tests => 6;

use MIDI;
use MIDI::Morph;

can_ok('MIDI::Morph', qw(new Morph));

my $m;

ok(!defined MIDI::Morph->new());

$m = MIDI::Morph->new(from => [], to => []);
isa_ok($m, 'MIDI::Morph');

is_deeply($m->Morph(0), []);
is_deeply($m->Morph(1), []);
is_deeply($m->Morph(0.5), []);
