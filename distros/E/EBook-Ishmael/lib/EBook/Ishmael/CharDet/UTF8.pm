package EBook::Ishmael::CharDet::UTF8;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use EBook::Ishmael::CharDet::Constants qw(:CONSTANTS);

my $ONE_CHAR_PROB = 0.5;
my $THRESHOLD = 7;

sub new {

    my ($class) = @_;

    my $self = {
        Code  => undef,
        Left  => 0,
        MBs   => 0,
        Total => 0,
        Bad   => 0,
    };
    return bless $self, $class;

}

sub take {

    my ($self, $bytes) = @_;

    return TAKE_BAD if $self->{Bad};
    return TAKE_MUST_BE if $self->{MBs} >= $THRESHOLD;

    for my $i (0 .. length($bytes)-1) {
        my $b = ord(substr $bytes, $i, 1) & 0xff;
        if (not defined $self->{Code}) {
            # ASCII
            if (not $b & 0x80) {
                $self->{Total}++;
                next;
            # 2-byte character (0b110...)
            } elsif ($b >> 5 == 0b110) {
                $self->{Code} = $b & 0b11111;
                $self->{Left} = 1;
            # 3-byte character (0b1110...)
            } elsif ($b >> 4 == 0b1110) {
                $self->{Code} = $b & 0b1111;
                $self->{Left} = 2;
            # 4-byte character (0b11110...)
            } elsif ($b >> 3 == 0b11110) {
                $self->{Code} = $b & 0b111;
                $self->{Left} = 3;
            # Invalid UTF8
            } else {
                $self->{Bad} = 1;
                return TAKE_BAD;
            }
        } else {
            if ($b >> 6 != 0b10) {
                $self->{Bad} = 1;
                return TAKE_BAD;
            }
            $self->{Code} = ($self->{Code} << 6) | ($b & 0b111111);
            $self->{Left}--;
            if ($self->{Left} == 0) {
                $self->{Total}++;
                $self->{MBs}++;
                undef $self->{Code};
                return TAKE_MUST_BE if $self->{MBs} >= $THRESHOLD;
            }
        }
    }

    return TAKE_OK;

}

sub confidence {

    my ($self) = @_;

    if ($self->{Bad} or $self->{MBs} == 0) {
        return 0;
    }

    # >= 6, we effectively get 0.99
    if ($self->{MBs} < 6) {
        return 1.0 - ($ONE_CHAR_PROB ** $self->{MBs});
    } else {
        return 0.99;
    }

}

sub bad {

    my ($self) = @_;

    return $self->{Bad};

}

sub encoding { 'UTF-8' }

1;
