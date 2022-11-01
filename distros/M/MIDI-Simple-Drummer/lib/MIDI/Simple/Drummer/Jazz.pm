package MIDI::Simple::Drummer::Jazz;
$MIDI::Simple::Drummer::Jazz::VERSION = '0.0811';
our $AUTHORITY = 'cpan:GENE';
use strict;
use warnings;
use parent 'MIDI::Simple::Drummer';

sub new {
    my $self = shift;
    $self->SUPER::new(
        -patch => 33,
        @_
    );
}

sub _default_patterns {
    my $self = shift;
    return {

1 => sub { # Basic swing with no kick or snare.
    my $self = shift;
    for my $beat (1 .. $self->beats) {
        $self->note($self->TRIPLET_8TH, $self->ride1);
        $self->rest($self->TRIPLET_8TH) for 0 .. 1;
        $self->note($self->TRIPLET_8TH, $self->pedal, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->ride1);
    }
},

2 => sub { # Syncopated swing with kick and snare.
    my $self = shift;
    for my $beat (1 .. $self->beats) {
        $self->note($self->TRIPLET_8TH, $self->kick, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->snare);

        $self->note($self->TRIPLET_8TH, $self->snare, $self->pedal, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->kick, $self->ride1);

        $self->note($self->TRIPLET_8TH, $self->snare, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->kick);

        $self->note($self->TRIPLET_8TH, $self->kick, $self->pedal, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->snare, $self->ride1);
    }
},

3 => sub { # Syncopated swing with kick and snare.
    my $self = shift;
    for my $beat (1 .. $self->beats) {
        $self->note($self->TRIPLET_8TH, $self->pedal, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->snare);

        $self->note($self->TRIPLET_8TH, $self->snare, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->pedal, $self->ride1);

        $self->note($self->TRIPLET_8TH, $self->snare, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->pedal);

        $self->note($self->TRIPLET_8TH, $self->kick, $self->pedal, $self->ride1);
        $self->rest($self->TRIPLET_8TH);
        $self->note($self->TRIPLET_8TH, $self->snare, $self->ride1);
    }
},

'1 fill' => sub {
    my $self = shift;
    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->rest($self->TRIPLET_8TH);
    $self->note($self->TRIPLET_8TH, $self->snare);

    $self->note($self->_8TH, $self->snare) for 0 .. 1;
},

'2 fill' => sub {
    my $self = shift;
    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->rest($self->TRIPLET_8TH);
    $self->note($self->TRIPLET_8TH, $self->snare);

    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->rest($self->TRIPLET_8TH);
    $self->note($self->TRIPLET_8TH, $self->snare);

    $self->note($self->_8TH, $self->snare) for 0 .. 1;
},

'3 fill' => sub { # Ala Buddy
    my $self = shift;
    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->note($self->TRIPLET_8TH, $self->kick);
    $self->note($self->TRIPLET_8TH, $self->snare);

    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->note($self->TRIPLET_8TH, $self->kick) for 0 .. 1;


    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->note($self->TRIPLET_8TH, $self->kick) for 0 .. 1;

    $self->note($self->TRIPLET_8TH, $self->snare);
    $self->note($self->TRIPLET_8TH, $self->kick) for 0 .. 1;
},

    };
}

# Custom kit access
sub _default_kit {
    my $self = shift;
    return {
        %{ $self->SUPER::_default_kit() },
        ride1 => ['Ride Cymbal 1'],
        ride2 => ['Ride Cymbal 2'],
        bell  => ['Ride Bell'],
        pedal => ['Pedal Hi-Hat'],
    }
}
sub ride1 { return shift->_set_get('ride1', @_) }
sub ride2 { return shift->_set_get('ride2', @_) }
sub bell  { return shift->_set_get('bell', @_) }
sub pedal { return shift->_set_get('pedal', @_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Simple::Drummer::Jazz

=head1 VERSION

version 0.0811

=head1 DESCRIPTION

This package contains a collection of triplet based patterns, loaded by
L<MIDI::Simple::Drummer>.

The constructor can be provided with a specific patch number (default 33 "Jazz
Kit") or the argument C<-brushes =E<gt> 1> to use the "Brushes kit."

Additionally, the methods below are available.

=head1 METHODS

=head2 ride1, ride2, bell

Strike (or set) the rides, individually.  By default, these are the
kit rides.  Imagine that!

=head2 pedal

"Depress" the pedal hi-hat.

=head1 SEE ALSO

L<MIDI::Simple::Drummer>, the F<eg/*> and F<t/*> test scripts.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
