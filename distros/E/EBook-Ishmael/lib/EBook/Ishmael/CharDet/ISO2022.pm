package EBook::Ishmael::CharDet::ISO2022;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use EBook::Ishmael::CharDet::Constants qw(:CONSTANTS);

use List::Util qw(any);

use constant {
    STATE_UNKNOWN => 0,
    STATE_GOOD    => 1,
    STATE_BAD     => 2,
};

sub initialize {

    my ($self) = @_;

    %$self = (
        InEscape => 0,
        Cur      => '',
        State    => STATE_UNKNOWN,
        Unique   => [],
    );

}

sub new {

    my ($class) = @_;

    my $self = bless {}, $class;
    $self->initialize;

    return $self;

}

sub take {

    my ($self, $data) = @_;

    for my $i (0 .. length($data) - 1) {
        my $b = ord(substr $data, $i, 1) & 0xff;
        if (!$self->{InEscape} && $b == ord "\e") {
            $self->{InEscape} = 1;
        } elsif ($self->{InEscape}) {
            if ($b >= 0x20 && $b <= 0x2f) {
                $self->{Cur} .= chr $b;
            } elsif ($b >= 0x30 && $b <= 0x7e) {
                $self->{Cur} .= chr $b;
                $self->{InEscape} = 0;
                if (any { $_ eq $self->{Cur} } @{ $self->{Unique} }) {
                    $self->{State} = STATE_GOOD;
                    return TAKE_MUST_BE;
                }
                $self->{Cur} = '';
            } else {
                $self->{State} = STATE_BAD;
                return TAKE_BAD;
            }
        }
    }

    return TAKE_OK;

}

sub confidence {

    my ($self) = @_;

    if ($self->{State} == STATE_GOOD) {
        return 1.0;
    } else {
        return 0;
    }

}

sub bad {

    my ($self) = @_;

    return $self->{State} == STATE_BAD;

}

sub encoding { die "encoding not set" }

1;
