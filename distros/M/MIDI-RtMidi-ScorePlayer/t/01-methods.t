#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIDI::Util qw(setup_score);

use_ok 'MIDI::RtMidi::ScorePlayer';

subtest throws => sub {
    throws_ok { MIDI::RtMidi::ScorePlayer->new }
        qr/score object is required/, 'no score given';
    throws_ok { MIDI::RtMidi::ScorePlayer->new(score => 'score') }
        qr/parts is required/, 'no parts given';
};

subtest defaults => sub {
    my $p = new_ok 'MIDI::RtMidi::ScorePlayer' => [
        score => 'score',
        parts => ['parts'],
    ];
    isa_ok $p->{device}, 'MIDI::RtMidi::FFI::Device';
    is $p->{port}, qr/wavetable|loopmidi|timidity|fluid/i, 'port'
};

subtest play => sub {
    my $score = setup_score(lead_in => 0);
    sub foo { return sub {} }
    my $p = new_ok 'MIDI::RtMidi::ScorePlayer' => [
        score    => $score,
        parts    => [ \&foo ],
        sleep    => 0,
        infinite => 0,
    ];
    lives_ok { $p->play } 'expecting to live';
};

subtest deposit => sub {
    my $score = setup_score(lead_in => 0);
    my $foo = sub { return sub { $score->r('qn') } };
    my $p = new_ok 'MIDI::RtMidi::ScorePlayer' => [
        score    => $score,
        parts    => [ $foo ],
        sleep    => 0,
        infinite => 0,
        deposit  => 'foo-',
        verbose  => 0,
    ];
    lives_ok { $p->play } 'expecting to live';
    my @got = glob('foo-*.midi');
    ok -e $got[0], 'deposited';
    unlink $got[0];
    ok !-e $got[0], 'unlinked';
};

done_testing();
