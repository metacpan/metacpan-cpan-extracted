package HTML::ListScraper::Sweep;

use warnings;
use strict;

use Algorithm::NeedlemanWunsch;
use HTML::ListScraper::Dust;

my $match_score = 2;
my $mismatch_score = -4;
my $gap_open_penalty = -2;
my $gap_extend_penalty = -1;

sub _score_sub {
    my ($a, $b) = @_;

    return ($a eq $b) ? $match_score : $mismatch_score;
}

sub new {
    my $class = shift;
    my $self = { @_ };

    my $iseq = $self->{book}->get_internal_sequence;
    my $first = $self->{begin};
    my $last = $self->{end} - 1;
    # warn "sweeping $first .. $last\n";
    my @seq = @$iseq[$first .. $last];
    $self->{haystack} = \@seq;

    my @sign = split //, $self->{sign};
    if (scalar(@sign) < 2) {
        die "sequence signature too short";
    }

    $self->{needle} = \@sign;

    bless $self, $class;

    return $self;
}

sub create_dust {
    my $self = shift;

    $self->{dust} = HTML::ListScraper::Dust->new();

    if (scalar(@{$self->{haystack}}) > 2) {
        my $matcher = Algorithm::NeedlemanWunsch->new(\&_score_sub);
	$matcher->gap_open_penalty($gap_open_penalty);
	$matcher->gap_extend_penalty($gap_extend_penalty);
	$matcher->local(1);

	$self->{found} = [ ];

	my $score = $matcher->align($self->{haystack},
            $self->{needle},
            { select_align => sub { $self->_on_align($_[0]); } });

	my $found_count = scalar(@{$self->{found}});
	if ($found_count >= 2) {
	    my @round = $self->_make_presentable;
	    if ((scalar(@round) >= 2) &&
		(scalar(@round) > (scalar(@{$self->{needle}}) / 2))) {
	        if (scalar(@round) < $found_count) {
		    $score = undef;
		}

		my $begin = $self->{begin};
		my $end = $round[0];
		if ($begin < $end) {
		    my $sweep = HTML::ListScraper::Sweep->new(
			book => $self->{book}, sign => $self->{sign},
			begin => $begin, end => $end);
		    my $dust = $sweep->create_dust;
		    my $before = $dust->get_alignments;
		    $self->{dust}->add_alignments_before($before);
		}

		$self->{dust}->add_alignment($score, \@round);

		$begin = $round[-1] + 1;
		$end = $self->{end};
		if ($begin < $end) {
		    my $sweep = HTML::ListScraper::Sweep->new(
			book => $self->{book}, sign => $self->{sign},
			begin => $begin, end => $end);
		    my $dust = $sweep->create_dust;
		    my $after = $dust->get_alignments;
		    $self->{dust}->add_alignments_after($after);
		}
	    }
	}
    }

    return $self->{dust};
}

sub _on_align {
    my ($self, $arg) = @_;

    if (exists($arg->{align})) {
        my ($i, $j) = @{$arg->{align}};

	if ($self->{haystack}->[$i] eq $self->{needle}->[$j]) {
	    unshift @{$self->{found}}, $self->{begin} + $i;
	    return 'align';
	}
    }

    foreach (qw(shift_a shift_b)) {
        if (exists($arg->{$_})) {
	    return $_;
        }
    }

    return 'align';
}

sub _make_presentable {
    my $self = shift;

    if ($self->{book}->shapeless) {
        return @{$self->{found}};
    }

    my %core;
    my @stack;
    foreach (@{$self->{found}}) {
        my $cur_tag = $self->{book}->get_tag($_);
        my $name = $cur_tag->name;
	my $stem = $name;
	$stem =~ s~^\/~~;

	if ($name eq $stem) {
	    push @stack, $cur_tag;
	} else {
	    my $skip = 0;
	    while (!$skip && scalar(@stack) &&
		    ($stack[scalar(@stack) - 1]->name ne $stem)) {
	        my $top_tag = $stack[scalar(@stack) - 1];
		if ($self->{book}->is_unclosed_tag($top_tag->name)) {
		    $core{$top_tag->index} = 1;
		    pop @stack;
		} else {
		    $skip = 1;
		}
	    }

	    if (!$skip && scalar(@stack)) {
	        my $top_tag = pop @stack;
		$core{$top_tag->index} = 1;
		$core{$_} = 1;
	    }
	}
    }

    while (scalar(@stack)) {
        my $top_tag = pop @stack;
	if ($self->{book}->is_unclosed_tag($top_tag->name)) {
	    $core{$top_tag->index} = 1;
	}
    }

    return sort { $a <=> $b; } keys %core;
}

1;
