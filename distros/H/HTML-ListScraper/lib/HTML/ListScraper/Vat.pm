package HTML::ListScraper::Vat;

use warnings;
use strict;

use Class::Generate;
use HTML::ListScraper::Foam;
use HTML::ListScraper::Occurence;

my $epsilon = 0.0001;

sub new {
    my ($class, $book, $min_count) = @_;
    my $self = { book => $book, min_count => $min_count };
    $self->{seq} = $book->get_internal_sequence;
    bless $self, $class;

    return $self;
}

sub create_sequence {
    my $self = shift;

    my $count = scalar(@{$self->{seq}});
    if ($count < $self->{min_count}) {
	return undef; # if we had a verbose mode, we would warn here
    }

    $self->{foam} = HTML::ListScraper::Foam->new($self->{book});

    $self->{map} = { };
    $self->_fill_pair_map;
    while ($self->_has_cand) {
	$self->_prune_map;
	$self->_skim_map;
	$self->_grow_map;
    }

    return $self->{foam};
}

sub _has_cand {
    my $self = shift;

    return scalar(keys %{$self->{map}});
}

sub _fill_pair_map {
    my $self = shift;

    $self->{max_spread} = 1;
    $self->{length} = 2;

    my $count = scalar(@{$self->{seq}});

    my $first = $self->{seq}->[0];
    my $i = 1;
    while ($i < $count) {
	my $second = $self->{seq}->[$i];
	my $seq = $first . $second;
	if (!exists($self->{map}->{$seq})) {
	    $self->{map}->{$seq} =
	        HTML::ListScraper::Occurence->new(2, $i - 1);
	} else {
	    my $spread = $self->{map}->{$seq}->append_pos($i - 1);
	    if ($spread > $self->{max_spread}) {
		$self->{max_spread} = $spread;
	    }
	}

	$first = $second;
	++$i;
    }
}

sub _prune_map {
    my $self = shift;

    my @seq = keys %{$self->{map}};
    foreach my $seq (@seq) {
	my $n = $self->{map}->{$seq}->spread;
	if ($n < $self->{min_count}) {
	    delete $self->{map}->{$seq};
	}
    }
}

sub _skim_map {
    my $self = shift;

    foreach my $seq (keys %{$self->{map}}) {
	my $occ = $self->{map}->{$seq};
	if ($occ->spread == $self->{max_spread}) {
	    if (!$self->{foam}->store($seq, $occ)) {
		# the best isn't good enough
		return;
	    }
	}
    }
}

sub _grow_map {
    my $self = shift;

    my $max_spread = 1;
    my $length = $self->{length} + 1;
    my $map = { };
    foreach my $seq (keys %{$self->{map}}) {
	my $occ = $self->{map}->{$seq};
	foreach my $pos ($occ->positions) {
	    if ($pos > 0) {
		my $npos = $pos - 1;
		my $nseq = $self->{seq}->[$npos] . $seq;

		if (!exists($map->{$nseq})) {
		    $map->{$nseq} =
		      HTML::ListScraper::Occurence->new($length, $npos);
		} else {
		    my $spread = $map->{$nseq}->append_pos($npos);
		    if ($spread > $max_spread) {
			$max_spread = $spread;
		    }
		}
	    }
	}
    }

    $self->{map} = $map;
    $self->{length} = $length;
    $self->{max_spread} = $max_spread;
}

1;
