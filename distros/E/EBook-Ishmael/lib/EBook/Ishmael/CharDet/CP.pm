package EBook::Ishmael::CharDet::CP;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use EBook::Ishmael::CharDet::Constants qw(:CONSTANTS);

sub new {

    my ($class) = @_;

    my $self = {
        Freqs   => 0,
        Bigrams => 0,
        Prev    => undef,
        Total   => 0,
    };
    return bless $self, $class;

}

sub take {

    my ($self, $data) = @_;

    for my $i (0 .. length($data) - 1) {
        my $c = substr $data, $i, 1;
        if ($self->ignore($c)) {
            undef $self->{Prev};
        } elsif (defined $self->{Prev}) {
            if ($self->freq_bigram($self->{Prev} . $c)) {
                $self->{Freqs}++;
            }
            $self->{Bigrams}++;
            $self->{Prev} = $c;
        } else {
            $self->{Prev} = $c;
        }
        $self->{Total}++;
    }

    return TAKE_OK;

}

sub ignore { die "ignore() not implemented" }

sub freq_bigram { die "freq_bigram() not implemented" }

sub dist_ratio { die "dist_ratio() not implemented" }

sub confidence {

    my ($self) = @_;

    if ($self->{Total} == 0) {
        return 0;
    }

    if ($self->{Freqs} == $self->{Bigrams}) {
        return 0.99;
    }

    return $self->{Freqs} / $self->{Bigrams};

}

sub bad { 0 }

sub encoding { die "encoding() not implemented" }

1;

