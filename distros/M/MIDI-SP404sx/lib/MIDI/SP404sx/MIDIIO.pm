package MIDI::SP404sx::MIDIIO;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use MIDI;
use MIDI::SP404sx::Note;
use MIDI::SP404sx::Pattern;
use Log::Log4perl qw(:easy);

my $type     = 0;
my $dtime    = 1;
my $channel  = 2;
my $note     = 3;
my $velocity = 4;

sub read_pattern {
    my $class = shift;
    my $file = shift;
    my $opus = MIDI::Opus->new({ from_file => $file });
    #print Dumper($opus);
    return decode_events($opus);
}

sub decode_events {
    my $opus = shift;
    my $pattern = MIDI::SP404sx::Pattern->new;
    for my $track ( $opus->tracks ) {
        my %seen;
        my $position = 0;
        EVENT: for my $e ( $track->events ) {
            next EVENT unless $e->[$type] =~ /note_/;
            $position += $e->[$dtime];
            my $t  = $position / $opus->ticks;
            my $n  = $e->[$note];
            my $c  = $e->[$channel];
            my $id = "${n},${c}";

            # process note on event
            if ( $e->[$type] eq 'note_on' ) {
                $seen{$id} = MIDI::SP404sx::Note->new(
                    pitch    => $n,
                    channel  => $c,
                    position => $t,
                    pattern  => $pattern,
                    velocity => $e->[$velocity],
                );
            }

            # process note off event
            if ( $e->[$type] eq 'note_off' ) {
                if ( my $note_obj = $seen{$id} ) {
                    $note_obj->nlength( $t - $note_obj->position );
                }
                else {
                    die "Received note off without note on";
                }
            }
        }
    }
    return $pattern;
}

# Time attached to every event in a MIDI file is an offset from the previous event.
# This offset is called delta-time. This is stored in slot $dtime of every event
# we deal with (i.e. note_on, note_off and track_name).

sub write_pattern {
    my $class = shift;
    my ( $pattern, $file ) = @_;
    my $ppqn = $MIDI::SP404sx::Constants::PPQ;
    my $opus = MIDI::Opus->new({ format => 1, ticks => $ppqn });
    my @tracks;

    # iterate over distinct channels sorted ascending
    for my $c ( sort { $a <=> $b } keys %{{ map { $_->channel => 1 } $pattern->notes }} ) {

        # instantiate events array with track label for base or upper channel (=SP404sx bank group)
        my @events = ( [ 'track_name', 0, scalar(@tracks) == 0 ? 'Base channel' : 'Upper channel' ] );

        # iterate over notes in this channel chronologically, make note-on and note-off events
        my @notes;
        for my $n ( sort { $a->position <=> $b->position } grep { $_->channel == $c } $pattern->notes ) {
            my $noff_pos = $n->position + $n->nlength;
            push @notes, [ 'note_on', $n->position, $n->channel, $n->pitch, $n->velocity ];
            push @notes, [ 'note_off', $noff_pos,   $n->channel, $n->pitch, $n->velocity ];
        }
        @notes = sort { $a->[$dtime] <=> $b->[$dtime] } @notes;

        # compute delta times in quarter notes
        for ( my $i = $#notes; $i >= 1; $i-- ) {
            $notes[$i]->[$dtime] -= $notes[$i-1]->[$dtime];
        }

        # compute delta times in pulses and add to events
        for my $n ( @notes ) {
            $n->[$dtime] = sprintf( "%.0f", $n->[$dtime] * $ppqn );
            push @events, $n;
        }

        # create and populate track
        my $track = MIDI::Track->new;
        $track->events(@events);
        push @tracks, $track;
    }
    $opus->tracks( @tracks );
    $opus->write_to_file( $file );
}

1;