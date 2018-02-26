package MIDI::Ngram;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Find the top repeated note phrases of a MIDI file

our $VERSION = '0.0901';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Lingua::EN::Ngram;
use List::Util qw( shuffle );
use List::Util::WeightedChoice qw( choose_weighted );
use MIDI::Simple;
use Music::Gestalt;
use Music::Note;
use Music::Tempo;


has in_file => (
    is       => 'ro',
    isa      => \&_invalid_list,
    required => 1,
);


has ngram_size => (
    is      => 'ro',
    isa     => \&_invalid_integer,
    default => sub { 2 },
);


has max_phrases => (
    is      => 'ro',
    isa     => \&_invalid_integer,
    default => sub { 10 },
);


has bpm => (
    is      => 'ro',
    isa     => \&_invalid_integer,
    default => sub { 100 },
);


has durations => (
    is      => 'ro',
    isa     => \&_invalid_list,
    default => sub { [qw( qn tqn )] },
);


has patches => (
    is      => 'ro',
    isa     => \&_invalid_list,
    default => sub { [ 0 .. 127 ] },
);


has out_file => (
    is      => 'ro',
    default => sub { 'midi-ngram.mid' },
);


has pause_duration => (
    is      => 'ro',
    isa     => sub { croak 'Invalid duration' unless $_[0] eq '' || $_[0] =~ /^[a-z]+$/ },
    default => sub { '' },
);


has analyze => (
    is  => 'ro',
    isa => \&_invalid_list,
);


has loop => (
    is      => 'ro',
    isa     => \&_invalid_integer,
    default => sub { 10 },
);


has weight => (
    is      => 'ro',
    isa     => \&_invalid_boolean,
    default => sub { 0 },
);


has random_patch => (
    is      => 'ro',
    isa     => \&_invalid_boolean,
    default => sub { 0 },
);


has shuffle_phrases => (
    is      => 'ro',
    isa     => \&_invalid_boolean,
    default => sub { 0 },
);


has single_phrases => (
    is      => 'ro',
    isa     => \&_invalid_boolean,
    default => sub { 0 },
);


has one_channel => (
    is      => 'ro',
    isa     => \&_invalid_boolean,
    default => sub { 0 },
);


has gestalt => (
    is      => 'ro',
    isa     => \&_invalid_boolean,
    default => sub { 0 },
);


has score => (
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
);


has notes => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);


sub process {
    my ($self) = @_;

    my $analysis;

    my $files = ref $self->in_file eq 'ARRAY' ? $self->in_file : [ $self->in_file ];

    for my $file ( @$files ) {
        # Counter for the tracks seen
        my $i = 0;

        my $opus = MIDI::Opus->new({ from_file => $file });

        $analysis .= "Ngram analysis of $file:\n\tN\tReps\tPhrase\n";

        # Handle each track...
        for my $t ( $opus->tracks ) {
            # Collect the note events for each track
            my @events = grep {
                $_->[0] eq 'note_on'    # Only consider note_on events
                && $_->[2] != 9         # Avoid the drum channel
                && $_->[4] != 0         # Ignore events of velocity 0
            } $t->events;

            # XXX Assume that there is one channel per track
            my $track_channel = $self->one_channel ? 0 : $events[0][2];

            # Skip if there are no events and no channel
            next unless @events && defined $track_channel;

            # Skip if this is not a channel to analyze
            next if $self->analyze && keys @{ $self->analyze }
                && !grep { $_ == $track_channel } @{ $self->analyze };

            $i++;
            $analysis .= "Track $i. Channel: $track_channel\n";

            # Declare the notes to inspect
            my $text = '';

            # Accumulate the notes
            for my $event ( @events ) {
                # Transliterate MIDI note numbers to alpha-code
                ( my $str = $event->[3] ) =~ tr/0-9/a-j/;
                $text .= "$str ";
            }

            # Parse the note text into ngrams
            my $ngram  = Lingua::EN::Ngram->new( text => $text );
            my $phrase = $ngram->ngram( $self->ngram_size );

            # Counter for the ngrams seen
            my $j = 0;

            # Display the ngrams in order of their repetition amount
            for my $p ( sort { $phrase->{$b} <=> $phrase->{$a} || $a cmp $b } keys %$phrase ) {
                # Skip single occurance phrases if requested
                next if !$self->single_phrases && $phrase->{$p} == 1;

                # Don't allow phrases that are not the right size
                my @items = grep { $_ } split /\s+/, $p;
                next unless @items == $self->ngram_size;

                $j++;

                # End if we are past the maximum
                last if $self->max_phrases > 0 && $j > $self->max_phrases;

                # Transliterate our letter code back to MIDI note numbers
                ( my $num = $p ) =~ tr/a-j/0-9/;

                # Convert MIDI numbers to named notes.
                my $text = _convert($num);

                $analysis .= sprintf "\t%d\t%d\t%s %s\n", $j, $phrase->{$p}, $num, $text;

                # Save the number of times the phrase is repeated
                $self->notes->{$track_channel}{$num} += $phrase->{$p};
            }

            $analysis .= $self->_gestalt_analysis( \@events )
                if $self->gestalt;
        }
    }

    return $analysis;
}

sub _gestalt_analysis {
    my ( $self, $events ) = @_;

    my $score_r = MIDI::Score::events_r_to_score_r( $events );
    $score_r = MIDI::Score::sort_score_r($score_r);

    my $g = Music::Gestalt->new( score => $score_r );

    my $note = Music::Note->new( $g->PitchLowest, 'midinum' );
    my $low  = $note->format('midi');
    $note    = Music::Note->new( $g->PitchHighest, 'midinum' );
    my $high = $note->format('midi');
    $note    = Music::Note->new( $g->PitchMiddle, 'midinum' );
    my $mid  = $note->format('midi');

    my $gestalt = "\tRange: $low to $high\n"
        . "\tSpan: $mid +/- " . $g->PitchRange . "\n";

    return $gestalt;
}


sub populate {
    my ($self) = @_;

    $self->score( _setup_midi( bpm => $self->bpm ) );

    my @phrases;
    my $playback;

    if ( $self->weight ) {
        $playback = "Weighted playback:\n\tLoop\tChan\tPhrase\n";

        for my $channel ( sort { $a <=> $b } keys %{ $self->notes } ) {
            # Create a function that adds notes to the score
            my $func = sub {
                my $patch = $self->random_patch ? $self->_random_patch() : 0;

                _set_chan_patch( $self->score, $channel, $patch );

                for my $n ( 1 .. $self->loop ) {
                    my $choice = choose_weighted(
                        [ keys %{ $self->notes->{$channel} } ],
                        [ values %{ $self->notes->{$channel} } ]
                    );

                    # Convert MIDI numbers to named notes.
                    my $text = _convert($choice);

                    $playback .= "\t$n\t$channel\t$choice $text\n";

                    # Add each chosen note to the score
                    for my $note ( split /\s+/, $choice ) {
                        my $duration = $self->durations->[ int rand @{ $self->durations } ];
                        $self->score->n( $duration, $note );
                    }

                    $self->score->r( $self->pause_duration )
                        if $self->pause_duration;
                }
            };

            push @phrases, $func;
        }
    }
    else {
        my $type = $self->shuffle_phrases ? 'Shuffled' : 'Ordered';
        $playback = "$type playback:\n\tN\tChan\tPhrase\n";

        my $n = 0;

        for my $channel ( keys %{ $self->notes } ) {
            my $notes = $self->notes->{$channel};

            # Shuffle the phrases if requested
            my @track_notes = $self->shuffle_phrases
                ? shuffle keys %$notes
                : sort { $notes->{$b} <=> $notes->{$a} || $a cmp $b } keys %$notes;

            # Temporary list of all the phrase notes
            my @all;

            # Add the notes to a bucket
            for my $phrase ( @track_notes ) {
                $n++;

                # Convert MIDI numbers to named notes.
                my $text = _convert($phrase);

                $playback .= "\t$n\t$channel\t$phrase $text\n";

                my @phrase = split /\s/, $phrase;
                push @all, @phrase;
                push @all, 'r'
                    if $self->pause_duration;
            }

            # Create a function that adds our bucket of notes to the score
            my $func = sub {
                my $patch = $self->random_patch ? $self->_random_patch() : 0;

                _set_chan_patch( $self->score, $channel, $patch);

                for my $note ( @all ) {
                    if ( $note eq 'r' ) {
                        $self->score->r( $self->pause_duration );
                    }
                    else {
                        my $duration = $self->durations->[ int rand @{ $self->durations } ];
                        $self->score->n( $duration, $note );
                    }
                }
            };

            push @phrases, $func;
        }
    }

    $self->score->synch(@phrases);

    return $playback;
}


sub write {
    my ($self) = @_;
    $self->score->write_score( $self->out_file );
}

sub _random_patch {
    my ($self) = @_;
    return $self->patches->[ int rand @{ $self->patches } ];
}

# Convert MIDI numbers to named notes.
sub _convert {
    my $string = shift;

    my $text = '( ';

    for my $n ( split /\s+/, $string ) {
        my $note = Music::Note->new( $n, 'midinum' );
        $text .= $note->format('midi') . ' ';
    }

    $text .= ')';

    return $text;
}

sub _setup_midi {
    my %args = (
        volume  => 120,
        bpm     => 100,
        channel => 0,
        patch   => 0,
        octave  => 5,
        @_,
    );

    my $score = MIDI::Simple->new_score();

    $score->set_tempo( bpm_to_ms($args{bpm}) * 1000 );

    $score->Volume($args{volume});
    $score->Channel($args{channel});
    $score->Octave($args{octave});
    $score->patch_change( $args{channel}, $args{patch} );

    return $score;
}

sub _set_chan_patch {
    my ( $score, $channel, $patch ) = @_;

    $channel //= 0;
    $patch   //= 0;

    $score->patch_change( $channel, $patch );
    $score->noop( 'c' . $channel );
}

sub _invalid_integer {
    croak 'Invalid integer'
        unless $_[0] && $_[0] =~ /^\d+$/ && $_[0] > 0;
}

sub _invalid_list {
    croak 'Invalid list'
        unless ref $_[0] eq 'ARRAY';
}

sub _invalid_boolean {
    croak 'Invalid Boolean'
        unless defined $_[0] && ( $_[0] == 1 || $_[0] == 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Ngram - Find the top repeated note phrases of a MIDI file

=head1 VERSION

version 0.0901

=head1 SYNOPSIS

  use MIDI::Ngram;
  my $mng = MIDI::Ngram->new(
    in_file      => [ 'eg/twinkle_twinkle.mid' ],
    ngram_size   => 3,
    patches      => [qw( 68 69 70 71 72 73 )],
    random_patch => 1,
    gestalt      => 1,
  );
  my $analysis = $mng->process;
  my $playback = $mng->populate;
  $mng->write;

=head1 DESCRIPTION

C<MIDI::Ngram> parses a given list of MIDI files and finds the top repeated note phrases.

=head1 ATTRIBUTES

=head2 in_file

Required.  An ArrayRef of MIDI files to process.

=head2 ngram_size

Ngram phrase size.  Default: 2

=head2 max_phrases

The maximum number of phrases to play.  Default: 10

=head2 bpm

Beats per minute.  Default: 100

=head2 durations

The note durations to choose from (at random).  Default: [qn tqn]

=head2 patches

The patches to choose from (at random) if given the B<random_patch> option.
Otherwise 0 (piano) is used.  Default: [0 .. 127]

=head2 out_file

MIDI output file.  Default: midi-ngram.mid

=head2 pause_duration

Insert a rest of the given duration after each phrase.  Default: '' (no resting)

=head2 analyze

ArrayRef of the channels to analyze.  If not given, all channels are analyzed.

=head2 loop

The number of times to choose a weighted phrase.  * Only works with the
B<weight> option.  Default: 4

=head2 weight

Boolean.  Play phrases by their ngram repetition occurrence.  Default: 0

=head2 random_patch

Boolean.  Choose a random patch from B<patches> for each channel.
Default: 0 (piano)

=head2 shuffle_phrases

Boolean.  Shuffle the non-weighted phrases before playing them.  Default: 0

=head2 single_phrases

Boolean.  Allow single occurrence ngrams.  Default: 0

=head2 one_channel

Boolean.  Accumulate phrases into a single list.  Default: 0

=head2 gestalt

Boolean.  Include pitch range in the analysis.

=head2 score

The MIDI score object.  Constructed at runtime.  Constructor argument if given
will be ignored.

=head2 notes

The bucket of ngrams.  Constructed at runtime.  Constructor argument if given
will be ignored.

=head1 METHODS

=head2 new()

  $mng = MIDI::Ngram->new(%arguments);

Create a new C<MIDI::Ngram> object.

=head2 process()

  my $analysis = $mng->process;

Find all ngram phrases and return the note analysis.

=head2 populate()

  my $playback = $mng->populate;

Add notes to the MIDI score and return the playback notes.

=head2 write()

  $mng->write;

Write out the MIDI file.

=head1 TO DO

Preserve note durations instead of random assignment.

=head1 SEE ALSO

L<Moo>

L<Lingua::EN::Ngram>

L<List::Util>

L<List::Util::WeightedChoice>

L<Music::Note>

L<MIDI::Simple>

L<Music::Tempo>

L<Music::Gestalt>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
