package Math::SimpleHisto::XS;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '1.30'; # Committed to floating point version numbers!

require XSLoader;
XSLoader::load('Math::SimpleHisto::XS', $VERSION);

require Math::SimpleHisto::XS::RNG;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
  INTEGRAL_CONSTANT
);
  #INTEGRAL_POL1

our %EXPORT_TAGS = (
  'all' => \@EXPORT_OK,
);

our @JSON_Modules = qw(JSON::XS JSON::PP JSON);
our $JSON_Implementation;
our $JSON;

foreach my $json_module (@JSON_Modules) {
  if (eval "require $json_module; 1;") {
    $JSON = $json_module->new;
    $JSON->indent(0) if $JSON->can('indent');
    $JSON->space_before(0) if $JSON->can('space_before');
    $JSON->space_after(0) if $JSON->can('space_after');
    $JSON->canonical(0) if $JSON->can('canonical');
    $JSON_Implementation = $json_module;
    last if $JSON;
  }
}

sub new {
  my $class = shift;
  my %opt = @_;

  if (defined $opt{bins}) {
    my $bins = $opt{bins};
    croak("Cannot combine the 'bins' parameter with other parameters") if keys %opt > 1;
    croak("The 'bins' parameter needs to be a reference to an array of bins")
      if not ref($bins)
      or not ref($bins) eq 'ARRAY'
      or not @$bins > 1;
    return $class->_new_histo_bins($bins);
  }
  else {
    foreach (qw(min max nbins)) {
      croak("Need parameter '$_'") if not defined $opt{$_};
    }
  }

  return $class->_new_histo(@opt{qw(nbins min max)});
}

# See ExtUtils::Constant
sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.

  my $constname;
  our $AUTOLOAD;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  croak('&' . __PACKAGE__ . "::constant not defined") if $constname eq 'constant';
  my ($error, $val) = constant($constname);
  if ($error) { croak($error); }
  {
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
  }
  goto &$AUTOLOAD;
}


use constant _PACK_FLAG_VARIABLE_BINS => 0;

my $native_pack_len;
SCOPE: {
  require bytes;
  my $intlen = bytes::length(pack('I', 0));
  $native_pack_len = 8 + 4 + 16 + 4 + $intlen*2 + 16;
}

sub dump {
  my $self = shift;
  my $type = shift;
  $type = lc($type);

  my ($min, $max, $nbins, $nfills, $overflow, $underflow, $data_ary, $bins_ary)
    = $self->_get_info;

  if ($type eq 'simple') {
    return join(
      ';',
      $VERSION,
      $min, $max, $nbins,
      $nfills, $overflow, $underflow,
      join('|', @$data_ary),
      (defined($bins_ary) ? join('|', @$bins_ary) : ''),
    );
  }
  elsif ($type eq 'json' or $type eq 'yaml') {
    my $struct = {
      version => $VERSION,
      min => $min, max => $max, nbins => $nbins,
      nfills => $nfills, overflow => $overflow, underflow => $underflow,
      data => $data_ary,
    };
    $struct->{bins} = $bins_ary if defined $bins_ary;

    if ($type eq 'json') {
      if (not defined $JSON) {
        die "Cannot use JSON dump mode since no JSON handling module could be loaded: "
            . join(', ', @JSON_Modules);
      }
      return $JSON->encode($struct);
    }
    else { # type eq yaml
      require YAML::Tiny;
      return YAML::Tiny::Dump($struct);
    }
  }
  elsif ($type eq 'native_pack') {
    my $flags = 0;
    vec($flags, _PACK_FLAG_VARIABLE_BINS, 1) = $bins_ary ? 1 : 0;

    my $len = $native_pack_len + 8 * (scalar(@$data_ary) + scalar(@{$bins_ary || []}));
    return pack(
      'd V d2 V I2 d2 d*',
      $VERSION,
      $len,
      $min, $max,
      $flags,
      $nbins,
      $nfills, $overflow, $underflow,
      @$data_ary,
      @{$bins_ary || []}
    );
  }
  else {
    croak("Unknown dump type: '$type'");
  }
  die "Must not be reached";
}


sub _check_version {
  my $version = shift;
  my $type = shift;
  if (not $version) {
    croak("Invalid '$type' dump format");
  }
  elsif ($VERSION-$version < -1.) {
    croak("Dump was generated with an incompatible newer version ($version) of this module ($VERSION)");
  }
}

sub new_from_dump {
  my $class = shift;
  my $type = shift;
  my $dump = shift;
  $type = lc($type);

  croak("Need dump string") if not defined $dump;

  my $version;
  my $hashref;
  if ($type eq 'simple') {
    ($version, my @rest) = split /;/, $dump, -1;
    my $nexpected = 9;

    _check_version($version, 'simple');
    if ($version <= 1.) { # no bins array in VERSION < 1
      $nexpected--;
    }
    elsif (@rest != $nexpected-1) {
      croak("Invalid 'simple' dump format, wrong number of elements in top level structure");
    }

    $hashref = {
      min => $rest[0], max => $rest[1], nbins => $rest[2],
      nfills => $rest[3], overflow => $rest[4], underflow => $rest[5],
      data => [split /\|/, $rest[6]]
    };
    if ($version >= 1. and $rest[7] ne '') {
      $hashref->{bins} = [split /\|/, $rest[7]];
    }
  }
  elsif ($type eq 'json') {
    if (not defined $JSON) {
      die "Cannot use JSON dump mode since no JSON handling module could be loaded: "
          . join(', ', @JSON_Modules);
    }
    $hashref = $JSON->decode($dump);
    $version = $hashref->{version};
    _check_version($version, 'json');
    croak("Invalid JSON dump, not a hashref") if not ref($hashref) eq 'HASH';
  }
  elsif ($type eq 'yaml') {
    require YAML::Tiny;
    my @docs = YAML::Tiny::Load($dump);
    if (@docs != 1 or not ref($docs[0]) eq 'HASH') {
      croak("Invalid YAML dump, not a single YAML document or not containing a hashref");
    }
    $hashref = $docs[0];
    $version = $hashref->{version};
    _check_version($version, 'yaml');
  }
  elsif ($type eq 'native_pack') {
    my $version = unpack('d', $dump);
    _check_version($version, 'native_pack');
    my $flags_support = $version >= 1.;
    my $prepended_length = $version >= 1.28;
    my $ndoubles;

    # We go through all this pain about the length and the number of elements in the packed
    # dump because that'll allow us to prevent reading beyond the end of a given dump.
    if ($prepended_length) {
      (undef, my $len) = unpack('d V', $dump);
      $len -= $native_pack_len;
      $ndoubles = $len / 8;
    }
    my $pack_str = $flags_support
                   ? ($prepended_length ? "d V d2 V I2 d2 d$ndoubles" : 'd3 V I2 d2 d*')
                   : 'd3 I2 d2 d*';

    my @things = unpack($pack_str, $dump);
    $version = shift @things;
    $hashref = {version => $version};

    foreach (($prepended_length ? ('data_length') : ()),
             qw(min max),
             ($flags_support ? ('flags') : ()),
             qw(nbins nfills overflow underflow))
    {
      $hashref->{$_} = shift(@things);
    }

    if ($flags_support) {
      my $flags = delete $hashref->{flags};
      if (vec($flags, _PACK_FLAG_VARIABLE_BINS, 1)) {
        $hashref->{bins} = [splice(@things, $hashref->{nbins})];
      }
    }

    $hashref->{data} = \@things;
  }
  else {
    croak("Unknown dump type: '$type'");
  }

  my $self;
  if (defined $hashref->{bins}) {
    $self = $class->new(bins => $hashref->{bins});
  }
  else {
    $self = $class->new(
      min   => $hashref->{min},
      max   => $hashref->{max},
      nbins => $hashref->{nbins},
    );
  }

  $self->set_nfills($hashref->{nfills});
  $self->set_overflow($hashref->{overflow});
  $self->set_underflow($hashref->{underflow});
  $self->set_all_bin_contents($hashref->{data});

  return $self;
}


sub STORABLE_freeze {
  my $self = shift;
  my $cloning = shift;
  my $serialized = $self->dump('simple');
  return $serialized;
}

sub STORABLE_thaw {
  my $self = shift;
  my $cloning = shift;
  my $serialized = shift;
  my $new = ref($self)->new_from_dump('simple', $serialized);
  $$self = $$new;
  # Pesky DESTROY :P
  bless($new => 'Math::SimpleHisto::XS::Doesntexist');
  $new = undef;
}

sub to_soot {
  my ($self, $name, $title) = @_;
  $name = '' if not defined $name;
  $title = '' if not defined $title;

  require SOOT;
  my $th1d = TH1D->new($name, $title, $self->nbins, $self->min, $self->max);
  $th1d->SetBinContent($_, $self->bin_content($_-1)) for 1..$self->nbins;
  $th1d->SetEntries($self->nfills);

  return $th1d;
}

1;
__END__

=head1 NAME

Math::SimpleHisto::XS - Simple histogramming, but kinda fast

=head1 SYNOPSIS

  use Math::SimpleHisto::XS;
  my $hist = Math::SimpleHisto::XS->new(
    min => 10, max => 20, nbins => 1000,
  );
  
  $hist->fill($x);
  $hist->fill($x, $weight);
  $hist->fill(\@xs);
  $hist->fill(\@xs, \@ws);
  
  my $data_bins = $hist->all_bin_contents; # get bin contents as array ref
  my $bin_centers = $hist->bin_centers; # dito for the bins

=head1 DESCRIPTION

This module implements simple 1D histograms with fixed or
variable bin size. The implementation is mostly in C with a
thin Perl layer on top.

If this module isn't powerful enough for your histogramming needs,
have a look at the powerful-but-experimental L<SOOT> module or
submit a patch.

The lower bin boundary is considered part of the bin. The upper
bin boundary is considered part of the next bin or overflow.

Bin numbering starts at C<0>.

=head2 EXPORT

Nothing is exported by this module into the calling namespace by
default. You can choose to export the following constants:

  INTEGRAL_CONSTANT

Or you can use the import tag C<':all'> to import all.

=head1 FIXED- VS. VARIABLE-SIZE BINS

This module implements histograms with both fixed and variable
bin sizes. Fixed bin size means that all bins in the histogram
have the same size. Implementation-wise, this means that finding
a bin in the histogram, for example for filling,
takes constant time (O(1)).

For variable width histograms, each bin can have a different size.
Finding a bin is implemented with a binary search, which has
logarithmic run-time complexity in the number of bins O(log n).

=head1 BASIC METHODS

=head2 C<new>

Constructor, takes named arguments. In order to create a fixed bin size
histogram, the following parameters are mandatory:

=over 2

=item min

The lower boundary of the histogram.

=item max

The upper boundary of the histogram.

=item nbins

The number of bins in the histogram.

=back

On the other hand, for creating variable width bin size histograms,
you must provide B<only> the C<bins> parameter with a reference to
an array of C<nbins + 1> bin boundaries. For example,

  my $hist = Math::SimpleHisto::XS->new(
    bins => [1.5, 2.5, 4.0, 6.0, 8.5]
  );

creates a histogram with four bins:

  [1.5, 2.5)
  [2.5, 4.0)
  [4.0, 6.0)
  [6.0, 8.5)

=head2 C<fill>

Fill data into the histogram. Takes one or two arguments. The first must be the
coordinate that determines where data is to be added to the histogram.
The second is optional and can be a weight for the data to be added. It defaults
to C<1>.

If the coordinate is a reference to an array, it is assumed to contain many
data points that are to be filled into the histogram. In this case, if the
weight is used, it must also be a reference to an array of weights.

=head2 C<fill_by_bin>

Fills data into the histogram and works like C<fill()>, but the first
argument (the value(s)) must be bin numbers instead of coordinates.

=head2 C<min>, C<max>, C<nbins>, C<width>, C<highest_bin>

Return static histogram attributes: minimum coordinate, maximum coordinate,
number of bins, total width of the histogram, and the index of the
highest bin in the histogram (which is just C<nbins - 1>).

=head2 C<underflow>, C<overflow>

Return the accumulated contents of the under- and overflow bins (which
have the ranges from C<(-inf, min)> and C<[max, inf)> respectively).

=head2 C<total>

The total sum of weights that have been filled into the histogram,
excluding under- and overflow.

=head2 C<nfills>

The total number of fill operations (currently including fills that fill into
under- and overflow, but this is subject to change).

=head1 BIN ACCESS METHODS

=head2 C<binsize>

Returns the size of a bin. For histograms with variable width bin sizes,
the size of the bin with the provided index is returned (defaults to the
first bin). Example:

  $hist->binsize(12);

Returns the size of the 13th bin.

=head2 C<all_bin_contents>, C<bin_content>

C<$hist-E<gt>all_bin_contents()> returns the contents of all histogram bins
as a reference to an array. This is not the internal storage but a copy.

C<$hist-E<gt>bin_content($ibin)> returns the content of a single bin.

=head2 C<bin_centers>, C<bin_center>

C<$hist-E<gt>bin_centers()> returns a reference to an array containing
the coordinates of all bin centers.

C<$hist-E<gt>bin_center($ibin)> returns the coordinate of the center
of a single bin.

=head2 C<bin_lower_boundaries>, C<bin_lower_boundary>

Same as C<bin_centers> and C<bin_center> respectively, but
for the lower boundary coordinate(s) of the bin(s). Note that
this lower boundary is considered part of the bin.

=head2 C<bin_upper_boundaries>, C<bin_upper_boundary>

Same as C<bin_centers> and C<bin_center> respectively, but
for the upper boundary coordinate(s) of the bin(s). Note that
this lower boundary is I<not> considered part of the bin.

=head2 C<find_bin>

C<$hist-E<gt>find_bin($x)> returns the bin number of the bin
in which the given coordinate falls. Returns undef if the
coordinate is outside the histogram range.

=head1 SETTERS

=head2 C<set_bin_content>

C<$hist-E<gt>set_bin_content($ibin, $content)> sets the content of a single bin.

=head2 C<set_underflow>, C<set_overflow>

C<$hist-E<gt>set_underflow($content)> sets the content of the underflow bin.
C<set_overflow> does the obvious.

=head2 C<set_nfills>

C<$hist-E<gt>set_nfills($n)> sets the number of fills.

=head2 C<set_all_bin_contents>

Given a reference to an array containing numbers, sets the contents
of each bin in the histogram to the number in the respective
array element. Number of elements needs to match the number of bins
in the histogram.

=head1 CLONING

=head2 C<clone>, C<new_alike>

C<$hist-E<gt>clone()> clones the object entirely.

C<$hist-E<gt>new_alike()> clones the parameters of the object,
but resets the contents of the clone.

=head2 C<new_from_bin_range>, C<new_alike_from_bin_range>

C<$hist-E<gt>new_from_bin_range($first_bin, $last_bin)>
creates a copy of the histogram including all bins from C<$first_bin>
to C<$last_bin>. For example,
C<$hist-E<gt>new_from_bin_range(50, 199)> would create a new histogram
with 150 bins (the range is inclusive!) and copy the respective data
from the original histogram. All bin contents outside the range will
be added to the under- or overflow respectively. Specifying a last
bin above the highest bin number of the source histogram yields
a new histogram running up to the highest bin of the source.

C<$hist-E<gt>new_alike_from_bin_range($first_bin, $last_bin)>
does the same, but resets all contents (like C<new_alike>).

=head1 CALCULATIONS

=head2 C<rebin>

Given a rebinning factor, clones the current histogram and modifies it to
have C<$rebin_factor> times fewer bins. You can only rebin by factors
that divide the number of bins of the input histogram.

For example, you can rebin a histogram with 200 bins by a factor of 10.
This results in a histogram with 20 bins. You cannot rebin the same histogram
by a factor of 7 because 7 does not divide 200 without remainder.

=head2 C<add_histogram>

Given another histogram object, this method will add the content of that
object to the invocant's content. This works only if the binning of the
histograms is exactly the same. Throws an exception if that is not
the case.

=head2 C<subtract_histogram>

Given another histogram object, this method will subtract the content of that
object from the invocant's content. This works only if the binning of the
histograms is exactly the same. Throws an exception if that is not
the case.

=head2 C<integral>

Returns the integral over the histogram. I<Very limited at this point>. Usage:

  my $integral = $hist->integral($from, $to, TYPE);

Where C<$from> and C<$to> are the integration limits and the optional
C<TYPE> is a constant indicating the method to use for integration.
Currently, only C<INTEGRAL_CONSTANT> is implemented (and assumed as the
default). This means that the bins will be treated as rectangles,
but fractional bins are treated correctly.

If the integration limits are outside the histogram boundaries,
there is no warning, the integration is silently performed within
the range of the histogram.

=head2 C<mean>

Calculates the mean of the histogram contents.

Note that the result is not usually the same as if you calculated
the mean of the input data directly due to the effect of the binning.

=head2 C<standard_deviation>

Calculates the standard deviation of the histogram contents.

Note that the result is not usually the same as if you calculated
the std. dev. of the input data directly due to the effect of the binning.

First parameter may be the previously calculated mean to avoid
recalculating it. If not provided, it will be calculated on the fly.

=head2 C<median>

Calculates and returns the estimated median of the data in the
histogram. Achieves sub-bin-size resolution by estimating the median
position within the bin from the sum of data below and above the
median bin.

The estimation is necessary since the true median requires the
original data.

=head2 C<median_absolute_deviation>

I<WARNING> this is apparently still crashy when facing weird data!

Calculates and returns an estimate of the median absolute
deviation (MAD) of the histogram. This is a fairly expensive
operation.

Optionally, as an optimization, you can pass in the previously
calculated median estimate of the histogram to prevent it
from having to be recalculated. Make sure you pass in the
correct value or the behaviour of this method is undefined
and might even crash your perl!

=head2 C<normalize>

Normalizes the histogram to the parameter of the
C<$hist-E<gt>normalize($total)> call.
Normalization defaults to C<1>.

=head2 C<cumulative>

Calculates the cumulative histogram of the invocant
histogram and returns it as a B<new> histogram object.

The cumulative (if done in Perl) is:

  for my $i (0..$n) {
    $content[$i] = sum(map $original_content[$_], 0..$i);
  }

As a convenience, if a numeric argument is passed to the method,
the B<OUTPUT> histogram will be normalized using number B<BEFORE>
calculating the cumulation. This means that

  my $cumu = $histo->cumulative(1.);

gives a cumulative histogram where the I<last bin> contains exactly
C<1>.

=head2 C<multiply_constant>

Scales all bin contents, as well as over- and underflow
by the given constant.

=head1 RANDOM NUMBERS

This module comes with a Mersenne twister-based Random Number
Generator that follows that in the C<Math::Random::MT> module.
It is available in the C<Math::SimpleHisto::XS::RNG>
class. You can create a new RNG by passing one or more
integers to the C<Math::SimpleHisto::XS::RNG-E<gt>new(...)>
method. The object's C<rand()> method works like the normal
Perl C<rand($x)> function.

You can use a histogram as a source for random numbers that
follow the distribution of the histogram.

  push @random_like_hist, $hist->rand() for 1..100000;

If you pass a C<Math::SimpleHisto::XS::RNG> object to
the call to C<rand()>, that random number generator will be used.

=head2 C<rand>

Optionally given a L<Math::SimpleHisto::XS::RNG> object
(a random number generator), this
returns a random number that is drawn from the
distribution of the histogram.

=head1 SERIALIZATION

This class defines serialization hooks for the L<Storable>
module. Therefore, you can simply serialize objects using the
usual

  use Storable;
  my $string = Storable::nfreeze($histogram);
  # ... later ...
  my $histo_object = Storable::thaw($string);

Currently, this mechanism hardcodes the use of the C<simple>
dump format. This is subject to change!

=head2 Serialization and Compatibility

If at all possible, the de-serialization routine C<new_from_dump>
will be maintained in such a way that it will be able to
deserialize dumps of histograms that were done with earlier versions
of this module. If a new version of this module can not at all
achieve this, that will be mentioned prominently in the change log.

The other way around, serialized histograms are not generally
backwards-compatible across major versions. That means you cannot
deserialize a dump made with version 1.01 of this module using
version 0.05. Such backwards-incompatible changes will always
be accompanied with major version number changes
(0.X => 1.X, 1.X => 2.X...).

=head2 Serialization Formats

The various serialization formats that this module supports (see
the C<dump> documentation below) all have various pros and cons.
For example, the C<native_pack> format is by far the fastest, but
is not portable. The C<simple> format is a very simple-minded text
format, but it is portable and performs well (comparable to the C<JSON>
format when using C<JSON::XS>, other JSON modules will be B<MUCH>
slower).
Of all formats, the C<YAML> format is the slowest. See
F<xt/bench_dumping.pl> for a simple benchmark script.

None of the serialization formats currently supports compression, but
the C<native_pack> format produces the smallest output at about half
the size of the JSON output. The C<simple> format is close
to C<JSON> for all but the smallest histograms, where it produces
slightly smaller dumps.
The C<YAML> produced is a bit bigger than the C<JSON>.

=head2 C<dump>

This module has fairly simple serialization methods. Just call the
C<dump> method on an object of this class and provide the type of
serialization desire. Currently valid serializations are
C<simple>, C<JSON>, C<YAML>, and C<native_pack>. Case doesn't matter.

For C<YAML> support, you need to have the C<YAML::Tiny> module
available. For C<JSON> support, you need any of C<JSON::XS>,
C<JSON::PP>, or C<JSON>. The three modules are tried in order
at I<compile> time. The chosen implementation can be
polled by looking at the
C<$Math::SimpleHisto::XS::JSON_Implementation> variable. It contains
the module name. Setting this vairable has no effect.

The simple serialization format is a home grown text format that
is subject to change, but in all likeliness, there will be some
form of version migration code in the deserializer for backwards
compatibility.

All of the serialization formats B<except for C<native_pack>>
are text-based and thus portable and endianness-neutral.

C<native_pack> should not be used when the serialized data
is transferred to another machine.

=head2 C<new_from_dump>

Given the type of the dump (C<simple>, C<JSON>, C<YAML>,
C<native_pack>) and the actual dump string, creates a new
histogram object from the contained data and returns it.

Deserializing C<JSON> and C<YAML> dumps requires
the respective support modules to be available. See above.

=head1 SEE ALSO

L<SOOT> is a dynamic wrapper around the ROOT C++ library
which does histogramming and much more. Beware, it is experimental
software.

Serialization can make use of the L<JSON::XS>, L<JSON::PP>,
L<JSON> or L<YAML::Tiny> modules.
You may want to use the convenient L<Storable> module for transparent
serialization of nested data structures containing objects
of this class.

=head1 ACKNOWLEDGMENTS

This module contains some code written by Abhijit Menon-Sen,
who wrote C<Math::Random::MT>.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
