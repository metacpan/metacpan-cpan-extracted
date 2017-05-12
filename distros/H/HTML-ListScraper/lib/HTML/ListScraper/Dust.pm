package HTML::ListScraper::Dust;

use warnings;
use strict;

use Class::Generate qw(class);

class 'HTML::ListScraper::Alignment' => {
    score => { type => '$', required => 1 },
    positions => { type => '@', required => 1 }
};

sub new {
    my $class = shift;
    my $self = { align => [] };
    bless $self, $class;

    return $self;
}

sub add_alignment {
    my ($self, $score, $pos) = @_;

    push @{$self->{align}},
        HTML::ListScraper::Alignment->new(score => $score,
					  positions => $pos);
}

sub add_alignments_before {
    my ($self, $alignments) = @_;

    unshift @{$self->{align}}, @$alignments;
}

sub add_alignments_after {
    my ($self, $alignments) = @_;

    push @{$self->{align}}, @$alignments;
}

sub get_alignments {
    my $self = shift;

    return wantarray ? @{$self->{align}} : $self->{align};
}

1;
