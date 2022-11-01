package MIDI::Ngram;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Find the top repeated note phrases of MIDI files

our $VERSION = '0.1808';

use Carp qw(croak);
use Lingua::EN::Ngram ();
use List::Util qw( shuffle uniq );
use List::Util::WeightedChoice qw( choose_weighted );
use MIDI::Util qw(setup_score set_chan_patch);
use Music::Note ();

use Moo;
use strictures 2;
use namespace::clean;


has in_file => (
    is       => 'ro',
    isa      => \&_is_list,
    required => 1,
);


has ngram_size => (
    is      => 'ro',
    isa     => \&_is_integer,
    default => sub { 2 },
);


has min_phrases => (
    is      => 'ro',
    isa     => \&_is_integer,
    default => sub { 2 },
);


has max_phrases => (
    is      => 'ro',
    isa     => \&_is_integer0,
    default => sub { 0 },
);


has bpm => (
    is      => 'ro',
    isa     => \&_is_integer,
    default => sub { 100 },
);


has durations => (
    is      => 'ro',
    isa     => \&_is_list,
    default => sub { [] },
);


has patches => (
    is      => 'ro',
    isa     => \&_is_list,
    default => sub { [ 0 .. 127 ] },
);


has random_patch => (
    is      => 'ro',
    isa     => \&_is_boolean,
    default => sub { 0 },
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
    isa => \&_is_list,
);


has loop => (
    is      => 'ro',
    isa     => \&_is_integer,
    default => sub { 10 },
);


has weight => (
    is      => 'ro',
    isa     => \&_is_boolean,
    default => sub { 0 },
);


has shuffle_phrases => (
    is      => 'ro',
    isa     => \&_is_boolean,
    default => sub { 0 },
);


has one_channel => (
    is      => 'ro',
    isa     => \&_is_boolean,
    default => sub { 0 },
);


has score => (
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
);

has _opus_ticks => (
    is => 'rw',
);


has dura_notes => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);


has notes => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

has _event_list => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build__event_list {
    my ($self) = @_;

    my %events;

    for my $file ( @{ $self->in_file } ) {
        my $opus = MIDI::Opus->new({ from_file => $file });

        # XXX Assume that all files have the same MIDI ppqn
        $self->_opus_ticks($opus->ticks)
            unless $self->_opus_ticks;

        for my $t ( $opus->tracks ) {
            my $score_r = MIDI::Score::events_r_to_score_r( $t->events_r );
            #MIDI::Score::dump_score($score_r);

            # Collect the note events
            for my $event (@$score_r) {
                # ['note', <start>, <duration>, <channel>, <note>, <velocity>]
                if ($event->[0] eq 'note') {
                    push @{ $events{ $event->[3] }{ $event->[1] } },
                        { note => $event->[4], dura => $event->[2] };
                }
            }
        }
    }

    return \%events;
}


has dura => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

has _dura_list => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);


has dura_net => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build_dura_net {
    my ($self) = @_;

    my %net;

    for my $channel (sort { $a <=> $b } keys %{ $self->_event_list }) {
        my @group;
        my $last;

        for my $start (sort { $a <=> $b } keys %{ $self->_event_list->{$channel} }) {
            my $duras = join ',', map { $_->{dura} } @{ $self->_event_list->{$channel}{$start} };

            if (@group == $self->ngram_size) {
                my $group = join ' ', @group;
                $net{$channel}{ $last . '-' . $group }++
                    if $last;
                $last = $group;
                @group = ();
            }
            push @group, $self->dura_convert($duras);
        }
    }

    for my $channel (keys %net) {
        for my $node (keys %{ $net{$channel} }) {
            delete $net{$channel}{$node}
                if $net{$channel}{$node} < $self->min_phrases;
        }
    }

    return \%net;
}


has note_net => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build_note_net {
    my ($self) = @_;

    my %net;

    for my $channel (sort { $a <=> $b } keys %{ $self->_event_list }) {
        my @group;
        my $last;

        for my $start (sort { $a <=> $b } keys %{ $self->_event_list->{$channel} }) {
            my $notes = join ',', map { $_->{note} } @{ $self->_event_list->{$channel}{$start} };

            if (@group == $self->ngram_size) {
                my $group = join ' ', @group;
                $net{$channel}{ $last . '-' . $group }++
                    if $last;
                $last = $group;
                @group = ();
            }

            push @group, $self->note_convert($notes);
        }
    }

    for my $channel (keys %net) {
        for my $node (keys %{ $net{$channel} }) {
            delete $net{$channel}{$node}
                if $net{$channel}{$node} < $self->min_phrases;
        }
    }

    return \%net;
}


has dura_note_net => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => 1,
);

sub _build_dura_note_net {
    my ($self) = @_;

    my %net;

    for my $channel (sort { $a <=> $b } keys %{ $self->_event_list }) {
        my @group;
        my $last;

        for my $start (sort { $a <=> $b } keys %{ $self->_event_list->{$channel} }) {
            my $nodes = join ',', map { "|$_->{dura}*$_->{note}|" } @{ $self->_event_list->{$channel}{$start} };

            if (@group == $self->ngram_size) {
                my $group = join ' ', @group;
                $net{$channel}{ $last . '-' . $group }++
                    if $last;
                $last = $group;
                @group = ();
            }
            push @group, $self->dura_note_convert($nodes);
        }
    }

    for my $channel (keys %net) {
        for my $node (keys %{ $net{$channel} }) {
            delete $net{$channel}{$node}
                if $net{$channel}{$node} < $self->min_phrases;
        }
    }

    return \%net;
}


sub process {
    my ($self) = @_;

    for my $channel (sort { $a <=> $b } keys %{ $self->_event_list }) {
        # Skip if this is not a channel to analyze
        next if $self->analyze && keys @{ $self->analyze }
            && !grep { $_ == $channel } @{ $self->analyze };

        my $dura_note_text = '';
        my $dura_text = '';
        my $note_text = '';

        for my $start (sort { $a <=> $b } keys %{ $self->_event_list->{$channel} }) {
            # CSV durations and notes
            my $dura_notes = join ',', map { "|$_->{dura}*$_->{note}|" } @{ $self->_event_list->{$channel}{$start} };
            my $duras = join ',', map { $_->{dura} } @{ $self->_event_list->{$channel}{$start} };
            my $notes = join ',', map { $_->{note} } @{ $self->_event_list->{$channel}{$start} };

            # Transliterate MIDI note numbers to alpha-code
            ( my $str = $duras ) =~ tr/0-9,/a-k/;
            $dura_text .= "$str ";
            ( $str = $notes ) =~ tr/0-9,/a-k/;
            $note_text .= "$str ";
            ( $str = $dura_notes ) =~ tr/0-9,*|/a-m/;
            $dura_note_text .= "$str ";
        }

        # Parse the note text into ngrams
        my $dura_note_ngram = Lingua::EN::Ngram->new( text => $dura_note_text );
        my $dura_note_phrase = $dura_note_ngram->ngram( $self->ngram_size );
        my $dura_ngram = Lingua::EN::Ngram->new( text => $dura_text );
        my $dura_phrase = $dura_ngram->ngram( $self->ngram_size );
        my $note_ngram = Lingua::EN::Ngram->new( text => $note_text );
        my $note_phrase = $note_ngram->ngram( $self->ngram_size );

        # Counter for the ngrams seen
        my $j = 0;

        # Display the ngrams in order of their repetition amount
        for my $p ( sort { $dura_phrase->{$b} <=> $dura_phrase->{$a} || $a cmp $b } keys %$dura_phrase ) {
            # Skip single occurance phrases if requested
            next if $dura_phrase->{$p} < $self->min_phrases;

            $j++;

            # End if a max is set and we are past the maximum
            last if $self->max_phrases > 0 && $j > $self->max_phrases;

            # Transliterate our letter code back to MIDI note numbers
            ( my $num = $p ) =~ tr/a-k/0-9,/;

            # Convert MIDI numbers to named durations.
            my $text = $self->dura_convert($num);

            # Save the number of times the phrase is repeated
            $self->dura->{$channel}{$text} += $dura_phrase->{$p};
        }

        unless (@{ $self->durations }) {
            # Build the durations set
            for my $channel (keys %{ $self->dura }) {
                for my $duras (keys %{ $self->dura->{$channel} }) {
                    # A dura string is a space separated, CSV
                    my @duras = split / /, $duras;
                    push @{ $self->_dura_list->{$channel} }, map { split /,/, $_ } @duras;
                }
                $self->_dura_list->{$channel} = [ uniq @{ $self->_dura_list->{$channel} } ];
            }
        }

        # Reset counter for the ngrams seen
        $j = 0;

        # Display the ngrams in order of their repetition amount
        for my $p ( sort { $note_phrase->{$b} <=> $note_phrase->{$a} || $a cmp $b } keys %$note_phrase ) {
            # Skip single occurance phrases if requested
            next if $note_phrase->{$p} < $self->min_phrases;

            $j++;

            # End if a max is set and we are past the maximum
            last if $self->max_phrases > 0 && $j > $self->max_phrases;

            # Transliterate our letter code back to MIDI note numbers
            ( my $num = $p ) =~ tr/a-k/0-9,/;

            # Convert MIDI numbers to named notes.
            my $text = $self->note_convert($num);

            # Save the number of times the phrase is repeated
            $self->notes->{$channel}{$text} += $note_phrase->{$p};
        }

        # Reset counter for the ngrams seen
        $j = 0;

        # Display the ngrams in order of their repetition amount
        for my $p ( sort { $dura_note_phrase->{$b} <=> $dura_note_phrase->{$a} || $a cmp $b } keys %$dura_note_phrase ) {
            # Skip single occurance phrases if requested
            next if $dura_note_phrase->{$p} < $self->min_phrases;

            $j++;

            # End if a max is set and we are past the maximum
            last if $self->max_phrases > 0 && $j > $self->max_phrases;

            # Transliterate our letter code back to MIDI note numbers
            ( my $num = $p ) =~ tr/a-m/0-9,*|/;

            # Convert MIDI numbers to named notes.
            my $text = $self->dura_note_convert($num);

            # Save the number of times the phrase is repeated
            $self->dura_notes->{$channel}{$text} += $dura_note_phrase->{$p};
        }
    }
}


sub populate {
    my ($self) = @_;

    my $score = setup_score( bpm => $self->bpm );
    $self->score($score);

    my @phrases;
    my $playback;

    if ( $self->weight ) {
        $playback = "Weighted playback:\n\tLoop\tChan\tPhrase\n";

        for my $channel ( sort { $a <=> $b } keys %{ $self->notes } ) {
            my $track_chan = $self->one_channel ? 0 : $channel;

            # Create a function that adds notes to the score
            my $func = sub {
                my $patch = $self->random_patch ? $self->_random_patch() : 0;

                set_chan_patch( $self->score, $track_chan, $patch );

                for my $n ( 1 .. $self->loop ) {
                    my $choice = choose_weighted(
                        [ keys %{ $self->notes->{$channel} } ],
                        [ values %{ $self->notes->{$channel} } ]
                    );

                    $playback .= "\t$n\t$track_chan\t$choice\n";

                    # Add each chosen note to the score
                    for my $note ( split /\s+/, $choice ) {
                        my @note = split /,/, $note;
                        my $duration = @{ $self->durations }
                            ? $self->durations->[ int rand @{ $self->durations } ]
                            : $self->_dura_list->{$channel}[ int rand @{ $self->_dura_list->{$channel} } ];
                        $self->score->n( $duration, @note );
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
            my $track_chan = $self->one_channel ? 0 : $channel;

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

                $playback .= "\t$n\t$track_chan\t$phrase\n";

                my @phrase = split /\s/, $phrase;
                push @all, @phrase;
                push @all, 'r'
                    if $self->pause_duration;
            }

            # Create a function that adds our bucket of notes to the score
            my $func = sub {
                my $patch = $self->random_patch ? $self->_random_patch() : 0;

                set_chan_patch( $self->score, $track_chan, $patch);

                for my $note ( @all ) {
                    if ( $note eq 'r' ) {
                        $self->score->r( $self->pause_duration );
                    }
                    else {
                        my @note = split /,/, $note;
                        my $duration = @{ $self->durations }
                            ? $self->durations->[ int rand @{ $self->durations } ]
                            : $self->_dura_list->{$channel}[ int rand @{ $self->_dura_list->{$channel} } ];
                        $self->score->n( $duration, @note );
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


sub dura_convert {
    my ($self, $string) = @_;

    my @text;

    my $match = 0;

    for my $n ( split /\s+/, $string ) {
        my @csv;

        for my $v (split /,/, $n) {
            my $dura = $v / $self->_opus_ticks;

            for my $d (keys %MIDI::Simple::Length) {
                if (sprintf('%.4f', $MIDI::Simple::Length{$d}) eq sprintf('%.4f', $dura)) {
                    $match++;
                    $dura = $d;
                    last;
                }
            }

            push @csv, $match ? $dura : 'd' . $v;
            $match = 0;
        }

        push @text, join ',', @csv;
    }

    return join ' ', @text;
}


sub note_convert {
    my ($self, $string) = @_;

    my @text;

    for my $n ( split /\s+/, $string ) {
        my @csv;

        for my $v (split /,/, $n) {
            my $note = Music::Note->new( $v, 'midinum' );
            push @csv, $note->format('midi');
        }

        push @text, join ',', @csv;
    }

    return join ' ', @text;
}


sub dura_note_convert {
    my ($self, $string) = @_;

    my @text;

    for my $frag ( split /\|/, $string ) {
        my $processed = $frag;

        if ($frag =~ /^([\w,]+)\*([\w,]+)$/) {
            $processed = $self->dura_convert($1)
                . '*'
                . $self->note_convert($2);
        }

        push @text, $processed;
    }

    return join '', @text;
}

sub _random_patch {
    my ($self) = @_;
    return $self->patches->[ int rand @{ $self->patches } ];
}

sub _is_integer0 {
    croak 'Not greater than or equal to zero'
        unless defined $_[0] && $_[0] =~ /^\d+$/;
}

sub _is_integer {
    croak 'Invalid integer'
        unless defined $_[0] && $_[0] =~ /^\d+$/ && $_[0] > 0;
}

sub _is_list {
    croak 'Invalid list'
        unless ref $_[0] eq 'ARRAY';
}

sub _is_boolean {
    croak 'Invalid Boolean'
        unless defined $_[0] && $_[0] =~ /^\d$/ && ( $_[0] == 1 || $_[0] == 0 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Ngram - Find the top repeated note phrases of MIDI files

=head1 VERSION

version 0.1808

=head1 SYNOPSIS

  use MIDI::Ngram;

  # Analyze a tune and build a new MIDI file of repetitions
  my $mng = MIDI::Ngram->new(
    in_file      => [ 'eg/twinkle_twinkle.mid' ],
    ngram_size   => 3,
    min_phrases  => 3,
    max_phrases  => 0, # Analyze all events
    patches      => [qw( 68 69 70 71 72 73 )],
    random_patch => 1,
  );

  $mng->process;

  # Analyze
  print Dumper $mng->dura_notes;
  print Dumper $mng->duras;
  print Dumper $mng->notes;

  print Dumper $mng->dura_note_net;
  print Dumper $mng->dura_net;
  print Dumper $mng->note_net;

  my $playback = $mng->populate;
  print $playback;

  $mng->write;

  # Convert a MIDI number string to a duration or note name.
  my $named = $mng->dura_convert('96'); # qn
  $named = $mng->note_convert('60 61,62'); # C4 Cs4,D4

=head1 DESCRIPTION

C<MIDI::Ngram> parses a given list of MIDI files, finds the top
repeated note phrases, builds the transition networks, and renders to
a MIDI file if desired.

Note: This module currently assumes that all given B<in_file>s have
the same MIDI ppqn (given by the first C<$opus-E<gt>ticks> seen).

=head1 ATTRIBUTES

=head2 in_file

Required.  An Array reference of MIDI files to process.

=head2 ngram_size

Ngram phrase size.

Default: C<2>

=head2 min_phrases

Integer.  Allow a minimum of this number of ngram occurrences in both
the repetition and network lists.

Default: C<2>

=head2 max_phrases

The maximum number of phrases to analyze/play.

Default: C<0>

Setting this to a value of C<0> analyzes all phrases.

=head2 bpm

Beats per minute.

Default: C<100>

=head2 durations

The optional MIDI note durations to choose from (at random).

Default: C<[]> (i.e. use the computed B<dura> phrases instead)

Using a setting of C<['qn']> allows you to evenly inspect the phrases
during audio playback.

=head2 patches

The patches to choose from (at random) if given the B<random_patch>
option.

Default: C<[0 .. 127]>

=head2 random_patch

Boolean.  Choose a random patch from B<patches> for each channel.

Default: C<0> (meaning "use the piano patch")

=head2 out_file

MIDI output file.

Default: C<midi-ngram.mid>

=head2 pause_duration

Insert a rest of the given duration after each phrase.

Default: C<''> (no resting)

=head2 analyze

Array reference of the channels to analyze.  If not given, all
channels are analyzed.

Default: C<undef>

=head2 loop

The number of times to choose a weighted phrase.  * This only works
in conjunction with the B<weight> option.

Default: C<10>

=head2 weight

Boolean.  Play phrases according to the probability of their
repetition occurrence with the function
L<List::Util::WeightedChoice/choose_weighted>.

Default: C<0>

=head2 shuffle_phrases

Boolean.  Shuffle the non-weighted phrases before playing them.

Default: C<0>

=head2 one_channel

Boolean.  Accumulate phrases onto a single playback channel.

Default: C<0>

=head2 score

The score object in L<MIDI::Simple/"MAIN-ROUTINES">.  Constructed by
the B<populate> method.

=head2 dura_notes

The hash-reference bucket of C<duration*note> ngrams.  Constructed by
the B<process> method.

The combination of duration with a note is indicated with the C<*>
character.  For example: C<ten*Cs4>

=head2 notes

The hash-reference bucket of pitch ngrams.  Constructed by the
B<process> method.

Notes are represented in MIDI format with octave number like, C<Cs4>.
A cluster of repeated notes is separated by spaces.  Simultaneous
notes are separated with a comma (C<,>).  For example: C<A4,Cs5>.

=head2 dura

The hash-reference bucket of duration ngrams.  Constructed by the
B<process> method.

Durations are represented in MIDI::Simple style format.  For example,
C<hn> for a known length and C<d123> for a tick duration.
A cluster of repeated durations is separated by spaces.  Simultaneous
durations are separated with a comma (C<,>).  For example: C<hn,d85>.

=head2 dura_net

A hash-reference ngram transition network of the durations.

A dash or hyphen (C<->) divides nodes.  For example:
C<qn,hn qn-qn,hn qn> where the nodes are both C<qn,hn qn> and
C<qn,hn qn>.

=head2 note_net

A hash-reference ngram transition network of the notes.

A dash or hyphen (C<->) divides nodes.  For example:
C<A4 G4,E3-F4,D3 F4> where the nodes are C<A4 G4,E3> and
C<F4,D3 F4>.

=head2 dura_note_net

A hash-reference ngram transition network of the durations and notes
considered as a unit.

A dash or hyphen (C<->) divides nodes.  For example:
C<qn*C3 qn*G4,hn*E3-qn*G4 qn*F4,hn*F3> where the nodes are
C<qn*C3 qn*G4,hn*E3> and C<qn*G4 qn*F4,hn*F3>.

=head1 METHODS

=head2 new

  $mng = MIDI::Ngram->new(%arguments);

Create a new C<MIDI::Ngram> object.

=head2 process

  $mng->process;

Find all ngram phrases of durations, notes and both combined.

This method creates the B<dura_notes>, B<dura>, and B<notes>
repetition lists.

=head2 populate

  $playback = $mng->populate;

Add notes to the MIDI score and return the playback notes.

=head2 write

  $mng->write;

Write out the MIDI file.

=head2 dura_convert

  $durations = $mng->dura_convert($string);

Convert MIDI numbers to named durations.

=head2 note_convert

  $notes = $mng->note_convert($string);

Convert MIDI numbers to named notes.

=head2 dura_note_convert

  $dura_notes = $mng->dura_note_convert($string);

Convert MIDI numbers to named C<duration*note> strings.

=head1 SEE ALSO

L<Moo>

L<Lingua::EN::Ngram>

L<List::Util>

L<List::Util::WeightedChoice>

L<Music::Note>

L<MIDI::Util>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
