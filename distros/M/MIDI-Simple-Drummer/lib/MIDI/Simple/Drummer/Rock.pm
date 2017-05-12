package MIDI::Simple::Drummer::Rock;
our $AUTHORITY = 'cpan:GENE';
use strict;
use warnings;
use parent 'MIDI::Simple::Drummer';
our $VERSION = '0.03';

use constant CLOSED => 'Closed Hi-Hat';
use constant CRASH  => 'Crash Cymbal 1';
use constant BELL   => 'Ride Bell';
use constant RIDE2  => 'Ride Cymbal 2';
use constant TOM1   => 'High Tom';
use constant TOM2   => 'Low-Mid Tom';
use constant TOM3   => 'Low Tom';
use constant TOM4   => 'High Floor Tom';
use constant TOM5   => 'Low Floor Tom';

sub new {
    my $self = shift;
    $self->SUPER::new(
        -patch => 1, # Standard
        -power => 0,
        -room  => 0,
        @_
    );
}

# "Quater-note beat" Qn tick. Cym on 1. Kick 1&3. Snare 2&4.
sub _quarter {
    my $self = shift;
    my %args = @_;
    for my $beat (1 .. $self->beats) {
        $self->note($self->QUARTER,
            $self->rotate($beat, $args{-rotate}),
            $self->strike($args{-key_patch})
        );
    }
}

# Common eighth-note based grooves with kick syncopation.
sub _eighth {
    my $self = shift;
    my %args = @_;
    for my $beat (1 .. $self->beats) {
        # Lay-down a back-beat rhythm.
        $self->note($self->EIGHTH,
            $self->backbeat_rhythm(%args, -beat => $beat)
        );
        # Add another kick or tick if we're at the right beat.
        $self->note($self->EIGHTH,
            ((grep { $beat == $_ } @{$args{-key_beat}})
                ? ($self->kick, $self->tick) : $self->tick)
        ) if $args{-key_beat} && @{$args{-key_beat}};
    }
}

sub _kick_fill {
    my $self = shift;
    my %args = @_;
    $self->note(
        $args{-note},
        $self->kick,
        $args{-fill}
            ? $self->strike($args{-patches} ? @{$args{-patches}} : CRASH)
            : $self->tick
    );
}

sub _half_one {
    my $self = shift;
    my %args = @_;
    $self->_kick_fill(-note => $self->EIGHTH, %args);
    $self->note($self->EIGHTH, $self->tick);
    $self->note($self->EIGHTH, $self->snare, $self->tick);
    $self->note($self->EIGHTH, $self->tick);
}

sub _half_two {
    my $self = shift;
    my %args = @_;
    $self->note($self->EIGHTH, $self->kick, $self->tick);
    $self->note($self->EIGHTH, $self->kick, $self->tick);
    $self->note($self->EIGHTH, $self->snare, $self->tick);
    $self->note($self->EIGHTH, $self->tick);
}

sub _half_three {
    my $self = shift;
    my %args = @_;
    $self->note($self->EIGHTH, $self->tick);
    $self->note($self->EIGHTH, $self->kick, $self->tick);
    $self->note($self->EIGHTH, $self->snare, $self->tick);
    $self->note($self->EIGHTH, $self->kick, $self->tick);
}

sub _half_four {
    my $self = shift;
    my %args = @_;
    $self->note($self->EIGHTH, $self->kick, $self->tick) for 0 .. 1;
    $self->note($self->EIGHTH, $self->snare, $self->tick);
    $self->note($self->EIGHTH, $self->kick, $self->tick);
}

sub _half_four_two {
    my $self = shift;
    my %args = @_;
    $self->note($self->EIGHTH, $self->tick);
    $self->note($self->EIGHTH, $self->kick, $self->tick);
    $self->note($self->EIGHTH, $self->snare, $self->tick);
    $self->note($self->EIGHTH, $self->tick);
}

sub _half_five {
    my $self = shift;
    my %args = @_;
    $self->note($self->EIGHTH, $self->kick, $self->tick);
    $self->note($self->EIGHTH, $self->tick);
    $self->note($self->EIGHTH, $self->snare, $self->tick);
    $self->note($self->EIGHTH, $self->kick, $self->tick);
}

sub _default_patterns {
    my $self = shift;
    return {

1.1 => sub {
    my $self = shift;
    my %args = (-key_patch => CLOSED, @_);
    $self->_quarter(%args);
},
1.2 => sub {
    my $self = shift;
    my %args = (-key_patch => BELL, @_);
    $self->_quarter(%args);
},
1.3 => sub {
    my $self = shift;
    my %args = (-key_patch => RIDE2, @_);
    $self->_quarter(%args);
},

# Exercises from the see also link.
2.1 => sub { # Ex. 1
    my $self = shift;
    my %args = @_;
    $self->_half_one(%args);
    $self->_half_one;
},
2.2 => sub { # Ex. 2
    my $self = shift;
    my %args = @_;
    $self->_half_one(%args);
    $self->_half_two;
},
2.3 => sub { # Ex. 3
    my $self = shift;
    my %args = @_;
    $self->_half_one(%args);
    $self->_half_three;
},
2.4 => sub { # Ex. 4
    my $self = shift;
    my %args = @_;
    $self->_half_four(%args);
    $self->_half_four_two;
},
2.5 => sub { # Ex. 5
    my $self = shift;
    my %args = @_;
    $self->_half_five(%args);
    $self->_half_four;
},
2.6 => sub { # Ex. 6
    my $self = shift;
    my %args = @_;
    $self->_half_five(%args);
    $self->_half_one;
    $self->_half_one;
    $self->_half_four;
    $self->_half_five;
    $self->_half_one;
},
2.7 => sub { # Ex. 7
    my $self = shift;
    my %args = @_;
    $self->_half_four(%args);
    $self->_half_five;
    $self->_half_five;
    $self->_half_four_two;
    $self->_half_four;
    $self->_half_five;
},
2.8 => sub { # Ex. 8
    my $self = shift;
    my %args = @_;
    $self->_half_one(%args);
    $self->_half_four_two;
    $self->_half_four;
    $self->_half_three;
    $self->_half_one;
    $self->_half_four_two;
},

3.1 => sub { # "Syncopated beat 1" en c-hh. qn k1,3,4&. qn s2,4.
    my $self = shift;
    my %args = (-key_beat => [4], @_);
    $self->_eighth(%args);
},
3.2 => sub { # "Syncopated beat 2" en c-hh. qn k1,3,3&,4&. qn s2,4.
    my $self = shift;
    my %args = (-key_beat => [3, 4], @_);
    $self->_eighth(%args);
},

'1 fill' => sub {
    my $self = shift;
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 3;
    $self->note($self->SIXTEENTH, $self->strike(TOM1)) for 0 .. 3;
    $self->note($self->SIXTEENTH, $self->strike(TOM3)) for 0 .. 3;
    $self->note($self->SIXTEENTH, $self->strike(TOM5)) for 0 .. 3;
},
'2 fill' => sub {
    my $self = shift;
    $self->note($self->SIXTEENTH, $self->snare, $self->strike(TOM5)) for 0 .. 3;
},
'3 fill' => sub {
    my $self = shift;
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 1;
    $self->note($self->EIGHTH, $self->snare);
    $self->note($self->SIXTEENTH, $self->strike(TOM1)) for 0 .. 1;
    $self->note($self->EIGHTH, $self->strike(TOM1));
},
'4 fill' => sub {
    my $self = shift;
    $self->note($self->SIXTEENTH, $self->snare, $self->strike(TOM5)) for 0 .. 1;
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 1;
    $self->note($self->SIXTEENTH, $self->strike(TOM1)) for 0 .. 1;
},
'5 fill' => sub {
    my $self = shift;
    $self->note($self->EIGHTH, $self->kick, $self->strike(CRASH));
    $self->note($self->EIGHTH, $self->snare) for 0 .. 2;
    $self->note($self->SIXTEENTH, $self->strike(TOM1)) for 0 .. 3;
    $self->note($self->SIXTEENTH, $self->strike(TOM3)) for 0 .. 3;
},
'6 fill' => sub {
    my $self = shift;
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 3;
    $self->note($self->EIGHTH, $self->strike(TOM1));
    $self->note($self->SIXTEENTH, $self->strike(TOM1)) for 0 .. 1;
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 1;
    $self->note($self->EIGHTH, $self->strike(TOM1));
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 1;
    $self->note($self->EIGHTH, $self->strike(TOM3));
},
'7 fill' => sub {
    my $self = shift;
    $self->note($self->SIXTEENTH, $self->snare);
    $self->note($self->EIGHTH, $self->snare);
    $self->note($self->SIXTEENTH, $self->strike(TOM1));
    $self->note($self->EIGHTH, $self->strike(TOM1));
    $self->note($self->SIXTEENTH, $self->strike(TOM3)) for 0 .. 1;
    $self->note($self->SIXTEENTH, $self->snare) for 0 .. 3;
    $self->note($self->SIXTEENTH, $self->strike(TOM3)) for 0 .. 1;
    $self->note($self->EIGHTH, $self->strike(TOM3));
},
'8 fill' => sub {
    my $self = shift;
    $self->note($self->EIGHTH, $self->snare);
    $self->note($self->EIGHTH, $self->kick) for 0 .. 1;
    $self->note($self->EIGHTH, $self->snare);
    $self->note($self->EIGHTH, $self->kick) for 0 .. 1;
    $self->note($self->EIGHTH, $self->snare);
    $self->note($self->EIGHTH, $self->kick);
},

    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Simple::Drummer::Rock

=head1 VERSION

version 0.0803

=head1 DESCRIPTION

This package contains a collection of common rock patterns, loaded by
L<MIDI::Simple::Drummer>.

The constructor can be provided with a specific patch number (default 1
"Standard Kit") or the arguments C<-power =E<gt> 1> or C<-room =E<gt> 1> to use
the alternate rock kits.

=head1 NAME

MIDI::Simple::Drummer::Rock - Rock drum grooves

=head1 TO DO

Some cooler fills, Man.

=head1 SEE ALSO

L<MIDI::Simple::Drummer>, the F<eg/*> and F<t/*> scripts.

Progressive Drum Grooves
L<http://www.amazon.com/Progressive-Drum-Grooves-Series/dp/1875726314/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
