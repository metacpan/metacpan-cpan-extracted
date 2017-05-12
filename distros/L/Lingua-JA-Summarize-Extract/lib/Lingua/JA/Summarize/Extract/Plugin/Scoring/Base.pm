package Lingua::JA::Summarize::Extract::Plugin::Scoring::Base;

use strict;
use base qw( Lingua::JA::Summarize::Extract::Plugin );

sub scoring {
    my($self, $term_list) = @_;

    my $part_info = {};
    for my $term (keys %{ $term_list }) {
        my @words = split /\s/, $term;
        next if @words < 2;

        for my $i (0 .. $#words - 1) {
            $part_info->{$words[$i]}->{pre}++;
            $part_info->{$words[$i + 1]}->{post}++;
        }
    }

    my $ret_list = {};
    for my $term (keys %{ $term_list }) {
        my $score = 1;
        my @words = split /\s/, $term;
        for my $word (@words){
            for my $key (qw/ pre post /) {
                $score *= ($part_info->{$word}->{$key} || 0) + 1;
            }
        }

        $score = $score ** (1 / (2 * $self->rate * (scalar @words || 1)));
        $score *= $term_list->{$term};
        $ret_list->{$term} = $score;
    }

    $self->scoring_fixup($ret_list);
}

sub scoring_fixup {
    my($self, $scoring) = @_;
    my @fixdata = map {
        +{
            term  => $_,
            score => $scoring->{$_},
        }
    } sort { $scoring->{$b} <=> $scoring->{$a} } keys %{ $scoring };
    return \@fixdata;
}

1;
