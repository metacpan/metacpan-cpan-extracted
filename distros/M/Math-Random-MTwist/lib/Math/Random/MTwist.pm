package Math::Random::MTwist;

use 5.010_000;  # see README
use strict;
use warnings;

use Exporter;
use Time::HiRes;  # for timeseed()
use XSLoader;

use constant {
  MT_TIMESEED => \0,
  MT_FASTSEED => \0,
  MT_GOODSEED => \0,
  MT_BESTSEED => \0,
};

our $VERSION = '0.17';

our @ISA = 'Exporter';
our @EXPORT = qw(MT_TIMESEED MT_FASTSEED MT_GOODSEED MT_BESTSEED);
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
  'rand'  => [qw(srand rand rand32 rand64 irand irand32 irand64 randstr)],
  'seed'  => [qw(seed32 seedfull timeseed fastseed goodseed bestseed)],
  'state' => [qw(savestate loadstate getstate setstate)],
  'dist'  => [
    qw(
        rd_double
        rd_erlang rd_lerlang
        rd_exponential rd_lexponential
        rd_lognormal rd_llognormal
        rd_normal rd_lnormal
        rd_triangular rd_ltriangular
        rd_weibull rd_lweibull
    )
  ],
);

$EXPORT_TAGS{all} = [ map @$_, values %EXPORT_TAGS ];

XSLoader::load('Math::Random::MTwist', $VERSION);

# We want the function-oriented interface to provide the same function names as
# the OO interface. But since it doesn't have the state argument (aka $self),
# MTwist.xs provides counterparts with a leading underscore that we map to here.
sub import {
  my $this = shift;

  my @unhandled_args;

  if (@_) {
    my $caller = caller;
    my $need4seed = 0;
    my %exportable = map +($_ => 1), @{$EXPORT_TAGS{all}};

    while (defined(my $arg = shift)) {
      if ($arg =~ /^:(.+)/ && exists $EXPORT_TAGS{$1}) {
        push @_, @{$EXPORT_TAGS{$1}};
      }
      elsif ($exportable{$arg}) {
        no strict 'refs';
        $need4seed++;
        *{"$caller\::$arg"} = \&{"$this\::_$arg"};
      }
      else {
        push @unhandled_args, $arg;
      }
    }

    _fastseed() if $need4seed;
  }

  __PACKAGE__->export_to_level(1, $this, @unhandled_args);
}

sub new {
  my $class = shift;
  my $seed = shift;

  my $self = new_state($class);

  if (! defined $seed) {
    $self->fastseed();
  }
  elsif (! ref $seed) {
    $self->seed32($seed);
  }
  elsif (ref $seed eq 'ARRAY') {
    $self->seedfull($seed);
  }
  elsif ($seed == MT_TIMESEED) {
    $self->timeseed();
  }
  elsif ($seed == MT_FASTSEED) {
    $self->fastseed();
  }
  elsif ($seed == MT_GOODSEED) {
    $self->goodseed();
  }
  elsif ($seed == MT_BESTSEED) {
    $self->bestseed();
  }
  else { # WTF?
    $self->fastseed();
  }

  $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::Random::MTwist - A fast stateful Mersenne Twister pseudo-random number generator.

=head1 SYNOPSIS

  # object-oriented inteface
  use Math::Random::MTwist;

  my $mt = Math::Random::MTwist->new();  # seed from /dev/urandom
  my $int = $mt->irand();                # [0 .. 2^64-1 or 2^32-1]
  my $double = $mt->rand(73);            # [0 .. 73)
  $mt->goodseed();                       # seed from /dev/random
  $mt->savestate("/tmp/foobar");         # save current state to file
  $mt->loadstate("/tmp/foobar");         # load past state from file
  my @dist = map $mt->rd_triangular(1, 3, 2), 1 .. 1e3;  # triangular dist.

  # function-oriented interface (OO interface may be used in parallel)
  use Math::Random::MTwist qw(seed32 seedfull
                              timeseed fastseed goodseed bestseed);
  use Math::Random::MTwist qw(:seed) # gives you all of the above

  use Math::Random::MTwist qw(srand rand rand32 irand irand32 irand64);
  use Math::Random::MTwist qw(:rand); # gives you all of the above

  use Math::Random::MTwist qw(rd_exponential rd_triangular rd_normal ...);
  use Math::Random::MTwist qw(:dist); # gives you all of the above

  use Math::Random::MTwist qw(savestate loadstate getstate setstate);
  use Math::Random::MTwist qw(:state); # gives you all of the above

  use Math::Random::MTwist qw(:all); # import all functions

=head1 DESCRIPTION

Math::Random::MTwist is a Perl interface to Geoff Kuenning's mtwist C
library. It provides several seeding methods and various random number
distributions.

All functions are available through a function-oriented interface and an
object-oriented interface. The function-oriented interface maintains a single
global state while the OO interface gives you an individual state per instance.

The function-oriented interface provides drop-in replacements for Perl's
built-in C<rand()> and C<srand()> functions.

If you C<use> the module with an import list, the global state is seeded
automatically using C<fastseed()>. In this case, if you need the C<MT_>
constants, you must import them explicitly through the C<:DEFAULT> tag.

=head1 CONSTRUCTOR

=over 2

=item B<new()>, B<new($seed)>

Takes an optional argument specifying the seed. If you omit the seed,
C<MT_FASTSEED> is the default.

The seed can be a number (will be coerced to an unsigned 32-bit integer), an
array reference holding up to 624 such numbers (missing values are padded with
zeros, excess values are ignored) or one of the special values C<MT_TIMESEED>,
C<MT_FASTSEED>, C<MT_GOODSEED> or C<MT_BESTSEED> that choose one of the
corresponding seeding methods (see below).

Each instance maintains an individual PRNG state allowing multiple independent
random number streams.

=back

=head1 SEEDING

=over 2

=item B<seed32($number)>

Seeds the generator with C<$number>, coercing it to an unsigned 32-bit
integer. Calls mtwist's C<mts_seed32new()>. Returns the seed.

=item B<srand()>, B<srand($number)>

Calls C<seed32> if C<$number> is given, C<fastseed()> otherwise. Returns the
seed.

=item B<seedfull($seeds)>

Seeds the generator with up to 624 numbers from the I<array reference>
C<$seeds>. The values are coerced to unsigned 32-bit integers. Missing values
are taken as zero, excess values are ignored. Calls mtwist's
C<mts_seedfull()>. Returns nothing.

=item B<fastseed()>

Seeds the generator with 4 bytes read from C</dev/urandom> if available,
otherwise from the system time (see details under C<timeseed()>). Calls
mtwist's C<mts_seed()>. Returns the seed.

This method is called by C<new(MT_FASTSEED)>.

=item B<goodseed()>

Seeds the generator with 4 bytes read from C</dev/random> if available,
otherwise from the system time (see details under C<timeseed()>). Calls
mtwist's C<mts_goodseed()>. Returns the seed.

This method is called by C<new(MT_GOODSEED)>.

=item B<bestseed()>

Seeds the generator with 642 integers read from C</dev/random> if
available. This might take a very long time and is probably not worth the
waiting. If C</dev/random> is unavailable or there was a reading error it falls
back to C<goodseed()>. Calls mtwist's C<mts_bestseed()>.

This method is called by C<new(MT_BESTSEED)>.

=item B<timeseed()>

Seeds the generator from the current system time obtained from
C<Time::HiRes::gettimeofday()> by calculating C<seconds * 1e6 + microseconds>
and coercing the result to an unsigned 32-bit integer. Returns the seed.

This method is called by C<new(MT_TIMESEED)>.

C<timeseed> doesn't correspond to any of mtwist's functions. The rationale
behind it is that mtwist uses the system time if neither C</dev/urandom> nor
C</dev/random> is available. On Windows, the time source it uses has only
millisecond resolution in contrast to microseconds from C<gettimeofday()>, so
C<fast/good/bestseed()> and C<srand()> (w/o seed argument) call C<timeseed()>
directly in this case.

=back

=head1 STATE HANDLING

=over 2

=item B<savestate($filename or $filehandle)>

Saves the current state of the generator to a file given either by a filename
(file will be truncated) or an open Perl file handle.

Returns 1 on success, 0 on error (you might want to check C<$!>).

=item B<loadstate($filename or $filehandle)>

Loads the state of the generator from a file given either by a filename or an
open Perl file handle.

Returns 1 on success, 0 on error (you might want to check C<$!>).

=item B<getstate()>

Returns the current state of the generator as a binary string.

=item B<setstate($string)>

Sets the state of the generator from C<$string>, which you should have obtained
with C<getstate()>. croak()s if C<$string> is not a string of the correct size.

=back

C<savestate()> and C<loadstate()> are portable because they save the state as
decimal numbers. C<getstate()> and C<setstate()> are not portable because they
simply use a memory dump for laziness reasons.

However, depending on your system's architecture, you can convert C<getstate()>
to C<savestate()> format using something like C<join ' ', (reverse unpack
'L624i', getstate())[1..624,0];>.

=head1 UNIFORMLY DISTRIBUTED RANDOM NUMBERS

=over 2

=item B<irand()>

Returns a random unsigned integer, 64-bit if your system supports it (see
C<irand64()>), 32-bit otherwise.

=item B<irand32()>

Returns a random unsigned 32-bit integer. Calls mtwist's C<mts_lrand()>.

=item B<irand64()>

If your Perl is 64-bit, returns a 64-bit unsigned integer. If your Perl is
32-bit but your OS knows the C<uint64_t> type, returns a 64-bit unsigned
integer coerced to a double (so it's the full 64-bit range but with only 52-bit
precision). Otherwise it returns undef. Calls mtwist's C<mts_llrand()>.

=item B<rand()>, B<rand($bound)>

Returns a random double with 52-bit precision in the range C<[0, $bound)>.
Calls mtwist's C<mts_ldrand()>.

C<$bound> may be negative. If C<$bound> is omitted or zero it defaults to 1.

=item B<rand32()>, B<rand32($bound)>

Returns a random double with 32-bit precision in the range C<[0, $bound)>.
Slightly faster than rand(). Calls mtwist's C<mts_drand()>.

C<$bound> may be negative. If C<$bound> is omitted or zero it defaults to 1.

=item B<randstr()>, B<randstr($length)>

Returns a random binary string. The default length is 8 bytes. Returns undef if
there is not enough memory.

=back

=head1 NON-UNIFORMLY DISTRIBUTED RANDOM NUMBERS

With the exception of C<rd_double()> the following methods come in two
variants: C<B<rd_>xxx> and C<B<rd_l>xxx>. They all return a double but the
C<B<rd_>xxx> versions provide 32-bit precision while the C<B<rd_l>xxx> versions
provide 52-bit precision at the expense of speed.

=over 2

=item B<rd_double()>, B<rd_double($index)>

This is kind of a FUNction (that's the "Fun with flags" sort of fun).

It generates a random double in the complete (signed) double range. It does
that by drawing a random 64-bit integer (if available, otherwise two 32-bit
integers) and interpreting the bit pattern as a double. That's the same as
saying C<unpack 'd', pack 'Q', irand64()>. The results follow a Benford
distribution (each range [2^n, 2^(n+1)[ can hold 2^52 values). Be prepared to
meet some NaNs, Infs and subnormals (see POSIX::2008 for floating point check
functions).

In scalar context it returns a double. In list context it returns the double,
the corresponding integer (undef if your Perl doesn't have 64-bit integers) and
the packed string representation.

For convenience, you can call B<rd_double()> with an optional argument
B<$index> to get the same result as with B<(rd_double())[$index]>, just a bit
more efficiently.

=item B<rd_(l)exponential(double mean)>

Generates an exponential distribution with the given mean.

=item B<rd_(l)erlang(int k, double mean)>

Generates an Erlang-k distribution with the given mean.

=item B<rd_(l)weibull(double shape, double scale)>

Generates a Weibull distribution with the given shape and scale.

=item B<rd_(l)normal(double mean, double sigma)>

Generates a normal (Gaussian) distribution with the given mean and standard
deviation sigma.

=item B<rd_(l)lognormal(double shape, double scale)>

Generates a log-normal distribution with the given shape and scale.

=item B<rd_(l)triangular(double lower, double upper, double mode)>

Generates a triangular distribution in the range C<[lower, upper)> with the
given mode.

=back

=head1 EXPORTS

By default the module exports the constants MT_TIMESEED, MT_FASTSEED,
MT_GOODSEED and MT_BESTSEED that can be used as an argument to the constructor.

The following export tags are available:

=over 2

=item B<:dist>

rd_double rd_erlang rd_lerlang rd_exponential rd_lexponential rd_lognormal
rd_llognormal rd_normal rd_lnormal rd_triangular rd_ltriangular rd_weibull
rd_lweibull

=item B<:rand>

rand rand rand32 rand64 irand irand32 irand64

=item B<:seed>

seed32 seedfull timeseed fastseed goodseed bestseed

=item B<:state>

savestate loadstate getstate setstate

=item B<:all>

All of the above.

=item B<:DEFAULT>

MT_TIMESEED MT_FASTSEED MT_GOODSEED MT_BESTSEED

=back

=head1 NOTES

This module is not C<fork()/clone()> aware, i.e. you have to take care of
re-seeding/re-instantiating in new processes/threads yourself.

Imported functions and OO methods have the same names. This works by symbol
table "redirection", e.g. non-OO irand() is actually _irand() internally and so
on (note the underscore). The minor drawback is that you can't use fully
qualified names like C<Math::Random::MTwist::irand()> etc. Instead you have to
say C<Math::Random::MTwist::_irand()>. I considered avoiding this by checking
if the first argument is a blessed reference but I discarded that in favor of
speed.

=head1 SEE ALSO

L<http://www.cs.hmc.edu/~geoff/mtwist.html>

L<Math::Random::MT|https://metacpan.org/pod/Math::Random::MT> and
L<Math::Random::MT::Auto|https://metacpan.org/pod/Math::Random::MT::Auto> are
significantly slower than Math::Random::MTwist. MRMA has some additional
sophisticated features but it depends on non-core modules.

=head1 AUTHOR

Carsten Gaebler (cgpan ʇɐ gmx ʇop de). I only accept encrypted e-mails, either
via L<SMIME|https://cpan.metacpan.org/authors/id/C/CG/CGPAN/cgpan-smime.crt> or
L<GPG|https://cpan.metacpan.org/authors/id/C/CG/CGPAN/cgpan-gpg.asc>.

=head1 COPYRIGHT

Perl and XS portion: Copyright © 2014 by Carsten Gaebler.

mtwist C library: Copyright © 2001, 2002, 2010, 2012, 2013 by Geoff Kuenning.

=head1 LICENSE

Perl and XS portion: L<WTFPL|http://wtfpl.net/>.

mtwist C library: L<LGPL|https://gnu.org/licenses/lgpl.html>

=cut
