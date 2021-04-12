package MIDI::SP404sx::Pattern;
use strict;
use warnings;
use MIDI::SP404sx::Constants;
use base 'MIDI::SP404sx';
use Log::Log4perl qw(:easy);

sub tempo {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;
        if ( $val >= $MIDI::SP404sx::Constants::min_bpm && $val <= $MIDI::SP404sx::Constants::max_bpm ) {
            $self->{tempo} = $val;
        }
        else {
            die $val;
        }
    }
    return $self->{tempo};
}

sub nlength {
    my $self = shift;
    if ( @_ ) {
        my $val = shift;
        if ( $val >= $MIDI::SP404sx::Constants::min_length && $val <= $MIDI::SP404sx::Constants::max_length ) {
            DEBUG "setting pattern length to $val";
            $self->{nlength} = $val;
        }
        else {
            die $val;
        }
    }
    return $self->{nlength};
}

sub notes {
    my $self = shift;
    $self->{notes} = [] if not $self->{notes};
    if ( @_ ) {
        for my $val ( @_ ) {
            push @{ $self->{notes} }, $val;
        }
    }
    return @{ $self->{notes} };
}

1;
