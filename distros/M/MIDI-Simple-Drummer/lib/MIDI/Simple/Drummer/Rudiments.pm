package MIDI::Simple::Drummer::Rudiments;
our $AUTHORITY = 'cpan:GENE';

our $VERSION = '0.04';

use strict;
use warnings;

use parent 'MIDI::Simple::Drummer';

use constant PAN_LEFT   => 0;
use constant PAN_CENTER => 64;
use constant PAN_RIGHT  => 1;


sub new {
    my $self = shift;
    $self->SUPER::new(
        -pan_width => 32, # [ 0 .. 64 ] # From center
        -chorus    => 0,
        -reverb    => 1,
        @_,
    );
}

sub _default_patterns {
    my $self = shift;
    return {
        1  => \&single_stroke_roll,
        2  => \&single_stroke_four,
        3  => \&single_stroke_seven,
        4  => \&multiple_bounce_roll,
        5  => \&triple_stroke_roll,
        6  => \&double_stroke_open_roll,
        7  => \&five_stroke_roll,
        8  => \&six_stroke_roll,
        9  => \&seven_stroke_roll,
        10 => \&nine_stroke_roll,
        11 => \&ten_stroke_roll,
        12 => \&eleven_stroke_roll,
        13 => \&thirteen_stroke_roll,
        14 => \&fifteen_stroke_roll,
        15 => \&seventeen_stroke_roll,
        16 => \&single_paradiddle,
        17 => \&double_paradiddle,
        18 => \&triple_paradiddle,
        19 => \&paradiddle_diddle,
        20 => \&flam,
        21 => \&flam_accent,
        22 => \&flam_tap,
        23 => \&flamacue,
        24 => \&flam_paradiddle,
        25 => \&flammed_mill,
        26 => \&flam_paradiddle_diddle,
        27 => \&pataflafla,
        28 => \&swiss_army_triplet,
        29 => \&inverted_flam_tap,
        30 => \&flam_drag,
        31 => \&drag,
        32 => \&single_drag_tap,
        33 => \&double_drag_tap,
        34 => \&lesson_25_two_and_three,
        35 => \&single_dragadiddle,
        36 => \&drag_paradiddle_1,
        37 => \&drag_paradiddle_2,
        38 => \&single_ratamacue,
        39 => \&double_ratamacue,
        40 => \&triple_ratamacue,
    };
};


sub single_stroke_roll { # 1
    my $self = shift;
    my %args = (
        critical => [PAN_RIGHT .. 8],
        @_
    );
    $self->alternate_note(%args);
}


sub single_stroke_four { # 2
    my $self = shift;
    my %args = (
        critical => [4, 8],
        alternate_pan => 2,
        accent => $self->EIGHTH,
        note => $self->TRIPLET_SIXTEENTH,
    );
    $self->single_stroke_n(%args);
}


sub single_stroke_seven { # 3
    my $self = shift;
    my %args = (
        critical => [7],
        @_
    );
    $self->single_stroke_n(%args);
}


sub multiple_bounce_roll { # 4 TODO
    my $self = shift;
    # TODO Set $multiple and then do a figure below.
}


sub triple_stroke_roll { # 5
    my $self = shift;
    my %args = (
        critical => [1 .. 12],
        groups_of => 3,
        note => $self->TRIPLET_SIXTEENTH,
        @_
    );
    $self->alternate_note(%args);
}


sub double_stroke_open_roll { # 6
    my $self = shift;
    my %args = (
        critical => [1 .. 8],
        groups_of => 2,
        @_
    );
    $self->alternate_note(%args);
}


sub five_stroke_roll { # 7
    my $self = shift;
    my %args = (
        critical => [0 .. 3],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 4];
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});
}


sub six_stroke_roll { #8
    my $self = shift;
    my %args = (
        critical => [0 .. 3],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->pan_left;
    $self->accent_note($args{accent});
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 4];
    $self->accent_note($args{accent});
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub seven_stroke_roll { # 9
    my $self = shift;
    my %args = (
        critical => [0 .. 5],
        groups_of => 2,
        accent => $self->EIGHTH,
        note => $self->TRIPLET_SIXTEENTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 6];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub nine_stroke_roll { # 10
    my $self = shift;
    my %args = (
        critical => [0 .. 7],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 8];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub ten_stroke_roll { # 11
    my $self = shift;
    my %args = (
        critical => [0 .. 7],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});
    $self->pan_left;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 8];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
    $self->pan_right;
    $self->accent_note($args{accent});
}


sub eleven_stroke_roll { # 12
    my $self = shift;
    my %args = (
        critical => [0 .. 9],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 10];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub thirteen_stroke_roll { # 13
    my $self = shift;
    my %args = (
        critical => [0 .. 11],
        groups_of => 2,
        accent => $self->EIGHTH,
        note => $self->TRIPLET_SIXTEENTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 12];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub fifteen_stroke_roll { # 14
    my $self = shift;
    my %args = (
        critical => [0 .. 13],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 14];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub seventeen_stroke_roll { # 15
    my $self = shift;
    my %args = (
        critical => [0 .. 15],
        groups_of => 2,
        accent => $self->EIGHTH,
        @_
    );
    $self->alternate_note(%args);
    $self->pan_right;
    $self->accent_note($args{accent});

    $args{critical} = [1 .. 16];
    $self->alternate_note(%args);
    $self->pan_left;
    $self->accent_note($args{accent});
}


sub single_paradiddle { # 16
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        @_
    );
    $self->alternate_note(%args);
    $self->alternate_note(%args, groups_of => 2);

    $args{critical} = [1 .. 2];
    $self->alternate_note(%args);
    $self->alternate_note(%args, groups_of => 2);
}


sub double_paradiddle { # 17
    my $self = shift;
    my %args = (
        critical => [0 .. 3],
        @_
    );
    $self->alternate_note(%args);
    $args{critical} = [0 .. 1];
    $self->alternate_note(%args, groups_of => 2);

    $args{critical} = [1 .. 4];
    $self->alternate_note(%args);
    $args{critical} = [1 .. 2];
    $self->alternate_note(%args, groups_of => 2);
}


sub triple_paradiddle { # 18
    my $self = shift;
    my %args = (
        critical => [0 .. 5],
        @_
    );
    $self->alternate_note(%args);
    $args{critical} = [0 .. 1];
    $self->alternate_note(%args, groups_of => 2);

    $args{critical} = [1 .. 6];
    $self->alternate_note(%args);
    $args{critical} = [1 .. 2];
    $self->alternate_note(%args, groups_of => 2);
}


sub paradiddle_diddle { # 19
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        @_
    );
    $self->alternate_note(%args);
    $self->alternate_note(%args, groups_of => 2);

    $args{critical} = [1 .. 2];
    $self->alternate_note(%args);
    $self->alternate_note(%args, groups_of => 2);
}


sub flam { # 20
    my $self = shift;
    my %args = (
        note => $self->EIGHTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 1);
    $self->_flambit(PAN_LEFT, $args{note}, 1);
}


sub flam_accent { # 21
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        note => $self->EIGHTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 1);
    $self->alternate_note(%args);

    $self->_flambit(PAN_LEFT, $args{note}, 1);
    $args{critical} = [1 .. 2];
    $self->alternate_note(%args);
}


sub flam_tap { # 22
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 1);
    $self->note($args{note}, $self->strike);

    $self->_flambit(PAN_LEFT, $args{note}, 1);
    $self->note($args{note}, $self->strike);
}


sub flamacue { # 23
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->accent_note($args{note});
    $self->alternate_note(critical => [0 .. 1], note => $self->EIGHTH);
    $self->_flambit(PAN_RIGHT, $args{note}, 0);

    $self->_flambit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->accent_note($args{note});
    $self->alternate_note(critical => [1 .. 2], note => $self->EIGHTH);
    $self->_flambit(PAN_LEFT, $args{note}, 0);
}


sub flam_paradiddle { # 24
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 1);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);

    $self->_flambit(PAN_LEFT, $args{note}, 1);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);
}


sub flammed_mill { # 25
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 1);
    $self->alternate_note(%args, critical => [1 .. 3]);

    $self->_flambit(PAN_LEFT, $args{note}, 1);
    $self->alternate_note(%args, critical => [0 .. 2]);

}


sub flam_paradiddle_diddle { # 26
    my $self = shift;
    my %args = (
        critical => [0 .. 3],
        note => $self->SIXTEENTH,
        @_
    );
    $self->_flambit(PAN_RIGHT, $args{note}, 1);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->alternate_note(%args, groups_of => 2);

    $self->_flambit(PAN_LEFT, $args{note}, 1);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $args{critical} = [1 .. 4];
    $self->alternate_note(%args, groups_of => 2);
}


sub pataflafla { # 27
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        note => $self->SIXTEENTH,
        @_
    );
    for (@{$args{critical}}) {
        # Flam tap tap Flam!
        $self->_flambit(PAN_RIGHT, $args{note}, 1);
        $self->alternate_note(%args);
        $self->_flambit(PAN_RIGHT, $args{note}, 1);
    }
}


sub swiss_army_triplet { # 28
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        note => $self->SIXTEENTH,
        @_
    );
    for (@{$args{critical}}) {
        # Flam!
        $self->_flambit(PAN_RIGHT, $args{note}, 1);
        $self->note($args{note}, $self->strike);
        $self->pan_left;
        $self->note($args{note}, $self->strike);
    }
}


sub inverted_flam_tap { # 29
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        note => $self->TRIPLET_SIXTEENTH,
        @_
    );
    for (@{$args{critical}}) {
        $self->_flambit(PAN_RIGHT, $args{note}, 1);
        $self->pan_left;
        $self->note($args{note}, $self->strike);

        $self->_flambit(PAN_LEFT, $args{note}, 1);
        $self->pan_right;
        $self->note($args{note}, $self->strike);
    }
}


sub flam_drag { # 30
    my $self = shift;
    my %args = (
        critical => [0 .. 1],
        note => $self->SIXTEENTH,
        @_
    );

    $self->_flambit(PAN_RIGHT, $self->EIGHTH, 1);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->accent_note($self->EIGHTH);

    $self->_flambit(PAN_LEFT, $self->EIGHTH, 1);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->accent_note($self->EIGHTH);
}

sub _flambit {
    my ($self, $direction, $note, $accent) = @_;

    # Set pan direction.
    if ($direction) {
        $self->pan_right;
    }
    else {
        $self->pan_left;
    }

    # Play a grace note.
    $self->note($self->THIRTYSECOND, $self->strike);

    # Alternate pan direction.
    if ($direction) {
        $self->pan_left;
    }
    else {
        $self->pan_right;
    }

    # Should we accent the final note?
    if ($accent) {
        $self->accent_note($note);
    }
    else {
        $self->note($note, $self->strike);
    }
}


sub drag { # 31
    my $self = shift;
    my %args = (
        note => $self->QUARTER,
        @_
    );
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->_dragit(PAN_LEFT, $args{note}, 0);
}


sub single_drag_tap { # 32
    my $self = shift;
    my %args = (
        note => $self->EIGHTH,
        @_
    );

    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->accent_note($args{note});

    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->accent_note($args{note});

}


sub double_drag_tap { # 33
    my $self = shift;
    my %args = (
        note => $self->EIGHTH,
        @_
    );

    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->accent_note($args{note});

    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->accent_note($args{note});
}


sub lesson_25_two_and_three { # 34
    my $self = shift;
    my %args = (
        note => $self->EIGHTH,
        @_
    );
    $self->_dragit(PAN_RIGHT, $self->SIXTEENTH, 0);
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->accent_note($args{note});
}


sub single_dragadiddle { # 35
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        @_
    );

    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);

    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);
}


sub drag_paradiddle_1 { # 36
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        accent => $self->EIGHTH,
        @_
    );

    $self->pan_right;
    $self->accent_note($args{accent});
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);

    $self->pan_left;
    $self->accent_note($args{accent});
    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);

}


sub drag_paradiddle_2 { # 37
    my $self = shift;
    my %args = (
        note => $self->SIXTEENTH,
        accent => $self->EIGHTH,
        @_
    );

    $self->pan_right;
    $self->accent_note($args{accent});
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);

    $self->pan_left;
    $self->accent_note($args{accent});
    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->note($args{note}, $self->strike);

}


sub single_ratamacue { # 38
    my $self = shift;
    my %args = (
        note => $self->TRIPLET_SIXTEENTH,
        accent => $self->EIGHTH,
        @_
    );

    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->accent_note($args{accent});

    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->accent_note($args{accent});
}


sub double_ratamacue { # 39
    my $self = shift;
    my %args = (
        note => $self->TRIPLET_SIXTEENTH,
        accent => $self->EIGHTH,
        @_
    );

    $self->_dragit(PAN_RIGHT, $args{accent}, 1);
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->accent_note($args{accent});

    $self->_dragit(PAN_LEFT, $args{accent}, 1);
    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->accent_note($args{accent});

}


sub triple_ratamacue { # 40
    my $self = shift;
    my %args = (
        note => $self->TRIPLET_SIXTEENTH,
        accent => $self->EIGHTH,
        @_
    );

    $self->_dragit(PAN_RIGHT, $args{accent}, 0);
    $self->_dragit(PAN_RIGHT, $args{accent}, 0);
    $self->_dragit(PAN_RIGHT, $args{note}, 0);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->accent_note($args{accent});

    $self->_dragit(PAN_LEFT, $args{accent}, 0);
    $self->_dragit(PAN_LEFT, $args{accent}, 0);
    $self->_dragit(PAN_LEFT, $args{note}, 0);
    $self->pan_right;
    $self->note($args{note}, $self->strike);
    $self->pan_left;
    $self->note($args{note}, $self->strike);
    $self->pan_right;
    $self->accent_note($args{accent});

}

sub _groups_of { # Beat groupings
    my ($beat, $group) = @_;
    return ($beat - 1) % $group;
}

sub _dragit { # Common drag direction & accent.
    my ($self, $direction, $note, $accent) = @_;

    # Set pan direction.
    if ($direction) {
        $self->pan_right;
    }
    else {
        $self->pan_left;
    }

    # Drag it!
    $self->note($self->SIXTEENTH, $self->strike);
    $self->note($self->SIXTEENTH, $self->strike);

    # Set pan direction.
    if ($direction) {
        $self->pan_right;
    }
    else {
        $self->pan_left;
    }
    $self->pan_right;

    # Accented?
    if ($accent) {
        $self->accent_note($note);
    }
    else {
        $self->note($note, $self->strike);
    }
}


sub pan_left {
    my $self = shift;
    $self->pan(PAN_CENTER - $self->pan_width);
}
sub pan_center {
    my $self = shift;
    $self->pan(PAN_CENTER);
}
sub pan_right {
    my $self = shift;
    $self->pan(PAN_CENTER + $self->pan_width);
}


sub alternate_pan {
    my ($self, $pan, $width) = @_;

    # Pan hard left if not given.
    $pan = 0 unless defined $pan;

    # Set balance to center unless a width is given.
    $width = PAN_CENTER unless defined $width;

    # Pan the stereo balance.
    $self->pan( $pan ? abs($width - PAN_CENTER) : PAN_CENTER + $width );

    # Return the pan dimensions.
    return $pan, $width;
}


sub alternate_note {
    my $self = shift;
    my %args = (
        critical => [0, 1],
        alternate_pan => 2,
        groups_of => 0,
        note => $self->SIXTEENTH,
        accent => 0,
        @_
    );

    # Add single strokes with different types of pan values.
    for my $beat (@{$args{critical}}) {
        # Use a beat grouping if requested.
        if ($args{groups_of}) {
            $self->alternate_pan(_groups_of($beat, $args{groups_of}), $self->pan_width);
        }
        # Use beat modulo otherwise.
        elsif ($args{alternate_pan}) {
            $self->alternate_pan($beat % $args{alternate_pan}, $self->pan_width);
        }

        # Add the note but accent the 1st if requested.
        if ($beat == ($args{critical})[0] && $args{accent}) {
            $self->accent_note($args{note});
        }
        else {
            $self->note($args{note}, $self->strike);
        }
    }
}


sub single_stroke_n {
    my $self = shift;
    my %args = (
        critical => [4, 8],
        alternate_pan => 2,
        accent => $self->EIGHTH,
        note => $self->TRIPLET_SIXTEENTH,
        @_
    );

    # Assume critical beats have increasing order.
    for my $beat (1 .. (@{$args{critical}})[-1]) {
        # Alternate hands by modulo.
        $self->alternate_pan($beat % $args{alternate_pan}, $self->pan_width);

        # Accent if on a critical beat.
        if (grep { $beat == $_ } @{ $args{critical} }) {
            $self->accent_note($args{accent});
        }
        else {
            $self->note($args{note}, $self->strike);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Simple::Drummer::Rudiments

=head1 VERSION

version 0.0803

=head1 SYNOPSIS

  use MIDI::Simple::Drummer::Rudiments;
  my $d = MIDI::Simple::Drummer::Rudiments->new;
  $d->count_in;
  $d->single_stroke_roll for 1 .. $d->phrases;
  $d->write('single_stroke_roll.mid');

=head1 DESCRIPTION

This package contains rudiment patterns.

=head1 NAME

MIDI::Simple::Drummer::Rudiments - Drum rudiments

=head1 METHODS

=head2 new()

Sets pan_width to 1/4 distance from center.
Sets the reverb effect to 1 and chorus to 0.

=head1 I. Roll Rudiments

=head2 single_stroke_roll()

 tap tap tap tap tap tap tap tap
 r   l   r   l   r   l   r   l

1. Single Stroke Roll

=head2 single_stroke_four()

2. Single Stroke Four

 [    3    ]     [    3    ]
 tap tap tap tap tap tap tap tap
 r   l   r   l   r   l   r   l

=head2 single_stroke_seven()

3. Single Stroke Seven

 [           6         ]
 tap tap tap tap tap tap tap
 r   l   r   l   r   l   r

=head1 B. Multiple Bounce Rudiments

=head2 multiple_bounce_roll()

Not yet implemented...

=head2 triple_stroke_roll()

5. Triple Stroke Roll

 [    3    ] [    3    ]
 tap tap tap tap tap tap
 r   r   r   l   l   l

=head2 double_stroke_open_roll()

6. Double Stroke Open Roll (Long Roll)

Alternating diddles

 diddle diddle diddle diddle
 r  r   l  l   r  r   l  l

=head2 five_stroke_roll()

7. Five Stroke Roll

Two diddles, accent

 [       5       ]
 diddle diddle Tap
 r  r   l  l    R

=head2 six_stroke_roll()

8. Six Stroke Roll

Accent, 2 diddles, accent

 [         6         ]
 Tap diddle diddle Tap
 R   l  l   r  r   L

=head2 seven_stroke_roll()

9. Seven Stroke Roll

3 diddles, accent

 [           7          ]
 diddle diddle diddle Tap
 r  r   l  l   r  r   L

=head2 nine_stroke_roll()

10. Nine Stroke Roll

4 diddles, accent

 [              9              ]
 diddle diddle diddle diddle Tap
 r  r   l  l   r  r   l  l   R

=head2 ten_stroke_roll()

11. Ten Stroke Roll

4 diddles, 2 accents

 [                 10              ]
 diddle diddle diddle diddle Tap Tap
 r  r   l  l   r  r   l  l   R   L

=head2 eleven_stroke_roll()

12. Eleven Stroke Roll

5 diddles, accent

 [                  11                ]
 diddle diddle diddle diddle diddle Tap
 r  r   l  l   r  r   l  l   r  r   L

=head2 thirteen_stroke_roll()

13. Thirteen Stroke Roll

6 diddles, accent

 [                     13                    ]
 diddle diddle diddle diddle diddle diddle Tap
 r  r   l  l   r  r   l  l   r  r   l  l   R

=head2 fifteen_stroke_roll()

14. Fifteen Stroke Roll

7 diddles, accent

 [                         15                       ]
 diddle diddle diddle diddle diddle diddle diddle Tap
 r  r   l  l   r  r   l  l   r  r   l  l   r  r   L

=head2 seventeen_stroke_roll()

15. Seventeen Stroke Roll

8 diddles, accent

 [                             17                          ]
 diddle diddle diddle diddle diddle diddle diddle diddle Tap
 r  r   l  l   r  r   l  l   r  r   l  l   r  r   l  l   R

=head1 II. Diddle Rudiments

=head2 single_paradiddle()

16. Single Paradiddle

Accent, single stroke, diddle

 Tap tap diddle
 R   l   r  r

=head2 double_paradiddle()

17. Double Paradiddle

Accent, 3 single strokes, diddle

 Tap tap tap tap diddle
 R   l   r   l   r  r

=head2 triple_paradiddle()

18. Triple Paradiddle

6 single taps, diddle

 Tap tap tap tap tap tap diddle
 R   l   r   l   r   l   r  r

=head2 paradiddle_diddle()

19. Paradiddle-Diddle

2 alternating taps, 2 alternating diddles

 Tap tap tap tap diddle
 R   l   r   l   r  r

=head1 III. Flam Rudiments

=head2 flam()

20. Flam

 grace tap = flam
 r     l     r l

=head2 flam_accent()

21. Flam Accent

 Flam tap tap
 l R  l   r

=head2 flam_tap()

22. Flam Tap

Accented "flam-diddles"

 grace Diddle grace Diddle
     l R  r       r L  l

=head2 flamacue()

23. Flamacue

Flam, accent, 2 taps, flam

=head2 flam_paradiddle()

24. Flam Paradiddle

Accented flam, tap, diddle

=head2 flammed_mill()

25. Single flammed Mill

Accented flam-diddle, 2 taps

=head2 flam_paradiddle_diddle()

26. Flam Paradiddle-Diddle

=head2 pataflafla()

27. Pataflafla

=head2 swiss_army_triplet()

28. Swiss Army Triplet

=head2 inverted_flam_tap()

29. Inverted Flam Tap

=head2 flam_drag()

30. Flam Drag

=head1 IV. Drag Rudiments

=head2 drag()

31. Drag (Half drag or ruff)

=head2 single_drag_tap()

32. Single Drag Tap

=head2 double_drag_tap()

33. Double Drag Tap

=head2 lesson_25_two_and_three()

34. Lesson 25 (Two and Three)

=head2 single_dragadiddle()

35. Single Dragadiddle

=head2 drag_paradiddle_1()

36. Drag Paradiddle #1

=head2 drag_paradiddle_2()

37. Drag Paradiddle #2

=head2 single_ratamacue()

38. Single Ratamacue

=head2 double_ratamacue()

39. Double Ratamacue

=head2 triple_ratamacue()

40. Triple Ratamacue

=head2 pan_left(), pan_center(), pan_right()

 $d->pan_left($width);
 $d->pan_center();
 $d->pan_right($width);

Convenience methods to pan in different directions.

=head2 alternate_pan()

 $d->alternate_pan();
 $d->alternate_pan($direction);
 $d->alternate_pan($direction, $width);

Pan the stereo balance by an amount.

The pan B<direction> is B<0> for left (the default) and B<1> for right.

The B<width> can be any integer between B<1> and B<64> (the default).
A B<width> of B<64> means "stereo pan 100% left/right."

=head2 alternate_note()

Abstract method for alternating a note strike based on the beat and note value,
given the following parameters.

Arguments & defaults:

  critical      : Beats 0 through 4
  alternate_pan : Pan every other beat (group)
  groups_of     : Number of beats after which we pan
  note          : A 1/16th note

=head2 single_stroke_n()

Abstract method for multiple types of single stroke rolls of B<n> maximum beats.

Arguments & defaults:

  critical      : The 4 & 8 beats
  alternate_pan : Pan every other beat
  accent        : An 1/8th note
  note          : A triplet 1/16th note

=head1 TO DO

Tempo increase-decrease

With and without metronome

Straight or swing time

Duple or triple application (for 5 & 7 stroke rolls)

Touch velocity

=head1 SEE ALSO

L<MIDI::Simple::Drummer>, the F<eg/*> and F<t/*> scripts.

L<http://en.wikipedia.org/wiki/Drum_rudiment>

L<http://www.vicfirth.com/education/rudiments.php>

L<http://www.drumrudiments.com/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
