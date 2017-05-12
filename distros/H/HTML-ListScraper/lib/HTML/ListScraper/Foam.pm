package HTML::ListScraper::Foam;

use warnings;
use strict;

my $epsilon = 0.0001;

sub new {
    my ($class, $book) = @_;
    my $self = { book => $book, map => { } };
    bless $self, $class;

    return $self;
}

sub get_sequences {
    my $self = shift;

    my $os = $self->{max_log_score};
    return grep {
	$self->{map}->{$_}->log_score + $epsilon >= $os;
    } keys %{$self->{map}};
}

sub get_occurence {
    my ($self, $seq) = @_;

    return $self->{map}->{$seq};
}

sub store {
    my ($self, $seq, $occ) = @_;

    if (exists($self->{map}->{$seq})) {
	die "duplicated sequence";
    }

    if (!exists($self->{max_log_score})) {
        $self->_cond_store($seq, $occ);
	return 1;
    }

    my $s = $occ->log_score;
    my $os = $self->{max_log_score};
    if ($s + $epsilon < $os) {
	return 0;
    }

    if ($s > $os) {
        if ($self->_cond_store($seq, $occ)) {
	    if ($s > $os + $epsilon) {
	        $self->_prune_map;
	    }
	}
    } else {
        $self->_cond_store($seq, $occ);
    }

    return 1;
}

sub _cond_store {
    my ($self, $seq, $occ) = @_;

    if (!$self->{book}->is_presentable($occ->first_pos, $occ->len)) {
        return 0;
    }

    $self->{max_log_score} = $occ->log_score;
    $self->{map}->{$seq} = $occ;
    return 1;
}

sub _prune_map {
    my $self = shift;

    my $os = $self->{max_log_score};
    my @seq = keys %{$self->{map}};
    foreach my $seq (@seq) {
	my $s = $self->{map}->{$seq}->log_score;
	if ($s + $epsilon < $os) {
	    delete $self->{map}->{$seq};
	}
    }
}

1;
