package MIDI::Drummer::Tiny;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Glorified metronome

our $VERSION = '0.1101';

use Moo;
use MIDI::Simple;


sub BUILD {
   my ( $self, $args ) = @_;

    my ($beats, $divisions) = split /\//, $self->signature;
    $self->beats($beats);
    $self->divisions($divisions);
    $self->score->time_signature(
        $self->beats,
        ( $self->divisions == 8 ? 3 : 2),
        ( $self->divisions == 8 ? 24 : 18 ),
        8
    );

    $self->score->noop( 'c' . $self->channel, 'V' . $self->volume );
    $self->score->set_tempo( int( 60_000_000 / $self->bpm ) );

    $self->score->control_change( $self->channel, 91, $self->reverb ) if $self->reverb;
    $self->score->control_change( $self->channel, 93, $self->chorus ) if $self->chorus;
    $self->score->control_change( $self->channel, 10, $self->pan ) if $self->pan;
}


has channel   => ( is => 'ro', default => sub { 9 } );
has volume    => ( is => 'ro', default => sub { 100 } );
has bpm       => ( is => 'ro', default => sub { 120 } );
has reverb    => ( is => 'ro', default => sub { 0 } );
has chorus    => ( is => 'ro', default => sub { 0 } );
has pan       => ( is => 'ro', default => sub { 0 } );
has file      => ( is => 'ro', default => sub { 'MIDI-Drummer.mid' } );
has bars      => ( is => 'ro', default => sub { 4 } );
has score     => ( is => 'ro', default => sub { MIDI::Simple->new_score } );
has signature => ( is => 'rw', default => sub { '4/4' });
has beats     => ( is => 'rw' );
has divisions => ( is => 'rw' );


# kit
has kick          => ( is => 'ro', default => sub { 'n35' } );
has snare         => ( is => 'ro', default => sub { 'n38' } );
has open_hh       => ( is => 'ro', default => sub { 'n46' } );
has closed_hh     => ( is => 'ro', default => sub { 'n42' } );
has pedal_hh      => ( is => 'ro', default => sub { 'n44' } );
has crash1        => ( is => 'ro', default => sub { 'n49' } );
has crash2        => ( is => 'ro', default => sub { 'n57' } );
has splash        => ( is => 'ro', default => sub { 'n55' } );
has china         => ( is => 'ro', default => sub { 'n52' } );
has ride1         => ( is => 'ro', default => sub { 'n51' } );
has ride2         => ( is => 'ro', default => sub { 'n59' } );
has ride_bell     => ( is => 'ro', default => sub { 'n53' } );
has hi_tom        => ( is => 'ro', default => sub { 'n50' } );
has hi_mid_tom    => ( is => 'ro', default => sub { 'n48' } );
has low_mid_tom   => ( is => 'ro', default => sub { 'n47' } );
has low_tom       => ( is => 'ro', default => sub { 'n45' } );
has hi_floor_tom  => ( is => 'ro', default => sub { 'n43' } );
has low_floor_tom => ( is => 'ro', default => sub { 'n41' } );


has whole             => ( is => 'ro', default => sub { 'wn' } );
has half              => ( is => 'ro', default => sub { 'hn' } );
has quarter           => ( is => 'ro', default => sub { 'qn' } );
has triplet_quarter   => ( is => 'ro', default => sub { 'tqn' } );
has dotted_quarter    => ( is => 'ro', default => sub { 'dqn' } );
has eighth            => ( is => 'ro', default => sub { 'en' } );
has triplet_eighth    => ( is => 'ro', default => sub { 'ten' } );
has dotted_eighth     => ( is => 'ro', default => sub { 'den' } );
has sixteenth         => ( is => 'ro', default => sub { 'sn' } );
has triplet_sixteenth => ( is => 'ro', default => sub { 'tsn' } );
has dotted_sixteenth  => ( is => 'ro', default => sub { 'dsn' } );


sub note { return shift->score->n(@_) }


sub rest { return shift->score->r(@_) }


sub count_in {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $i ( 1 .. $self->beats * $bars ) {
        $self->note( $self->quarter, $self->closed_hh );
    }
}


sub metronome44 { shift->metronome(@_) }

sub metronome {
    my $self = shift;
    my $bars = shift || $self->bars;
    my $flag = shift || 0;

    my $i = 0;

    for my $n ( 1 .. $self->beats * $bars ) {
        if ( $n % 2 == 0 )
        {
            $self->note( $self->quarter, $self->closed_hh, $self->snare );
        }
        else {
            if ( $flag == 0 )
            {
                $self->note( $self->quarter, $self->closed_hh, $self->kick );
            }
            else
            {
                if ( $i % 2 == 0 )
                {
                    $self->note( $self->quarter, $self->closed_hh, $self->kick );
                }
                else
                {
                    $self->note( $self->eighth, $self->closed_hh, $self->kick );
                    $self->note( $self->eighth, $self->kick );
                }
            }

            $i++;
        }
    }
}


sub metronome34 {
    my $self = shift;
    my $bars = shift || $self->bars;

    for ( 1 .. $bars ) {
        $self->note( $self->quarter, $self->ride1, $self->kick );
        $self->note( $self->quarter, $self->ride1 );
        $self->note( $self->quarter, $self->ride1, $self->snare );
    }
}


sub metronome54 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->quarter, $self->closed_hh, $self->kick);
        $self->note($self->quarter, $self->closed_hh);
        $self->note($self->quarter, $self->closed_hh, $self->snare);
        $self->note($self->quarter, $self->closed_hh);
        if ($n % 2) {
            $self->note($self->quarter, $self->closed_hh);
        }
        else {
            $self->note($self->eighth, $self->closed_hh);
            $self->note($self->eighth, $self->kick);
        }
    }
}


sub metronome58 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->eighth, $self->closed_hh, $self->kick);
        $self->note($self->sixteenth, $self->closed_hh);
        $self->note($self->sixteenth, $self->kick);
        $self->note($self->eighth, $self->closed_hh, $self->snare);
        $self->note($self->sixteenth, $self->closed_hh);
        $self->note($self->sixteenth, $self->snare);
        $self->note($self->sixteenth, $self->closed_hh);
        $self->note($self->sixteenth, $self->kick);
    }
}


sub metronome74 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->quarter, $self->closed_hh, $self->kick);
        $self->note($self->quarter, $self->closed_hh);
        $self->note($self->quarter, $self->closed_hh, $self->snare);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->kick);
        $self->note($self->quarter, $self->closed_hh, $self->kick);
        $self->note($self->quarter, $self->closed_hh, $self->snare);
        $self->note($self->quarter, $self->closed_hh);
    }
}


sub metronome78 {
    my $self = shift;
    my $bars = shift || $self->bars;
    for my $n (1 .. $bars) {
        $self->note($self->eighth, $self->closed_hh, $self->kick);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->sixteenth, $self->closed_hh, $self->kick);
        $self->note($self->sixteenth, $self->kick);
        $self->note($self->eighth, $self->closed_hh, $self->snare);
        $self->note($self->eighth, $self->closed_hh);
        $self->note($self->eighth, $self->closed_hh);
    }
}


sub set_time_sig {
    my $self = shift;
    my $signature = shift || $self->signature;
    $self->signature($signature);
    my ($beats, $divisions) = split /\//, $signature;
    $self->beats($beats);
    $self->divisions($divisions);
    $self->score->time_signature(
        $self->beats,
        ( $self->divisions == 8 ? 3 : 2),
        ( $self->divisions == 8 ? 24 : 18 ),
        8
    );
}


sub accent_note {
    my $self = shift;
    my $volume = shift;
    $self->score->Volume($volume->[0]);
    $self->note(@_);
    $self->score->Volume($volume->[1]);
}


sub write {
    my $self = shift;
    $self->score->write_score( $self->file );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny - Glorified metronome

=head1 VERSION

version 0.1101

=head1 SYNOPSIS

 use MIDI::Drummer::Tiny;

 my $d = MIDI::Drummer::Tiny->new(
    file      => 'drums.mid',
    bpm       => 100,
    signature => '5/4',
    bars      => 8,
    kick      => 'n36', # Override default patch
    snare     => 'n40', # "
 );

 $d->count_in(1);  # Closed hi-hat for 1 bar

 $d->metronome54;  # 5/4 time for the number of bars

 $d->set_time_sig('4/4');

 $d->rest($d->whole);

 $d->metronome44;  # 4/4 time for the number of bars

 # Alternate kick and snare
 $d->note( $d->quarter, $d->open_hh, $_ % 2 ? $d->kick : $d->snare )
    for 1 .. $d->beats * $d->bars;

 $d->write;

=head1 DESCRIPTION

This module provides a MIDI drummer with the essentials to add notes to produce
a MIDI score.

=head1 ATTRIBUTES

=head2 file

Default: C<MIDI-Drummer.mid>

=head2 score

Default: C<MIDI::Simple-E<gt>new_score>

=head2 channel

Default: C<9>

=head2 volume

Default: C<100>

=head2 bpm

Default: C<120>

=head2 reverb

Default: C<0>

=head2 chorus

Default: C<0>

=head2 pan

Default: C<0>

=head2 bars

Default: C<4>

=head2 beats

Computed given the B<signature>.

=head2 divisions

Computed given the B<signature>.

=head2 signature

Default: C<4/4>

B<beats> / B<divisions>

=head1 KIT

=over 4

=item kick

=item snare

=item open_hh

=item closed_hh

=item pedal_hh

=item crash1

=item crash2

=item splash

=item china

=item ride1

=item ride2

=item ride_bell

=item hi_tom

=item hi_mid_tom

=item low_mid_tom

=item low_tom

=item hi_floor_tom

=item low_floor_tom

=back

=head1 DURATIONS

=over 4

=item whole, half

=item quarter, triplet_quarter, dotted_quarter

=item eighth, triplet_eighth, dotted_eighth

=item sixteenth, triplet_sixteenth, dotted_sixteenth

=back

=head1 METHODS

=head2 new

  $d = MIDI::Drummer::Tiny->new(%arguments);

Return a new C<MIDI::Drummer::Tiny> object.

=for Pod::Coverage BUILD

=head2 note

 $d->note( $d->quarter, $d->closed_hh, $d->kick );
 $d->note( 'qn', 'n42', 'n35' ); # Same thing

Add a note to the score.

This method takes the same arguments as with L<MIDI::Simple/"Parameters for n/r/noop">.

=head2 rest

 $d->rest( $d->quarter );

Add a rest to the score.

This method takes the same arguments as with L<MIDI::Simple/"Parameters for n/r/noop">.

=head2 count_in

 $d->count_in;
 $d->count_in($bars);

Play the closed hihat for the number of beats times the given bars.
If no bars are given, the default times the number of beats is used.

=head2 metronome, metronome44

  $d->metronome44;
  $d->metronome44($bars);
  $d->metronome44($bars, $flag);
  $d->metronome44(16, 1);
  $d->metronome44(0, 1); # Use the ->bars attribute

Add a steady 4/4 beat to the score.

If a B<flag> is provided the beat is modified to include alternating
eighth-note kicks.

=head2 metronome34

  $d->metronome34;
  $d->metronome34($bars);

Add a steady 3/4 beat to the score.

=head2 metronome54

  $d->metronome54;
  $d->metronome54($bars);

Add a 5/4 beat to the score.

=head2 metronome58

  $d->metronome58;
  $d->metronome58($bars);

Add a 5/8 beat to the score.

=head2 metronome74

  $d->metronome74;
  $d->metronome74($bars);

Add a 7/4 beat to the score.

=head2 metronome78

  $d->metronome78;
  $d->metronome78($bars);

Add a 7/8 beat to the score.

=head2 set_time_sig

  $d->set_time_sig('5/4');

Set the B<signature>, B<beats>, B<divisions>, and the B<score>
C<time_signature> values based on the given string.

=head2 accent_note

  $d->accent_note([$accent, $resume], $d->sixteenth, $d->snare);

Play an accented note.

For instance, this can be a "ghosted note", where the B<accent> is a
smaller number (< 50), or an "accented note" that is greater than the
current (B<resume>) volume.

=head2 write

Output the score to the default F<*.mid> file or one given to the
constuctor.

=head1 SEE ALSO

The F<t/*> and F<eg/*> programs in this distribution

L<Moo>

L<MIDI::Simple>

L<https://en.wikipedia.org/wiki/General_MIDI#Percussion>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
