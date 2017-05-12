package List::Enumerator::Array;
use strict;
use warnings;

use base qw/List::Enumerator::Role/;
use overload
	'<<'  => \&push,
	'+'   => \&add,
	'@{}' => \&to_a,
	fallback => 1;

no warnings 'once';

__PACKAGE__->mk_accessors(qw/array index/);

sub BUILD {
	my ($self) = @_;
	$self->array([]) unless $self->array;
	$self->index(0);
}

sub _next {
	my ($self) = @_;

	my $i = $self->index;

	if ($i < @{$self->array}) {
		$self->index($i + 1);
		$self->array->[$i];
	} else {
		$self->stop;
	}
}

sub _rewind {
	my ($self) = @_;

	$self->index(0);
	$self;
}

sub to_a {
	my ($self) = @_;
	$self->array;
}
*as_list = \&to_a;

sub to_list {
	my ($self) = @_;
	@{$self->array};
}

sub push {
	my ($self, @args) = @_;
	CORE::push @{$self->array}, @args;
	$self;
}

sub add {
	my ($self, $array, $bool) = @_;
	$bool ? [ @$array, @{$self->array} ]
	      : [ @{$self->array}, @$array ];
}

sub unshift {
	my ($self, @args) = @_;
	CORE::unshift @{$self->array}, @args;
	$self;
}

sub prepend {
	my ($self, $args) = @_;
	CORE::unshift @{$self->array}, @$args;
	$self;
}

sub concat {
	my ($self, $args) = @_;
	CORE::push @{$self->array}, @$args;
	$self;
}
*append = \&concat;

sub shift {
	my ($self) = @_;
	CORE::shift @{$self->array};
}

sub pop {
	my ($self) = @_;
	CORE::pop @{$self->array};
}

sub delete {
	my ($self, $target, $block) = @_;
	my $ret = [];
	for (0 .. $#{$self->array}) {
		my $item = CORE::shift @{$self->array};
		if ($item eq $target) {
			CORE::push @$ret, $self->array->[$_];
		} else {
			CORE::push @{$self->array}, $item;
		}
	}
	@$ret ? $target
	      : ref($block) eq "CODE" ? $block->(local $_ = $target)
	                              : undef;
}

sub delete_if {
	my ($self, $block) = @_;
	my $ret = [];
	for my $index (0 .. $#{$self->array}) {
		my $item = CORE::shift @{$self->array};
		if ($block->(local $_ = $item)) {
			CORE::push @$ret, $item;
		} else {
			CORE::push @{$self->array}, $item;
		}
	}
	wantarray? @$ret : List::Enumerator::Array->new(array => $ret);
}

sub delete_at {
	my ($self, $index) = @_;
	return if $index > $#{$self->array};
	my $ret;
	for (0 .. $#{$self->array}) {
		my $item = CORE::shift @{$self->array};
		if ($_ == $index) {
			$ret = $item;
		} else {
			CORE::push @{$self->array}, $item;
		}
	}
	$ret;
}

# for performance
sub each {
	my ($self, $block) = @_;
	$self->rewind;


	if ($block) {
		eval {
			for (@{ $self->array }) {
				$block->(local $_ = $_);
			}
		}; if (Exception::Class->caught("StopIteration") ) { } else {
			my $e = Exception::Class->caught();
			ref $e ? $e->rethrow : die $e if $e;
		}
	}

	$self;
}

sub map {
	my ($self, $block) = @_;
	$self->rewind;
	my @ret;

	@ret = CORE::map({ $block->(local $_ = $_) } @{ $self->array });

	wantarray? @ret : List::Enumerator::Array->new(array => \@ret);
}


1;
__END__



