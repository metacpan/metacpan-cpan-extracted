package HTML::ListScraper::Occurence;

use warnings;
use strict;

sub new {
    my ($class, $length, $pos) = @_;
    my $self = { length => $length, spread => 1,
        edge => $pos, positions => [ $pos ] };
    bless $self, $class;

    return $self;
}

sub spread {
    my $self = shift;

    return $self->{spread};
}

sub len {
    my $self = shift;

    return $self->{length};
}

sub first_pos {
    my $self = shift;

    return $self->{positions}->[0];
}

sub log_score {
    my $self = shift;

    # return log($self->{spread}) * $self->{length};
    return log($self->{spread}) * log($self->{length});
}

sub positions {
    my $self = shift;

    return @{$self->{positions}};
}

sub append_pos {
    my ($self, $pos) = @_;

    my $count = scalar(@{$self->{positions}});
    if ($pos <= $self->{positions}->[$count - 1]) {
	die "position $pos out of order";
    }

    push @{$self->{positions}}, $pos;

    if ($self->{edge} + $self->{length} <= $pos) {
	++($self->{spread});
	$self->{edge} = $pos;
    }

    return $self->{spread};
}

1;
