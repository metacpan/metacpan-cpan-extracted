package MIDI::SP404sx::Note;
use strict;
use warnings;
use MIDI::SP404sx::Constants;
use base 'MIDI::SP404sx';
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($INFO);

sub velocity {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;
        if ( $val >= 0 && $val <= $MIDI::SP404sx::Constants::max_velocity ) {
            $self->{velocity} = $val;
            DEBUG "setting note velocity to $val";
        }
        else {
            ERROR "attempting to set velocity to invalid value $val";
        }
    }
    return $self->{velocity};
}

sub nlength {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;

        # XXX compute allowable max length to check, use pattern object
        if ( $val >= 0 ) {
            $self->{nlength} = $val;
            DEBUG "setting note length to $val";
        }
        else {
            ERROR "attempting to set negative note length: $val";
        }
    }
    return $self->{nlength};
}

sub pattern {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;
        if ( UNIVERSAL::isa( $val, 'MIDI::SP404sx::Pattern') ) {
            $self->{pattern} = $val;
            $self->{pattern}->notes( $self );
            DEBUG "adding note to pattern $val";
        }
        else {
            ERROR "trying to add note to something that's not a pattern: $val";
        }
    }
    return $self->{pattern};
}

sub position {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;

        # XXX compute allowable position, use pattern object
        if ( $val >= 0 ) {
            $self->{position} = $val;
            DEBUG "setting event position to $val";
        }
        else {
            ERROR "note position value out of range: $val";
        }
    }
    return $self->{position};
}

sub pitch {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;
        if ( $val >= 0 && $val <= $MIDI::SP404sx::Constants::max_note ) {
            $self->{pitch} = $val;
            DEBUG "setting midi note value to $val";
        }
        else {
            ERROR "note value out of range: $val";
        }
    }
    return $self->{pitch};
}

sub channel {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;
        if ( $val >= 0 && $val <= $MIDI::SP404sx::Constants::max_channel ) {
            $self->{channel} = $val;
            DEBUG "setting midi note channel to $val";
        }
        else {
            ERROR "midi note channel out of range: $val";
        }
    }
    return $self->{channel};
}

1;
