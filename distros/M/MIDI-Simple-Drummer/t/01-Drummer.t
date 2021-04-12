#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok 'MIDI::Simple::Drummer';

my $d = new_ok 'MIDI::Simple::Drummer';

my $f1 = 'Drummer.mid';
my $f2 = 'Buddy-Rich.mid';

# Define test durations.
my @v = (
    [qw(WHOLE         _1ST wn 4)],
    [qw(HALF          _2ND hn 2)],
    [qw(QUARTER       _4TH qn 1)],
    [qw(EIGHTH        _8TH en 0.5)],
    [qw(SIXTEENTH    _16TH sn 0.25)],
    [qw(THIRTYSECOND _32ND xn 0.125)],
    [qw(SIXTYFOURTH  _64TH yn 0.0625)],
);

# Test durations.
for my $v (@v) {
    my($m, $n, $i, $j) = @$v;
    is $d->$m(), $i, $m;
    is $d->$n(), $i, $n;
    is $d->_durations->{$i}, $j, "duration=$j";
}

# Test accessors...
my $x = $d->channel;
is $x, 9, 'get default channel';
$x = $d->channel(2);
is $x, 2, 'set channel';
$d->channel(9); # Ok enough of that.

$x = $d->bpm;
is $x, 120, 'get default bpm';
$x = $d->bpm(111);
is $x, 111, 'set bpm';

$x = $d->volume;
is $x, 100, 'get default volume';
$x = $d->volume(101);
is $x, 101, 'set volume';

$x = $d->phrases;
is $x, 4, 'get default phrases';
$x = $d->phrases(2);
is $x, 2, 'set phrases';

$x = $d->bars;
is $x, 4, 'get default bars';
$x = $d->bars(2);
is $x, 2, 'set bars';

$x = $d->beats;
is $x, 4, 'get default beats';
$x = $d->beats(2);
is $x, 2, 'set beats';

$x = $d->divisions;
is $x, 4, 'get default divisions';
$x = $d->divisions(2);
is $x, 2, 'set divisions';

$x = $d->signature;
is $x, '4/4', 'get default signature';
$x = $d->signature('7/4');
is $x, '7/4', 'set signature';

$x = $d->file;
is $x, $f1, 'get default file';
$x = $d->file($f2);
is $x, $f2, 'set file';

$x = $d->score;
isa_ok $x, 'MIDI::Simple', 'score';

$x = $d->accent;
is $x, 127, 'get default accent';
$x = $d->accent(20);
is $x, 121, 'set accent';

$x = $d->kit;
isa_ok $x, 'HASH';
$x = $d->kit('clank');
is $x, undef, 'kit clank undef';
$x = $d->kit(clunk => ['Foo','Bar']);
is_deeply $x, ['Foo','Bar'], 'kit set clunk';

$x = $d->name_of('kick');
is $x, 'Acoustic Bass Drum', 'kick is Acoustic Bass Drum';

$x = $d->snare;
is $x, 'n38', 'snare';
$x = $d->kick;
is $x, 'n35', 'kick';
$x = $d->tick;
is $x, 'n42', 'tick';
$x = $d->backbeat;
like $x, qr/n3[58]/, 'backbeat';
$x = $d->hhat;
like $x, qr/n4[246]/, 'hhat';
$x = $d->crash;
like $x, qr/n(?:5[257]|49)/, 'crash';
$x = $d->ride;
like $x, qr/n5[139]/, 'ride';
$x = $d->tom;
like $x, qr/n(?:4[13578]|50)/, 'tom';

$x = $d->strike;
is $x, 'n38', 'strike default';
$x = $d->strike('Cowbell');
is $x, 'n56', 'strike patch';
$x = $d->strike('Cowbell', 'Tambourine');
is $x, 'n56,n54', 'strike patches string';
$x = [$d->strike('Cowbell', 'Tambourine')];
is_deeply $x, ['n56', 'n54'], 'strike patches list';

$x = $d->option_strike;
like $x, qr/n(?:5[257]|49)/, 'option_strike default';
$x = $d->option_strike('Cowbell');
is $x, 'n56', 'option_strike patch';
$x = $d->option_strike('Cowbell', 'Tambourine');
like $x, qr/n5[46]/, 'option_strike options';

# Test the metronome.
$d = new_ok 'MIDI::Simple::Drummer';
$d->metronome;
$d = new_ok 'MIDI::Simple::Drummer' => [ -signature => '3/4' ];
$x = $d->beats;
is $x, 3, 'get beats';
$x = $d->divisions;
is $x, 4, 'get divisions';
$d->metronome;
$x = grep { $_->[0] eq 'note' } @{$d->score->{Score}};
ok $x == $d->beats * $d->phrases, 'metronome';

# Test the machinations.
$d = new_ok 'MIDI::Simple::Drummer';
$d->count_in;
$x = grep { $_->[0] eq 'note' } @{$d->score->{Score}};
ok $x == $d->beats, 'count_in';

$x = $d->rotate;
is $x, 'n35', 'rotate';
$x = $d->rotate(1);
is $x, 'n35', 'rotate 1';
$x = $d->rotate(2);
is $x, 'n38', 'rotate 2';
$x = $d->rotate(3);
is $x, 'n35', 'rotate 3';
$x = $d->rotate(1, ['Cowbell', 'Tambourine']);
is $x, 'n54', 'rotate 1 options';
$x = $d->rotate(2, ['Cowbell', 'Tambourine']);
is $x, 'n56', 'rotate 2 options';
$x = $d->rotate(3, ['Cowbell', 'Tambourine']);
is $x, 'n54', 'rotate 3 options';

$x = $d->backbeat_rhythm;
is $x, 'n35,n42', 'backbeat_rhythm';
$x = $d->backbeat_rhythm(-beat => 1);
is $x, 'n35,n42', 'backbeat_rhythm 1';
$x = $d->backbeat_rhythm(-beat => 2);
is $x, 'n38,n42', 'backbeat_rhythm 2';
$x = $d->backbeat_rhythm(-beat => 3);
is $x, 'n35,n42', 'backbeat_rhythm 3';
$x = $d->backbeat_rhythm(-beat => 1, -fill => 0);
is $x, 'n35,n42', 'backbeat_rhythm 1 no fill';
$x = $d->backbeat_rhythm(-beat => 1, -fill => 1);
like $x, qr/n35,n(?:5[257]|49)/, 'backbeat_rhythm 1 fill';
$x = $d->backbeat_rhythm(-beat => 2, -fill => 1);
is $x, 'n38,n42', 'backbeat_rhythm 2 fill';
$x = $d->backbeat_rhythm(-beat => 3, -fill => 1);
is $x, 'n35,n42', 'backbeat_rhythm 3 fill';

$d->patterns;
$x = $d->patterns(0);
is $x, undef, 'get unknown pattern is undef';
my $y = sub { $d->note($d->EIGHTH, $d->strike) };
$x = $d->patterns('y', $y);
is_deeply $x, $y, 'set y pattern';
$x = $d->patterns('y fill', $y);
is_deeply $x, $y, 'set y fill pattern';

$x = $d->beat;
ok $x, 'beat';
$x = $d->fill;
like $x, qr/ fill$/, 'fill';
$x = $d->beat(-name => 'y');
is $x, 'y', 'named y beat';
$x = $d->beat(-type => 'fill');
like $x, qr/ fill$/, 'fill';
$x = $d->beat(-name => 'y', -type => 'fill');
is $x, 'y fill', 'named fill';
$x = $d->beat(-last => 'y');
isnt $x, 'y', 'last known beat';
$x = $d->beat(-last => 'y fill');
isnt $x, 'y fill', 'last known fill';

# Write the score to disk.
$x = $d->write;
ok $x eq $f1 && -e $x, 'write';
$x = $d->write($f2);
ok $x eq $f2 && -e $x, 'named write';

# TODO sync_tracks() tests with score notes instead.
$d = new_ok 'MIDI::Simple::Drummer';
$d->patterns(b1 => \&b1);
$d->patterns(b2 => \&b2);
$d->sync_tracks(
    sub { $d->beat(-name => 'b1') },
);
$d->write($f1);
$d->sync_tracks(
    sub { $d->beat(-name => 'b1') },
    sub { $d->beat(-name => 'b2') },
);
$d->write($f2);
ok -s $f1 < -s $f2, 'multi-track';
sub b1 { # tick
    my $self = shift;
    my %args = @_;
    my $strike = $self->tick;
    $self->note($self->QUARTER(), $strike) for 1 .. $self->beats;
    return $strike;
}
sub b2 { # kick
    my $self = shift;
    my %args = @_;
    my $strike = $self->kick;
    $self->note($self->QUARTER(), $strike) for 1 .. $self->beats;
    return $strike;
}

done_testing();
