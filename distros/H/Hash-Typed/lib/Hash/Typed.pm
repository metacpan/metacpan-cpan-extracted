package Hash::Typed;
use strict; use warnings; our $VERSION = '0.05';
use Carp qw/croak/; use Tie::Hash; our (@ISA);

BEGIN { 
	@ISA = qw(Tie::Hash);
}

sub new {
	my ($package) = (shift);

	my $self = { };
	
	tie %{$self}, 'Hash::Typed', @_;

	bless $self, $package;
}

sub TIEHASH {
	my ($pkg) = shift;
	my($self) = [];
	push @{$self}, {}, [], [], 0;
	$self = bless $self, $pkg;
	if (ref $_[0]) {
		my $spec = $self->PARSE(shift);
		push @{$self}, $spec;
	}
	while (@_) {
		$self->STORE(shift, shift);
	}
	if ($self->[4] && $self->[4]->{required}) {
		if (ref $self->[4]->{required}) {
			$self->REQUIRED($self->[4]->{required});
		} else {
			$self->REQUIRED([keys %{$self->[4]->{ordered_keys}}]);
		}
	}
	return $self;
}

sub FETCH {
	my($self, $key) = (shift, shift);
	return exists( $self->[0]{$key} ) ? $self->[2][ $self->[0]{$key} ] : undef;
}

sub STORE {
	my ($self, $key, $value) = @_;

	if ($self->[4]) {
		my $described = $self->[4]->{keys}->{$key};

		if ($self->[4]->{strict} && !$described) {
			croak "Strict mode enabled and passed key \"${key}\" does not exist in the specification.";
		}

		$value = $described->($value)
			if ($described);
	}

	if (exists $self->[0]{$key}) {
		my($i) = $self->[0]{$key};
		$self->[1][$i] = $key;
		$self->[2][$i] = $value;
		$self->[0]{$key} = $i;
	} elsif ($self->[4] && defined $self->[4]{ordered_keys}{$key} && $self->[4]{ordered_keys}{$key} <= scalar @{$self->[1]}) {
		my $i = $self->[4]{ordered_keys}{$key};
		my $before = $self->[1]->[$i - 1];
		$i = $i == 0 ? $i : --$i if ($before && ($self->[4]{ordered_keys}{$before} || -1) >= $i);
		splice(@{$self->[1]}, $i, 0, $key);
		splice(@{$self->[2]}, $i, 0, $value);
		$self->[0]{$key} = $i;
		$self->[0]{ $self->[1][$_] }++
			for ($i+1..$#{$self->[1]});
	} else {
		push(@{$self->[1]}, $key);
		push(@{$self->[2]}, $value);
		$self->[0]{$key} = $#{$self->[1]};
	}
}

sub DELETE {
	my ($self, $key) = @_;

	if (exists $self->[0]{$key}) {
		my($i) = $self->[0]{$key};
		$self->[0]{ $self->[1][$_] }--
			for ($i+1..$#{$self->[1]});
		$self->[3]--  if ( $i == $self->[3]-1 );
		delete $self->[0]{$key};
		splice @{$self->[1]}, $i, 1;
		return (splice(@{$self->[2]}, $i, 1))[0];
	}
	return undef;
}

sub CLEAR {
	my ($self) = @_;
	push @{$self}, {}, [], [], 0;
}

sub EXISTS { exists $_[0]->[0]{ $_[1] }; }

sub FIRSTKEY {
	$_[0][3] = 0;
  	&NEXTKEY;
}

sub NEXTKEY {
	return $_[0][1][ $_[0][3]++ ] if ($_[0][3] <= $#{ $_[0][1] } );
  	return undef;
}

sub SCALAR { scalar(@{$_[0]->[1]}); }

sub PARSE {
	my ($self, $spec) = @_;
	my (%keys, %described);
	tie(%described, 'Hash::Typed');
	while (@{$spec}) {
		my ($key, $value) = (shift @{$spec}, shift @{$spec});
		if ($key eq 'keys') {
			if (ref $value eq 'ARRAY') {
				($value) = $self->PARSE($value);
				my $i = 0;
				%keys = map { $_ => $i++ } keys %{$value}; 
			} else {
				croak "keys spec must currently be an ARRAY";
			}
		}
		$described{$key} = $value;
	}
	$described{ordered_keys} = \%keys if scalar keys %keys;
	return \%described;
}

sub REQUIRED {
	my ($self, $keys) = @_;
	for my $key (@{$keys}) {
		if (! defined $self->[0]{$key}) {
			croak "Required key $key not set.";
		}
	}
}

1;

__END__;

=head1 NAME

Hash::Typed - Ordered typed tied hashes.

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	use Hash::Types;

	use Types::Standard qw/Int Str ArrayRef/;

	my $test = Hash::Typed->new(
		[
			strict => 1,
			required => 1, # all keys are required on instantiation
			keys => [
				one => Int,
				two => Str,
				three => ArrayRef,
				four => sub { return 1 },
				five => sub { 
					Hash::Typed->new(
						[ strict => 1, required => [qw/one/], keys => [ one => Int ] ],
						%{$_[0]}
					);
				}
			]
		],
		(
			three => [qw/a b c/],
			two => 'def',
			one => 211,
			four => undef,
			five => { one => 633 }
		)
	);

	$test->{one} = "not okay";  # errors as does not pass Int type constraint.

	...

	tie my %test, 'Hash::Typed',
		[
			strict => 1,
			required => [qw/one two three four/],
			keys => [
				one => Int,
				two => Str,
				three => ArrayRef,
				four => sub { return 1 },
				five => sub { Hash::Typed->new(@{$_[0]}); }
			]
		],
		(
			three => [qw/a b c/],
			two => 'def',
			one => 211,
			four => undef,
			five => [ [keys => [ one => Int ]], one => 633 ]
		);

...

	{
		one => 211, 
		two => 'def', 
		three => [qw/a b c/], 
		four => 1, 
		five => { 
			one => 633 
		}
	}

=head1 SUBROUTINES/METHODS

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-typed at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Typed>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Hash::Typed

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Typed>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hash-Typed>

=item * Search CPAN

L<https://metacpan.org/release/Hash-Typed>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Hash::Typed
