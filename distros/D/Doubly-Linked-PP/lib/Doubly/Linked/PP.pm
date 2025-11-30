package Doubly::Linked::PP;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

sub new {
	my ($pkg, $data) = @_;

	return bless {
		data => $data,
		next => undef,
		prev => undef
	}, ref $pkg || $pkg;
}

sub length {
	my ($self) = @_;

	my $i = $self->{next} || $self->{data} ? 1 : 0;

	while ($self->next) {
		$self = $self->next;
		$i++;
	}

	return $i;
}

sub start {
	my ($self) = @_;

	while ($self->prev) {
		$self = $self->prev;
	}

	return $self;
}

sub is_start {
	if ($_[0]->prev) {
		return 0;
	}
	return 1;
}

sub end {
	my ($self) = @_;

	while ($self->next) {
		$self = $self->next;
	}

	return $self;
}

sub is_end {
	if ($_[0]->next) {
		return 0;
	}
	return 1;
}

sub data { $_[0]->{data} = $_[1] if $_[1]; $_[0]->{data} }

sub next { $_[0]->{next} }

sub prev { $_[0]->{prev} }

sub bulk_add {
	my ($self, @items) = @_;
	$self = $self->end;
	for (@items) {
		$self = $self->insert_at_end($_);
	}
	return $self;
}

sub add {
	$_[0]->insert_at_end($_[1]);
}

sub insert {
	my ($self, $cb, $data) = @_;

	if (_is_undef($self)) {
		$self->{data} = $data;
		return $self;
	}

	$self  = $self->find($cb);

	return $self->insert_before($data);
}

sub insert_before {
	my ($self, $data) = @_;

	if (_is_undef($self)) {
		$self->{data} = $data;
		return $self;
	}

	my $node = $self->new($data);	

	$node->{next} = $self;

	if ($self->{prev}) {
		$node->{prev} = $self->{prev};
		$self->{prev}->{next} = $node;
	}

	$self->{prev} = $node;

	return $node;
}

sub insert_after {
	my ($self, $data) = @_;

	if (_is_undef($self)) {
		$self->{data} = $data;
		return $self;
	}

	my $node = $self->new($data);	

	$node->{prev} = $self;

	if ($self->{next}) {
		$node->{next} = $self->{next};
		$self->{next}->{prev} = $node;
	}

	$self->{next} = $node;

	return $node;
}

sub insert_at_start {
	my ($self, $data) = @_;

	if (_is_undef($self)) {
		$self->{data} = $data;
		return $self;
	}

	$self = $self->start();

	my $node = $self->new($data);

	$self->{prev} = $node;
	$node->{next} = $self;

	return $node;
}

sub insert_at_end {
	my ($self, $data) = @_;

	if (_is_undef($self)) {
		$self->{data} = $data;
		return $self;
	}

	$self = $self->end();

	my $node = $self->new($data);

	$self->{next} = $node;
	$node->{prev} = $self;

	return $node;
}

sub insert_at_pos {
	my ($self, $pos, $data) = @_;

	if (_is_undef($self)) {
		$self->{data} = $data;
		return $self;
	}

	$self = $self->start;

	for (my $i = 0; $i < $pos; $i++) {
		if ($self->{next}) {
			$self = $self->{next};
		}
	}

	return $self->insert_after($data);
}

sub remove {
	my ($self) = @_;

	if (_is_undef($self)) {
		return undef;
	}

	my $prev = $self->{prev};
	my $next = $self->{next};
	my $data = $self->{data};

	if ($prev) {
		if ($next) {
			$next->{prev} = $prev;
			$prev->{next} = $next;
			%{$self} = %{$next};
		} else {
			$prev->{next} = undef;
			%{$self} = %{$prev};
		}
	} elsif ($next) {
		$next->{prev} = undef;
		%{$self} = %{$next};
	} else {
		$self->{data} = undef;
	}

	return $data;
}

sub remove_from_start {
	my ($self) = @_;

	if (_is_undef($self)) {
		return undef;
	}

	$self = $self->start();

	return $self->remove();
}

sub remove_from_end {
	my ($self) = @_;

	if (_is_undef($self)) {
		return undef;
	}

	$self = $self->end();

	return $self->remove();
}

sub remove_from_pos {
	my ($self, $pos) = @_;

	if (_is_undef($self)) {
		return undef;
	}

	$self = $self->start();

	for (my $i = 0; $i < $pos; $i++) {
		if ($self->{next}) {
			$self = $self->{next};
		}
	}

	return $self->remove();
}

sub find {
	my ($self, $cb) = @_;

	$self = $self->start;

	if ( $cb->($self->data) ) {
		return $self;
	}
	
	while ($self->next) {
		$self = $self->next;

		if ( $cb->($self->data) ) {
			return $self;
		}
	}

	die "No match found for find cb";
}

sub destroy {
	my ($self) = @_;
	my $orig = $self;
	$self = $self->end;
	while ($self->prev) {
		my $next = $self->prev;
		$self->remove();
		$self = $next;
	}
	$self->remove();
	%{$orig} = %{$self};
	$orig;
}

sub _is_undef {
	my ($self) = shift;

	if ($self->{data} || $self->{prev} || $self->{next}) {
		return 0;
	}
	return 1;
}


1;

__END__

=head1 NAME

Doubly::Linked::PP - linked lists

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	use Doubly::Linked::PP;

	my $list = Doubly->new();

	$list->bulk_add(1..100000);

	$list->data; # 1;

	$list->length; # 100000;

	$list = $list->end;

	$list->data; # 100000;

	$list->prev->data; # 99999;

=head1 BENCHMARK

	use Benchmark qw(:all :hireswallclock);
	use lib '.';
	use Doubly::Linked::PP;
	use Doubly::Linked;
	use Doubly;
	my $r = timethese(2000000, {
		'Doubly::Linked::PP' => sub {
			my $linked = Doubly::Linked::PP->new(123);
			$linked->bulk_add(0..10);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
		},
		'Doubly::Linked' => sub {
			my $linked = Doubly::Linked->new(123);
			$linked->bulk_add(0..10);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
		},
		'Doubly' => sub {
			my $linked = Doubly->new(123);
			$linked->bulk_add(0..10);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
		}
	});

	cmpthese $r;

----

	Benchmark: timing 2000000 iterations of Doubly, Doubly::Linked, Doubly::Linked::PP...
	    Doubly: 1.70335 wallclock secs ( 1.62 usr +  0.08 sys =  1.70 CPU) @ 1176470.59/s (n=2000000)
	Doubly::Linked: 7.49174 wallclock secs ( 7.04 usr +  0.44 sys =  7.48 CPU) @ 267379.68/s (n=2000000)
	Doubly::Linked::PP: 26.0622 wallclock secs (25.32 usr +  0.56 sys = 25.88 CPU) @ 77279.75/s (n=2000000)
				Rate Doubly::Linked::PP  Doubly::Linked           Doubly
	Doubly::Linked::PP   77280/s                 --            -71%             -93%
	Doubly::Linked      267380/s               246%              --             -77%
	Doubly             1176471/s              1422%            340%               --

=head2 SEE ALSO

L<Doubly>

L<Doubly::Linked>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-doubly-linked-pp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Doubly-Linked-PP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Doubly::Linked::PP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Doubly-Linked-PP>

=item * Search CPAN

L<https://metacpan.org/release/Doubly-Linked-PP>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Doubly::Linked::PP
