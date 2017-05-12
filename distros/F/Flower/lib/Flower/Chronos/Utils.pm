package Flower::Chronos::Utils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(are_hashes_equal parse_time);

use Time::Piece;

sub are_hashes_equal {
    my ($first, $second) = @_;

    foreach my $key (keys %$first) {
        if (defined $first->{$key} && defined $second->{$key}) {
            if ($first->{$key} ne $second->{$key}) {
                return 0;
            }
        }
        elsif (!defined $first->{$key} && !defined $second->{$key}) {
            next;
        }
        else {
            return 0;
        }
    }

    return 1;
}

sub parse_time {
    my ($string) = @_;

    return $string if $string =~ m/^\d+$/;

    my $format = '%Y-%m-%d';
    if ($string =~ m/ \d\d:\d\d:\d\d$/) {
        $format .= ' %T';
    }
    return Time::Piece->strptime($string, $format)->epoch;
}

1;
