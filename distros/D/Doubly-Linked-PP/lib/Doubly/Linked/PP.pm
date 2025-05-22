package Doubly::Linked::PP;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.04';

sub new {
	my $class = shift;
	bless {
		data => [@_ ? $_[0] : ()],
		idx  => 0,
	}, $class
}

sub _clone_at {
	my $self = shift;
	my ($idx) = @_;
	bless {
		%$self,
		idx => $idx,
	}, ref($self)
}

sub length {
	my $self = shift;
	scalar @{$self->{data}}
}

sub data {
	my $self = shift;
	if (@_) {
		$self->{data}[$self->{idx}] = $_[0];
	}
	$self->{data}[$self->{idx}]
}

sub start {
	my $self = shift;
	$self->_clone_at(0)
}

sub is_start {
	my $self = shift;
	$self->{idx} == 0
}

sub end {
	my $self = shift;
	$self->_clone_at($#{$self->{data}})
}

sub is_end {
	my $self = shift;
	$self->{idx} == $#{$self->{data}}
}

sub next {
	my $self = shift;
	$self->is_end
		? undef
		: $self->_clone_at($self->{idx} + 1)
}

sub prev {
	my $self = shift;
	$self->is_start
		? undef
		: $self->_clone_at($self->{idx} - 1)
}

sub bulk_add {
	my $self = shift;
	push @{$self->{data}}, @_;
}

sub add {
	my $self = shift;
	my ($item) = @_;
	$self->bulk_add($item);
	$self->end
}

sub insert {
	my $self = shift;
	my ($cb, $item) = @_;
	my $i = 0;
	for (; $i < @{$self->{data}}; $i++) {
		last if $cb->($self->{data}[$i]);
	}
	splice @{$self->{data}}, $i, 0, $item;
	$self->_clone_at($i)
}

sub insert_before {
	my $self = shift;
	my ($item) = @_;
	splice @{$self->{data}}, $self->{idx}, 0, $item;
	$self
}

sub insert_after {
	my $self = shift;
	my ($item) = @_;
	return $self->insert_at_end($item) unless $self->{idx} || scalar @{$self->{data}};
	my $pos = $self->{idx} + 1;
	splice @{$self->{data}}, $pos, 0, $item;
	$self->_clone_at($pos)
}

sub insert_at_start {
	my $self = shift;
	my ($item) = @_;
	$self->{idx}++;
	unshift @{$self->{data}}, $item;
	$self->start
}

sub insert_at_end {
	my $self = shift;
	my ($item) = @_;
	push @{$self->{data}}, $item;
	$self->end
}

sub insert_at_pos {
	my $self = shift;
	my ($pos, $item) = @_;
	$self->{idx}++ if $self->{idx} >= $pos;
	splice @{$self->{data}}, $pos, 0, $item;
	$self->_clone_at($pos)
}

sub remove {
	my $self = shift;
	splice @{$self->{data}}, $self->{idx}, 1;
}

sub remove_from_start {
	my $self = shift;
	$self->{idx}-- if $self->{idx} > 0;
	shift @{$self->{data}};
}

sub remove_from_end {
	my $self = shift;
	pop @{$self->{data}};
}

sub remove_from_pos {
	my $self = shift;
	my ($pos) = @_;
	$self->{idx}-- if $self->{idx} >= $pos;
	splice @{$self->{data}}, $pos, 1;
}

sub find {
	my $self = shift;
	my ($cb) = @_;
	my $i = 0;
	for (; $i < @{$self->{data}}; $i++) {
		last if $cb->($self->{data}[$i]);
	}
	$self->_clone_at($i)
}

sub destroy {
	my $self = shift;
	@{$self->{data}} = ();
	$self->{idx} = 0;
}

1;

__END__

=head1 NAME

Doubly::Linked::PP - linked lists

=head1 VERSION

Version 0.04

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
	use Doubly;

	my $r = timethese(100000, {
		'Doubly::Linked::PP' => sub {
			my $linked = Doubly::Linked::PP->new(123);
			$linked->bulk_add(0..1000);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
		},
		'Doubly' => sub {
			my $linked = Doubly->new(123);
			$linked->bulk_add(0..1000);
			$linked = $linked->end;
			$linked->is_end;
			$linked = $linked->start;
			$linked->is_start;
			$linked->add(789);
		}
	});

	cmpthese $r;

...

	Benchmark: timing 100000 iterations of Doubly, Doubly::Linked::PP...
	    Doubly: 2.87622 wallclock secs ( 2.58 usr +  0.30 sys =  2.88 CPU) @ 34722.22/s (n=100000)
	Doubly::Linked::PP: 2.21881 wallclock secs ( 2.22 usr +  0.00 sys =  2.22 CPU) @ 45045.05/s (n=100000)
			      Rate             Doubly Doubly::Linked::PP
	Doubly             34722/s                 --               -23%
	Doubly::Linked::PP 45045/s                30%                 --

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
