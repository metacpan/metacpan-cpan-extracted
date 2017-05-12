use Test::More tests => 6;

use MIDI::Morph;

my ($from, $to, $from_copy, $to_copy, $halfway);

(my $pos = 0, my $pitch = 30, my $vel = 20);
foreach (0 .. 10) {
    push @$from,      ['note', $pos, 5 * $_, 0, $pitch, $vel];
    push @$from_copy, ['note', $pos, 5 * $_, 0, $pitch, $vel];
    push @$to,      ['note', 2 * $pos, 10 * $_, 0, 2 * $pitch, 3 * $vel];
    push @$to_copy, ['note', 2 * $pos, 10 * $_, 0, 2 * $pitch, 3 * $vel];
    push @$halfway, ['note', 1.5 * $pos, 7.5 * $_, 0, 1.5 * $pitch, 2 * $vel];
    $pos += 100;
    $pitch++;
    $vel++;
}

my $m = MIDI::Morph->new(from => $from, to => $to);
isa_ok($m, 'MIDI::Morph');

is_deeply($m->Morph(0), $from);
is_deeply($m->Morph(0.5), $halfway);
is_deeply($m->Morph(1), $to);

# Make sure our data is still intact
is_deeply($from, $from_copy);
is_deeply($to, $to_copy);
