package Math::Random::Xoshiro256;
use strict;
use warnings;
use v5.10;
use Carp qw(croak);

# https://pause.perl.org/pause/query?ACTION=pause_operating_model#3_5_factors_considering_in_the_indexing_phase
our $VERSION = '0.1.2';

require XSLoader;
XSLoader::load('Math::Random::Xoshiro256', $VERSION);

sub new {
	my ($class, $opts) = @_;
	my $self = Math::Random::Xoshiro256::_xs_new($class);

	# Check if the user passed any seeds into the constructor
	if (exists $opts->{seed}) {
		my $seed = $opts->{seed};
		$self->seed($seed);
	} elsif (exists $opts->{seed4}) {
		my @seeds = @$opts->{seeds};
		$self->seed4(@seeds);
	} else {
		$self->auto_seed;
	}

	return $self;
}

sub auto_seed {
	my ($self) = @_;

	# Get 32 bytes worth of random bytes and build 4x uint64_t seeds from them
	my $bytes = os_random_bytes(4 * 8);
	my @seeds = unpack('Q4', $bytes);

	$self->seed4(@seeds);
}

# Fetch random bytes from the OS supplied method
# /dev/urandom = Linux, Unix, FreeBSD, Mac, Android
# Windows requires the Win32::API call to call RtlGenRandom()
sub os_random_bytes {
	my $count  = shift();
	my $ret    = "";

	if ($^O eq 'MSWin32') {
		require Win32::API;

		state $rand = Win32::API->new(
			'advapi32',
			'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)'
		) or croak("Could not import SystemFunction036: $^E");

		$ret = chr(0) x $count;
		$rand->Call($ret, $count) or croak("Could not read from csprng: $^E");
	} elsif (-r "/dev/urandom") {
		open my $urandom, '<:raw', '/dev/urandom' or croak("Couldn't open /dev/urandom: $!");

		sysread($urandom, $ret, $count) or croak("Couldn't read from csprng: $!");
	} else {
		croak("Unknown operating system $^O");
	};

	if (length($ret) != $count) {
		croak("Unable to read $count bytes from OS");
	}

	return $ret;
}

sub shuffle_array {
    my ($self, @array) = @_;

	# Make a copy of the array to shuffle
    my @shuffled = @array;
    my $n        = scalar(@shuffled);

	# Shuffle the array using the Fisher-Yates algorithm
	for (my $i = $n - 1; $i > 0; $i--) {
        my $j = $self->random_int(0, $i);
        @shuffled[$i, $j] = @shuffled[$j, $i] if $i != $j;
    }

	return @shuffled;
}

sub random_elem {
    my ($self, @array) = @_;

	if (!@array) {
		return undef;
	}

    my $idx = $self->random_int(0, scalar(@array) - 1);
	my $ret = $array[$idx];

    return $ret;
}

sub random_bytes {
    my ($self, $num) = @_;

	if (!defined($num) || $num <= 0) {
		croak("random_bytes: positive number required");
	}

	# Get random bytes until we have the desired number
    my $bytes = '';
    while (length($bytes) < $num) {
        my $rand64 = $self->rand64;
        $bytes .= pack('Q<', $rand64); # little endian for each 64-bit chunk
    }

    return substr($bytes, 0, $num);
}

sub random_float {
    my ($self, $non_inclusive) = @_;

	# Get a random 64-bit integer and convert it to a float in [0,1]
    my $u64   = $self->rand64;
	my $top53 = $u64 >> 11;

    my $ret;
	if ($non_inclusive) {
		$ret = $top53 / ((2**53) - 1);
	} else {
		$ret = $top53 / (2**53);
	}

	return $ret;
}

1;
__END__

=head1 NAME

Math::Random::Xoshiro256 - XS wrapper for xoshiro256** PRNG

=head1 SYNOPSIS

  use Math::Random::Xoshiro256;
  my $rng = Math::Random::Xoshiro256->new();

  my $rand   = $rng->rand64();
  my $int    = $rng->random_int(10, 20);   # non-biased integer in [10, 20]
  my $bytes  = $rng->random_bytes(16);     # 16 random bytes from PRNG
  my $float  = $rng->random_float();       # float in [0, 1] inclusive

  my @arr       = ('red', 'green', 'blue', 'yellow', 'purple');
  my $rand_item = $rng->random_elem(@arr);
  my @mixed     = $rng->shuffle_array(@arr);

  $rng->seed($seed)   # Single 64bit seed
  $rng->seed4(@seeds) # 4x 64bit seeds

=head1 DESCRIPTION

Implement the Xoshiro256** PRNG and expose so user friendly random methods.

This module is automatically seeded with entropy directly from your OS.
On Linux this is C</dev/urandom> and on Windows it uses C<RtlGenRandom>.

Alternately you can manually seed this if you need repeatable random
numbers.

=head1 METHODS

=over

=item B<rand64()>

Return an unsigned 64-bit random integer.

=item B<random_int($min, $max)>

Return a random integer (non-biased) in [$min, $max] inclusive.

=item B<random_bytes($num)>

Returns $num random bytes.

=item B<random_float()>

Returns a float in the interval [0, 1] inclusive.

=item B<random_elem(@array)>

Returns a single random element from the given array (returns undef if array is empty).

=item B<shuffle_array(@array)>

Returns a shuffled list using the Fisher-Yates algorithm with the PRNG instance. Input array is not modified.

=back

=head1 SEE ALSO

=over

=item *
L<Random::Simple>

=item *
L<Math::Random::PCG32>

=item *
L<Math::Random::ISAAC>

=item *
L<Math::Random::MT>

=back

=cut
