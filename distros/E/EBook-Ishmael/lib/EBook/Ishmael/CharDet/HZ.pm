package EBook::Ishmael::CharDet::HZ;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use EBook::Ishmael::CharDet::Constants qw(:CONSTANTS);

my $ONE_CHAR_PROB = 0.5;
my $THRESHOLD = 7;

sub new {

    my ($class) = @_;

    my $self = {
        InCode   => 0,
        Tilde    => 0,
        Consumed => 0,
        Codes    => 0,
        Total    => 0,
        Bad      => 0,
    };
    return bless $self, $class;

}

sub take {

    my ($self, $data) = @_;

    return TAKE_BAD if $self->{Bad};
    return TAKE_MUST_BE if $self->{Codes} >= $THRESHOLD;

    for my $i (0 .. length($data) - 1) {
        my $b = ord(substr $data, $i, 1) & 0xff;
        if ($self->{InCode}) {
            if ($self->{Tilde}) {
                if ($b != ord '}') {
                    $self->{Bad} = 1;
                    return TAKE_BAD;
                }
                $self->{Consumed} = 0;
                $self->{InCode} = 0;
                $self->{Tilde} = 0;
                $self->{Codes}++;
                $self->{Total}++;
                return TAKE_MUST_BE if $self->{Codes} >= $THRESHOLD;
            } elsif ($b == ord '~') {
                if ($self->{Consumed} % 2 != 0) {
                    $self->{Bad} = 1;
                    return TAKE_BAD;
                }
                $self->{Tilde} = 1;
            } elsif ($self->{Consumed} % 2 == 0) {
                if ($b < 0x21 or $b > 0x77) {
                    $self->{Bad} = 1;
                    return TAKE_BAD;
                }
                $self->{Consumed}++;
            } elsif ($self->{Consumed} % 2 != 0) {
                if ($b < 0x21 or $b > 0x7e) {
                    $self->{Bad} = 1;
                    return TAKE_BAD;
                }
                $self->{Consumed}++;
                $self->{Codes}++;
                $self->{Total}++;
            }
        } elsif ($self->{Tilde}) {
            if ($b == ord '~' or $b == ord "\n") {
                $self->{Total}++;
                $self->{Tilde} = 0;
            } elsif ($b == ord '{') {
                $self->{Tilde} = 0;
                $self->{InCode} = 1;
            } else {
                $self->{Bad} = 1;
                return TAKE_BAD;
            }
        } else {
            if ($b == ord '~') {
                $self->{Tilde} = 1;
            } else {
                $self->{Total}++;
            }
        }
    }

    return TAKE_OK;

}

sub confidence {

    my ($self) = @_;

    if ($self->{Bad} or $self->{Total} == 0) {
        return 0;
    }

    if ($self->{Codes} < 6) {
        return 1.0 - ($ONE_CHAR_PROB ** $self->{Codes});
    } else {
        return 0.99;
    }

}

sub bad {

    my ($self) = @_;

    return $self->{Bad};

}

sub encoding { 'hz' }

1;
