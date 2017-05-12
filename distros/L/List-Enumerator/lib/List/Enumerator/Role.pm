package List::Enumerator::Role;
use strict;
use warnings;

use Exception::Class ( "StopIteration" );

use List::Util;
use List::MoreUtils;

use base qw/Class::Accessor::Fast/;
no warnings 'once';

__PACKAGE__->mk_accessors(qw/is_beginning/);

# this is mix-in module

sub new {
	my ($class, %opts) = @_;
	my $self = $class->SUPER::new(\%opts);
	$self->can("BUILD") && $self->BUILD(\%opts);
	$self->is_beginning(1);
	$self;
}

sub next {
	my ($self) = @_;
	$self->is_beginning(0);
	$self->_next();
}

sub rewind {
	my ($self) = @_;
	unless ($self->is_beginning) {
		$self->_rewind();
		$self->is_beginning(1);
	}
	$self;
}

sub select {
	my ($self, $block) = @_;
	$self->rewind;

	List::Enumerator::Sub->new(
		next => sub {
			local $_;
			do {
				$_ = $self->next;
			} while (!$block->($_));
			$_;
		},
		rewind => sub {
			$self->rewind;
		}
	);
}
*find_all = \&select;

sub reject {
	my ($self, $block) = @_;
	$self->select(sub {
		!$block->($_);
	});
}

sub reduce {
	my ($self, $result, $block) = @_;
	$self->rewind;

	no strict 'refs';

	if (@_ == 2) {
		$block  = $result;
		$result = undef;
	};

	my $caller = caller;
	local *{$caller."::a"} = \my $a;
	local *{$caller."::b"} = \my $b;

	my @list = $self->to_list;
	unshift @list, $result if defined $result;

	$a = shift @list;
	for (@list) {
		$b = $_;
		$a = $block->($a, $b);
	};

	$a;
}
*inject = \&reduce;

sub slice {
	my ($self, $start, $end) = @_;
	my @list = $self->to_list;
	if (defined $end) {
		return () if abs $start > @list;
		$start = @list + $start if $start < 0;
		$end = @list + $end if $end < 0;
		$end = $#list if $end > $#list;
		return () if $start > @list;
		return () if $start > $end;

		my @ret = @list[$start .. $end];
		if (wantarray) {
			@ret ? @ret : ();
		} else {
			@ret ? List::Enumerator::Array->new(array => \@ret)
			     : List::Enumerator::Array->new(array => []);
		}
	} else {
		$list[$start];
	}
};

sub find {
	my ($self, $target) = @_;
	my $block = ref($target) eq "CODE" ? $target : sub { $_ eq $target };
	my $ret;
	$self->each(sub {
		if ($block->($self)) {
			$ret = $_;
			$self->stop;
		}
	});
	$ret;
}

sub first {
	my ($self, $n) = @_;
	my $ret;
	if (defined $n) {
		$ret = [ $self->take($n) ];
	} else {
		$self->rewind;
		$ret = $self->next;
		$self->rewind;
	}
	$ret;
}

sub last {
	my ($self, $n) = @_;
	my $ret;
	if (defined $n) {
		$ret = [ @{ $self->to_a }[-$n..-1] ];
	} else {
		$ret = $self->to_a->[-1];
	}
}

sub max {
	my ($self, $block) = @_;
	List::Util::max $self->to_list;
}

sub max_by {
	my ($self, $block) = @_;
	$self->sort_by($block)->last;
}

sub min {
	my ($self, $block) = @_;
	List::Util::min $self->to_list;
}

sub min_by {
	my ($self, $block) = @_;
	$self->sort_by($block)->first;
}

sub minmax_by {
	my ($self, $block) = @_;
	$block = sub { $_ } unless $block;
	my @ret = $self->sort_by($block)->to_list;
	wantarray? ($ret[0], $ret[$#ret]) : [ $ret[0], $ret[$#ret] ];
}
*minmax = \&minmax_by;

sub sort_by {
	my ($self, $block) = @_;
	List::Enumerator::Array->new(array => [
		map {
			$_->[0];
		}
		sort {
			$a->[1] <=> $b->[1];
		}
		map {
			[$_, $block->($_)];
		}
		$self->to_list
	]);
}

sub sort {
	my ($self, $block) = @_;
	my @ret = $block ? sort { $block->($a, $b) } $self->to_list : sort $self->to_list;
	wantarray? @ret : List::Enumerator::Array->new(array => \@ret);
}

sub sum {
	my ($self) = @_;
	$self->reduce(0, sub { $a + $b });
}

sub uniq {
	my ($self) = @_;
	my @ret = List::MoreUtils::uniq($self->to_list);
	wantarray? @ret : List::Enumerator::Array->new(array => \@ret);
}

sub grep {
	my ($self, $block) = @_;
	my @ret = grep { $block->($_) } $self->to_list;
	wantarray? @ret : List::Enumerator::Array->new(array => \@ret);
}

sub compact {
	my ($self) = @_;
	my @ret = grep { defined } $self->to_list;
	wantarray? @ret : List::Enumerator::Array->new(array => \@ret);
}

sub reverse {
	my ($self) = @_;
	my @ret = reverse $self->to_list;
	wantarray? @ret : List::Enumerator::Array->new(array => \@ret);
}

sub flatten {
	my ($self, $level) = @_;
	my $ret = _flatten($self->to_a, $level);
	wantarray? @$ret : List::Enumerator::Array->new(array => $ret);
}

sub _flatten {
	my ($array, $level) = @_;
	(defined($level) && $level <= 0) ? $array : [
		map {
			(ref($_) eq 'ARRAY') ? @{ _flatten($_, defined($level) ? $level - 1 : undef) } : $_;
		}
		@$array
	];
}

sub length {
	my ($self) = @_;
	scalar @{[ $self->to_list ]};
}
*size = \&length;

sub is_empty {
	my ($self) = @_;
	!$self->length;
}

sub index_of {
	my ($self, $target) = @_;
	$self->rewind;

	my $block = ref($target) eq "CODE" ? $target : sub { $_ eq $target };

	my $ret = 0;
	return eval {
		while (1) {
			my $item = $self->next;
			return $ret if $block->(local $_ = $item);
			$ret++;
		}
	}; if (Exception::Class->caught("StopIteration") ) { } else {
		my $e = Exception::Class->caught();
		ref $e ? $e->rethrow : die $e if $e;
	}

	undef;
}
*find_index = \&index_of;


sub chain {
	my ($self, @others) = @_;
	$self->rewind;

	my ($elements, $current);
	$elements = List::Enumerator::E([ map { List::Enumerator::E($_)->rewind } $self, @others ]);
	$current = $elements->next;

	my @cache = ();
	my $i = 0;
	my $ret = List::Enumerator::Sub->new(
		next => sub {
			my $ret;
			if ($i < @cache) {
				$ret = $cache[$i];
			} else {
				eval {
					$ret = $current->next;
					push @cache, $ret;
				}; if (Exception::Class->caught("StopIteration") ) {
					$current = $elements->next;
					$ret = $current->next;
					push @cache, $ret;
				} else {
					my $e = Exception::Class->caught();
					ref $e ? $e->rethrow : die $e if $e;
				}
			}
			$i++;
			$ret;
		},
		rewind => sub {
			$i = 0;
		}
	);

	wantarray? $ret->to_list : $ret;
}

sub take {
	my ($self, $arg) = @_;
	$self->rewind;

	my $ret;
	if (ref $arg eq "CODE") {
		$ret = List::Enumerator::Sub->new(
			next => sub {
				local $_ = $self->next;
				if ($arg->($_)) {
					$_;
				} else {
					StopIteration->throw;
				}
			},
			rewind => sub {
				$self->rewind;
			}
		);
	} else {
		my $i;
		$ret = List::Enumerator::Sub->new(
			next => sub {
				if ($i++ < $arg) {
					$self->next;
				} else {
					StopIteration->throw;
				}
			},
			rewind => sub {
				$self->rewind;
				$i = 0;
			}
		);
	}
	wantarray? $ret->to_list : $ret;
}
*take_while = \&take;

sub drop {
	my ($self, $arg) = @_;
	$self->rewind;

	my $ret;
	if (ref $arg eq "CODE") {
		my $first;
		$ret = List::Enumerator::Sub->new(
			next => sub {
				my $ret;
				unless ($first) {
					do { $first = $self->next } while ($arg->(local $_ = $first));
					$ret = $first;
				} else {
					$ret = $self->next;
				}
				$ret;
			},
			rewind => sub {
				$self->rewind;
				$first = undef;
			}
		);
	} else {
		my $i = $arg;
		$ret = List::Enumerator::Sub->new(
			next => sub {
				$self->next while (0 < $i--);
				$self->next;
			},
			rewind => sub {
				$self->rewind;
				$i = $arg;
			}
		);
	}
	wantarray? $ret->to_list : $ret;
}
*drop_while = \&drop;

sub every {
	my ($self, $block) = @_;
	for ($self->to_list) {
		return 0 unless $block->($_);
	}
	return 1;
}
*all = \&every;

sub some {
	my ($self, $block) = @_;
	for ($self->to_list) {
		return 1 if $block->($_);
	}
	return 0;
}
*any = \&some;


sub none {
	my ($self, $block) = @_;
	$block = sub { $_ } unless $block;

	for ($self->to_list) {
		return 0 if $block->($_);
	}
	return 1;
}

sub one {
	my ($self, $block) = @_;
	$block = sub { $_ } unless $block;

	my $ret = 0;
	for ($self->to_list) {
		if ($block->($_)) {
			if ($ret) {
				return 0;
			} else {
				$ret = 1;
			}
		}
	}
	return $ret;
}

sub zip {
	my ($self, @others) = @_;
	$self->rewind;

	my $elements = [
		map {
			List::Enumerator::E($_)->rewind;
		}
		@others
	];

	my @cache = ();
	my $ret = List::Enumerator::Sub->new(
		next => sub {
			my $ret = [];
			push @$ret, $self->next;
			for (@$elements) {
				my $n;
				eval {
					$n = $_->next;
				}; if (Exception::Class->caught("StopIteration") ) {
					$n = undef;
				} else {
					my $e = Exception::Class->caught();
					ref $e ? $e->rethrow : die $e if $e;
				}
				push @$ret, $n;
			}
			push @cache, $ret;
			$ret;
		},
		rewind => sub {
			my $i = 0;
			$_->next_sub(sub {
				if ($i < @cache) {
					$cache[$i++];
				} else {
					StopIteration->throw;
				}
			});
			$_->rewind_sub(sub {
				$i = 0;
			});
		}
	);

	wantarray? $ret->to_list : $ret;
}

sub with_index {
	my ($self, $start) = @_;
	$self->zip(List::Enumerator::E($start)->countup);
}

sub countup {
	my ($self, $lim) = @_;
	my $start = eval { $self->next } || 0;
	my $i = $start;
	List::Enumerator::Sub->new(
		next => sub {
			($lim && $i > $lim) && StopIteration->throw;
			$i++;
		},
		rewind => sub {
			$i = $start;
		}
	);
}
*countup_to = \&countup;
*to = \&countup;


sub cycle {
	my ($self) = @_;
	$self->rewind;

	my @cache = ();
	List::Enumerator::Sub->new(
		next => sub {
			my ($this) = @_;

			my $ret;
			eval {
				$ret = $self->next;
				push @cache, $ret;
			}; if (Exception::Class->caught("StopIteration") ) {
				my $i = -1;
				$this->next_sub(sub {
					$cache[++$i % @cache];
				});
				$ret = $this->next;
			} else {
				my $e = Exception::Class->caught();
				ref $e ? $e->rethrow : die $e if $e;
			}
			$ret;
		},
		rewind => sub {
			$self->rewind;
			@cache = ();
		}
	);
}

sub join {
	my ($self, $sep) = @_;
	join $sep || "", $self->to_list;
}

sub group_by {
	my ($self, $block) = @_;
	$self->reduce({}, sub {
		local $_ = $b;
		my $r = $block->($b);
		$a->{$r} ||= [];
		push @{ $a->{$r} }, $b;
		$a;
	});
}

sub partition {
	my ($self, $block) = @_;
	my $ret = $self->group_by(sub {
		$block->($_) ? 1 : 0;
	});

	wantarray? ($ret->{1}, $ret->{0}) : [$ret->{1}, $ret->{0}];
}

sub is_include {
	my ($self, $target) = @_;
	$self->some(sub { $_ eq $target });
}
*include = \&is_include;

sub map {
	my ($self, $block) = @_;
	$self->rewind;

	my $ret = List::Enumerator::Sub->new(
		next => sub {
			local $_ = $self->next;
			$block->($_);
		},
		rewind => sub {
			$self->rewind;
		}
	);
	wantarray? $ret->to_list : $ret;
}
*collect = \&map;

sub each {
	my ($self, $block) = @_;
	$self->rewind;

	eval {
		while (1) {
			local $_ = $self->next;
			$block->($_) if $block;
		}
	}; if (Exception::Class->caught("StopIteration") ) { } else {
		my $e = Exception::Class->caught();
		ref $e ? $e->rethrow : die $e if $e;
	}

	$self;
}

sub to_list {
	my ($self) = @_;

	my @ret = ();
	$self->each(sub {
		push @ret, $_;
	});

	wantarray? @ret : [ @ret ];
}

sub each_index {
	my ($self, $block) = @_;
	$self->rewind;

	my $i = 0;
	eval {
		while (1) {
			$self->next;
			local $_ = $i++;
			$block->($_) if $block;
		}
	}; if (Exception::Class->caught("StopIteration") ) { } else {
		my $e = Exception::Class->caught();
		ref $e ? $e->rethrow : die $e if $e;
	}

	wantarray? $self->to_list : $self;
}

sub each_slice {
	my ($self, $n, $block) = @_;
	$self->rewind;

	my $ret = List::Enumerator::Sub->new(
		next => sub {
			my $arg = [];
			my $i   = $n - 1;
			push @$arg, $self->next;
			while ($i--) {
				eval {
					push @$arg, $self->next;
				}; if (Exception::Class->caught("StopIteration") ) { } else {
					my $e = Exception::Class->caught();
					ref $e ? $e->rethrow : die $e if $e;
				}
			}
			$arg;
		},
		rewind => sub {
			$self->rewind;
		}
	);
	if ($block) {
		$ret->each($block);
	}
	wantarray? $ret->to_list : $ret;
}

sub each_cons {
	my ($self, $n, $block) = @_;
	$self->rewind;

	my @memo = ();
	my $ret = List::Enumerator::Sub->new(
		next => sub {
			if (@memo < $n) {
				my $i = $n;
				push @memo, $self->next while $i--;
			} else {
				shift @memo;
				push @memo, $self->next;
			}
			[ @memo ];
		},
		rewind => sub {
			$self->rewind;
			@memo = ();
		}
	);
	if ($block) {
		$ret->each($block);
	}
	wantarray? $ret->to_list : $ret;
}

sub choice {
	my ($self) = @_;
	$self->[int(rand($self->length))];
}
*sample = \&choice;

sub shuffle {
	my ($self) = @_;
	my @shuffled = List::Util::shuffle($self->to_list);
	wantarray? @shuffled : List::Enumerator::Array->new(array => \@shuffled);
}

sub transpose {
	my ($self) = @_;
	my ($first, @rest) = $self->to_list;

	if (defined $first) {
		die "not a matrix" unless ref($first) eq "ARRAY";
		List::Enumerator::Array->new(array => $first)->zip(@rest);
	} else {
		List::Enumerator::Array->new(array => [])->to_list;
	}
}

sub to_a {
	my ($self) = @_;
	[ $self->to_list ];
}

sub expand {
	my ($self) = @_;
	List::Enumerator::Array->new(array => $self->to_a);
}
*dup = \&expand;

sub dump {
	my ($self) = @_;
	require Data::Dumper;
	Data::Dumper->new([ $self->to_a ])->Purity(1)->Terse(1)->Dump;
}


sub _next {
	die "Not implemented.";
}

sub _rewind {
	die "Not implemented.";
}

sub stop {
	my ($self) = @_;
	StopIteration->throw;
}

1;
__END__



