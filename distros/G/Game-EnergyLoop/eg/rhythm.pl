#!/usr/bin/env perl
# rhythm.pl - an example Game::EnergyLoop script. A integer energy
# system is something like a priority queue. There are things to TWEAK.
#   make depend
#   perl ./rhythm.pl
use Game::EnergyLoop;
use List::UtilsBy qw(rev_nsort_by);
use MIDI;
use Object::Pad;

my @events;
my $out_file = shift // 'out.midi';

class Timer {
    field $name :param :reader = "none";
    field $alive :reader = 1;
    field $callback :param :writer;
    field $energy :param            = 96;
    field $cur_energy               = 0;
    field $start :param             = 0;
    field $priority :param :reader  = 0;
    field $ttl :param               = 1;

    field $channel :param = 0;
    field $pitch :param;
    field $velocity :param = 90;

    ADJUST {
        $cur_energy = $start;
    }

    method enlo_energy ( $new = undef ) {
        $cur_energy = $new if defined $new;
        return $cur_energy;
    }

    method enlo_update( $value, $min, $stash ) {
        my $dtime = 0;
        unless ( $stash->{advanced} ) {
            $dtime = $value;
            $stash->{advanced} = 1;
        }
        my $spawn = $callback->( $dtime, $channel, $pitch, $velocity );
        $alive = 0 if --$ttl <= 0;
        $start = 0;
        # when we're next scheduled to run (if still alive)
        return defined $spawn ? ( $energy, $spawn ) : $energy;
    }
}

# Create a note_on event, and schedule a note_off for later.
sub note {
    my ( $dtime, $channel, $pitch, $velocity ) = @_;
    push @events, [ note_on => $dtime, $channel, $pitch, $velocity ];
    return [
        Timer->new(
            callback => sub {
                my ( $d, $c, $p ) = @_;
                push @events, [ note_off => $d, $c, $p, 0 ];
                return;
            },
            start    => 8,        # note duration
            priority => 1,        # note_off need higher priority
            pitch    => $pitch,
        )
    ];
}

my $stash = {
    # If we have advanced, dtime is 0 so that additional events at the
    # same time sound together.
    advanced => 1,
};
# TWEAK - this is the basic "four on the floor, offset hi-hat, and 2/4
# clap" dance rhythm that you may have heard elsewhere.
my $ttl     = 16;
my $dur     = 96;
my @objects = (
    Timer->new(
        name     => "bass",
        energy   => $dur,
        callback => \&note,
        ttl      => $ttl,
        pitch    => 36,
        velocity => 80,
    ),
    Timer->new(
        name     => "hi-hat",
        energy   => $dur,
        callback => \&note,
        ttl      => $ttl,
        start    => $dur / 2,
        velocity => 100,
        pitch    => 42,
    ),
    Timer->new(
        name     => "clap",
        energy   => $dur * 2,
        callback => \&note,
        ttl      => $ttl / 2,
        start    => $dur,
        pitch    => 39,
        velocity => 60,
    ),
);

sub reorder ($objs) {
    # The priority is so that note_off turn off previous note_on before
    # a new note_on for the same pitch.
    @$objs = rev_nsort_by { $_->priority } @$objs;
}

my $cost;
do {
    $cost    = Game::EnergyLoop::update( \@objects, \&reorder, $stash );
    @objects = grep { $_->alive } @objects;
    $stash->{advanced} = 0;
} while ( $cost < ~0 );

sub make_tracks () { [ MIDI::Track->new( { events => \@events } ) ] }

MIDI::Opus->new(
    { format => 0, ticks => 96, tracks => make_tracks() } )
  ->write_to_file($out_file);
