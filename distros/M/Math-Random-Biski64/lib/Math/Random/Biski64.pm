package Math::Random::Biski64;

use strict;
use warnings;
use v5.12;
no warnings 'portable';

our $VERSION = 'v0.2.0';

use Carp qw(croak);
use constant MASK64 => 0xFFFFFFFFFFFFFFFF;
my $URANDOM_FH = undef;

sub _rotl64 {
	my ($x, $k) = @_;
	(($x << $k) | ($x >> (64 - $k))) & MASK64;
}

sub _add64 {
	my ($a, $b) = @_;
	my $lo = ($a & 0xFFFFFFFF) + ($b & 0xFFFFFFFF);
	my $hi = (($a >> 32) & 0xFFFFFFFF) + (($b >> 32) & 0xFFFFFFFF) + ($lo >> 32);
	(($hi & 0xFFFFFFFF) << 32) | ($lo & 0xFFFFFFFF);
}

sub _mul64 {
	my ($a, $b) = @_;
	my @al = map { ($a >> $_) & 0xFFFF } (0, 16, 32, 48);
	my @bl = map { ($b >> $_) & 0xFFFF } (0, 16, 32, 48);
	my @p;
	for my $i (0 .. 3) {
		for my $j (0 .. 3) {
			next if $i + $j >= 4;
			$p[$i + $j] += $al[$i] * $bl[$j];
		}
	}
	for my $i (0 .. 2) {
		my $c = $p[$i] >> 16;
		$p[$i] &= 0xFFFF;
		$p[$i + 1] += $c;
	}
	$p[0] | ($p[1] << 16) | ($p[2] << 32) | ($p[3] << 48);
}

sub new {
	my ($class, $seed) = @_;
	my $self = bless {}, ref($class) || $class;
	if (defined $seed) {
		$self->seed($seed);
	} else {
		$self->seed(os_random_u64());
	}
	$self;
}

sub os_random_u64 {
	my $bytes = os_random_bytes(8);
	return unpack('Q<', $bytes);
}

################################################################################

#my $seed = [10293820198];
#my $num  = splitmix_64_perl_single($seed);
sub splitmix64_perl {
	# Seed must be passed as a array reference so we can update it
	my $seed = $_[0];

	use integer;
	# We bitwise or with zero to convert a signed int (IV) to an unsigned int (UV)
	# This is a weird hack that mauke taught me. It works so *shrug*
	my $z       = ($seed->[0] += 11400714819323198485) | 0;
	$seed->[0] |= 0;
	no integer;

	$z = ($z ^ ($z >> 30));
	use integer;
	$z = ($z * 13787848793156543929) | 0;
	no integer;

	$z = ($z ^ ($z >> 27));
	use integer;
	$z = ($z * 10723151780598845931) | 0;
	no integer;

	$z = ($z ^ ($z >> 31));

	return $z;
}

################################################################################

sub seed {
	my ($self, $seed) = @_;
	my $sm = [$seed];
	my ($s0, $s1, $s2);
	do {
		$s0 = splitmix64_perl($sm);
		$s1 = splitmix64_perl($sm);
		$s2 = splitmix64_perl($sm);
	} while ($s0 == 0 && $s1 == 0 && $s2 == 0);
	@{$self}{qw(fast_loop mix loop_mix)} = ($s0, $s1, $s2);
	$self->_warmup;
	$self;
}

sub next_u64 {
	my ($self) = @_;
	use integer;
	my $output = $self->{mix} + $self->{loop_mix};
	my $old_lm = $self->{loop_mix};
	no integer;

	$self->{loop_mix} = $self->{fast_loop} ^ $self->{mix};

	use integer;
	$self->{mix} = _rotl64($self->{mix}, 16) + _rotl64($old_lm, 40);
	$self->{fast_loop} += 11068046444225730969;
	no integer;

	return $output | 0;
}

sub next_u32 {
	my ($self) = @_;
	$self->next_u64 >> 32;
}

sub next_double {
	my ($self) = @_;
	($self->next_u64 >> 11) / 9007199254740992.0;
}

sub rand_integer {
	my ($self, $min, $max) = @_;
	my $range = $max - $min + 1;
	return $min if $range <= 1;
	my $limit = MASK64 - (MASK64 % $range + 1) % $range;
	my $val;
	do { $val = $self->next_u64 } while $val > $limit;
	return $min + ($val % $range);
}

sub shuffle_array {
	my $self = shift;
	my @copy = @_;
	for my $i (reverse 1 .. $#copy) {
		my $j = $self->rand_integer(0, $i);
		@copy[$i, $j] = @copy[$j, $i];
	}
	return @copy;
}

sub random_elem {
	my $self = shift;

	if (!@_) {
		return undef;
	}

	my $size = scalar(@_) - 1;
	my $id   = $self->rand_integer(0, $size);
	my $ret  = $_[$id];

	return $ret;
}

sub _warmup {
	my ($self) = @_;
	$self->next_u64 for 1 .. 16;
}

sub for_stream {
	my ($class, $seed, $stream_index, $total_streams) = @_;
	my $sm = [$seed];
	my ($s0, $s1, $s2);
	do {
		$s0 = splitmix64_perl($sm);
		$s1 = splitmix64_perl($sm);
		$s2 = splitmix64_perl($sm);
	} while ($s0 == 0 && $s1 == 0 && $s2 == 0);
	my $fast_loop;
	if ($total_streams > 1) {
		my $cycles_per_stream = int(MASK64 / $total_streams);
		my $step = _mul64($stream_index & MASK64, $cycles_per_stream);
		$fast_loop = _add64($s0, _mul64($step, 0x9999999999999999));
	} else {
		$fast_loop = $s0;
	}
	my $self = bless { fast_loop => $fast_loop, mix => $s1, loop_mix => $s2 }, ref($class) || $class;
	$self->_warmup;
	$self;
}

# Fetch random bytes from the OS supplied method
# /dev/urandom = Linux, Unix, FreeBSD, Mac, Android
# Windows requires the Win32::API call to call RtlGenRandom()
sub os_random_bytes {
	my $count  = shift();
	my $ret    = "";

	if ($count <= 0) {
		croak("$count is not a valid amount of bytes");
	}

	if ($^O eq 'MSWin32') {
		require Win32::API;

		state $rand = Win32::API->new(
			'advapi32',
			'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)'
		) or croak("Could not import SystemFunction036: $^E");

		$ret = chr(0) x $count;
		$rand->Call($ret, $count) or croak("Could not read from csprng: $^E");
	} elsif (-r "/dev/urandom") {
		if (!$URANDOM_FH) {
			open($URANDOM_FH, '<:raw', '/dev/urandom') or croak("Couldn't open /dev/urandom: $!");
		}

		sysread($URANDOM_FH, $ret, $count) or croak("Couldn't read from csprng: $!");
	} else {
		croak("Unknown operating system $^O");
	};

	if (length($ret) != $count) {
		croak("Unable to read $count bytes from OS");
	}

	return $ret;
}

1;

__END__

=head1 NAME

Math::Random::Biski64 - Fast 64-bit PRNG with guaranteed minimum 2^64 period

=head1 SYNOPSIS

  use Math::Random::Biski64;

  # Local copy of the random number generator to play with
  my $rng = Math::Random::Biski64->new();
  my $num = $rng->next_u64();

  # Or create one with a specific 64bit seed
  my $rng2 = Math::Random::Biski64->new(12345);
  my $num  = $rng2->next_u64();

=head1 DESCRIPTION

This module implements the Biski64 algorithm, a fast and robust non-cryptographic
64-bit pseudo-random number generator. It uses a 64-bit Weyl sequence to guarantee
a minimum period of 2^64, and is designed for applications where speed and
statistical quality are important.

On module load, a default generator is automatically seeded from the OS
random source (C</dev/urandom> on Unix, C<RtlGenRandom> on Windows).

=head1 METHODS

=head2 new($seed?)

Create a new generator. If C<$seed> is provided, the generator is seeded via
C<seed>. Otherwise, the generator is seeded from the OS random source.

=head2 seed($seed)

Initialize the generator from a 64-bit seed using SplitMix64 to expand the
seed into the full internal state, followed by a 16-iteration warm-up.

=head2 next_u64()

Returns the next 64-bit random integer.

=head2 next_u32()

Returns the next 32-bit random integer (upper 32 bits of the next_u64 output).

=head2 next_double()

Returns a random double in [0, 1).

=head2 rand_integer($min, $max)

Returns an unbiased random integer in the inclusive range C<$min> to
C<$max>. Uses rejection sampling to eliminate modulo bias: if the raw
64-bit value exceeds the largest multiple of the range that fits in 2^64,
it is rejected and a new value is drawn.

Returns C<$min> unchanged if C<$min> E<gt>= C<$max>.

=head2 shuffle_array(@array)

Returns a new array containing the same elements as C<@array> but randomly
shuffled using the Fisher-Yates algorithm. The original array is not modified.

  my @cards  = 1..52;
  my @shuffled = $rng->shuffle_array(@cards);

=head2 random_elem(@array)

Returns a randomly selected element from C<@array>, chosen with an
unbiased uniform distribution. Returns undef if C<@array> is empty.

  my @colors = qw(red green blue);
  my $color  = $rng->random_elem(@colors);

=head1 ALGORITHM

The Biski64 state consists of three 64-bit integers: C<fast_loop>, C<mix>,
and C<loop_mix>. On each call:

  output     = mix + loop_mix
  loop_mix   = fast_loop ^ mix
  mix        = rotl(mix, 16) + rotl(loop_mix, 40)
  fast_loop += 0x9999999999999999

=head1 SEE ALSO

L<https://github.com/danielcota/biski64>

=head1 LICENSE

MIT

=cut
