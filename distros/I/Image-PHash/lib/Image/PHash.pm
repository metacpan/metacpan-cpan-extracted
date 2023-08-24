package Image::PHash;

use 5.008;
use strict;
use warnings;
no warnings "portable";

use Carp;
use Config;
use Math::DCT 'dct2d';

our $VERSION = '0.3';

=head1 NAME

Image::PHash - Fast perceptual image hashing (DCT-based pHash)

=head1 SYNOPSIS

  use Image::PHash;

  # Load an image and prepare to hash.
  # Will try to find an image library to load and resize the image to 32x32, ready for the DCT step
  my $iph = Image::PHash->new($image_file);

  # Calculate the perceptual hash (top 8x8 of the DCT) - 64 bits, 16 hex chars
  my $p = $iph->pHash(); # implies settings geometry => '8x8', method => 'average'

  # Alternative, better performing, 64 bit hash (64 upper-left most DCT values)
  my $p = $iph->pHash(geometry => 64); # this is actually recommended over the default hash

  # Alternative method for creating the bitmask with lower false-negative rate
  my $p = $iph->pHash(geometry => 64, method => 'log');

  # Calculate a pHash with the upper left half of the upper-left-most 7x7 of the DCT - 27 bits, 7 hex chars
  # Use for indexing or reducing full phash false negatives - significant false negative rate by itself
  my $p7 = $iph->pHash(geometry => '7x7', reduce => 1);
  # or shortcut function
  $p7 = $iph->pHash7();

  # Calculate a pHash with the upper left half of the upper-left-most 6x6 of the DCT - 20 bits, 5 hex chars
  # Use for indexing or reducing full phash false negatives - very significant false negative rate by itself
  my $p6 = $iph->pHash(geometry => '6x6', reduce => 1, method => 'median');
  # or shortcut function
  $p6 = $iph->pHash6();

  # Calculate the difference (Hamming distance) between two hex hashes
  my $diff = Image::PHash::diff($p1, $p2);

=head1 DESCRIPTION

Image::PHash allows you to calculate the (DCT-based) perceptual hash (pHash) of an image.

The constructor and general structure is based on L<Image::Hash> - keeping usage quite
similar, but the pHash algorithm is rewritten from scratch as the L<Image::Hash>
implementation was flawed (and slow). Apart from fixes/tweaks for L<GD>, L<Imager>, 
L<ImageMagick> resizing, L<Image::Imlib2> support is added along with some unique features
like reduced hashes for indexing, options to deal with image mirroring, alternative
bitmap methods.

A fast DCT XS module made specifically to serve this hashing module is used: L<Math::DCT>.
Depending on your setup, it should be 15x or so faster than pHash.org

=head1 CONSTRUCTOR METHOD

=head2 C<new>

  my $iph = Image::PHash->new($image_file , $library?, \%settings?);
  
The first argument is an image filename when the Imlib2 library is used, but it
can also by a variable with the image data for the other libraries, or even an
image object for the supported libraries.

The second (optional) argument is the image library. Valid options are C<Imlib2>,
C<GD>, C<Imager>, C<ImageMagick> and if not specified the module will try to load
them in that order. Using a different library (or even library version) will most
likely result in different hashes being returned, so make sure you hash your entire
image set using the same image library. Also, the module will probably not work with
very old versions of the image libraries. See Notes for comparison of libraries.

The third (optional) argument can take a reference to a settings hash. Currently
supported settings:

=over 4

=item * C<resize> : Expects an integer to specify the size of the image resize before
applying the DCT transformation. By default it is C<32>, which resizes to a C<32x32> image.
You may want to explore different sizes which have different hashing behaviour e.g.
increasing resize to C<64> seems to offer some benefit for the reduced/index hashes
(at a performance penalty of course).

=item * C<magick_filter> : The C<filter> parameter for L<ImageMagick> which controls
the scaling filter. The default is C<Cubic> which is about as good as L<ImageMagick>'s
own default C<Lanczos>, but significantly faster. You can look up the L<ImageMagick>
documentation for alternatives (e.g. C<Lanczos>, C<Mitchell>, C<Triangle>, C<Gaussian>...)
if you want a different balance of speed/quality.

=item * C<imager_qtype> : The C<qtype> parameter for L<Imager> which defines the
quality of scaling performed. The type C<mixing> is used by default as it seems to
behave well for most cases while being about twice as fast as L<Imager>'s internal
default qtype of C<normal>, but you can still manually specify that if you prefer.

The constructor will C<croak> if there is an error loading an image library or an
incorrect/missing argument. It will only C<carp> and return C<undef> if an image
library returns after failing to load an image.

=back

=head1 METHODS

=head2 C<pHash>

  my $p = $iph->pHash(
      geometry    => '8x8',     # Size of the matrix to keep from the DCT. 8x8 is the standard 64 bit pHash.
      reduce      => 0,         # If enabled removes lower right half or matrix and 0,0 position.
      method      => 'average', # Method with which to convert the dct to bitmask.
      mirror      => 0,         # If enabled will return the hash of the mirror image (horizontal flip).
      mirrorproof => 0,         # If enabled will return a hash type that resists image mirroring.
  );

  my @bits = $iph->pHash();

Generates a pHash, returns it as a hex string (or array of 1s and 0s in array
context).

The pHash process consists of resizing the image to 32x32 (unless different C<resize>)
was specified with the constructor, converting color to luminance, DCT on resized image's
luminance, conversion to bit values based on the selected method and dropping the high
frequency part of the matrix, following the C<geometry> and C<reduce> settings.

The parameters to pass:

=over 4
 
=item * C<geometry> : A string with the desired square dimensions C<NxN> of the bit
matrix taken from the upper left of the full (by default 32x32) processed DCT to be
used in the hash. By default it is C<'8x8'>, which produces the typical 64bit pHash.

Alternatively, specify a simple integer for the number of low frequency bits to take
from the matrix going through the matrix in increasing diagonals.
E.g. a value of C<64> will return 64 bits just like the default pHash, but they will
be taken from the upper left half of the 11x11 top-left part of the DCT matrix. The
effect is that the resulting hash will have improved characteristics, especially
in the average distance of non-similar images.

=item * C<reduce> : The option will return only the bits that are on, or to the upper
left of the 0,N->N,0 diagonal of the selected NxN matrix, except the first bit (which
is always 1). This way you get the (N-1)*(2+N)/2 most significant (recording the largest
changes) bits. 

For example, a 8x8 reduced hash has 35 bits, which is less than a 6x6 matrix, and yet
may outperform a full 7x7 49 bit matrix.

The option only applies to square C<geometry>. If you have specified bits instead,
you already get an effect similar to C<reduce>.

=item * C<method> : Specifies which method to use for converting the DCT result to
a bitmask. By default it is C<average>. Supported methods:

=over 4

=item * C<average> : The default method which compares each DCT value with the arithmetic
mean. It usually a bit better at recognising similarity than C<median> (the average
difference of similar images will be lower), albeit with an increase in false positives.

=item * C<median> : The median of the DCT values is used as the threshold. Some
implementations prefer it over C<average> due to lower false positives/collision rate,
which can be good for reduced size hashes, but it increases false negatives so it is
not the recommended method for many scenarios.

=item * C<average_x> : Applies only to reduced hashes - it will calculate the average using
the entire NxN matrix for C<geometry='NxN'>, or use the next X lowest frequency DCT coefficients
(total 2*X) to calculate the average for C<geometry=X>. Almost as low collision rate as C<log>,
perhaps a bit better (lower) false negatives.

=item * C<log> : A special logarithmic average is calculated as the threshold, giving
the lowest collision rate (a tie with <median> or better). It will usually have a bit
increased false negative chance compared to C<average> or perhaps even C<diff> - but
should still be lower than C<median>. Quite close to C<average_x>, but also applies to
non-reduced hashes.

=item * C<diff> : The difference between each DCT value is taken as the bitmask. It seems
to fall between C<average> and C<median> in most tests, both in false negative/collision
rate and at similarity recognition.

=back

=item * C<mirror> : Returns the pHash of the mirror image. Note that this is a function
applied after the DCT, so if you call C<pHash> once with C<mirror> and once without
you can get both hashes without a processing overhead. Not compatible with C<mirrorproof>.

=item * C<mirrorproof> : Will return a pHash that is impervious to mirroring (flipping
images horizontally). This means two mirrored images will have the same/similar pHash,
so it is good for declaring such images as "similar" with a single pHash comparison, but
if you want to know they were mirrored the C<mirror> option is more appropriate.

Caveat: The option sacrifices about 2 bits or so of entropy, so the resulting
pHash is less effective. Thus, it should not be preferred if there is no specific
reason, especially when the C<mirror> option is available.

=back

=head1 INDEXING SHORTCUT METHODS

The special reduced hashes below, named B<pHash6> and B<pHash7> are specially chosen
to be useful in two scenarios:
* Extra verification to reduce false positives that the full has produces. Depending
on the scenario, tests have shown each of the reduced hash being able to reduce false
positives by 60-90% with the right threshold (example 2, 3 for pHash6, pHash7 resp.),
and if both are used over 95% reduction of false positives is possible.
* For scenarios where we want to use a simple index of a database (e.g. MySQL) and only
very simple manipulations are required to be matched (e.g. resize) or there is a higher
tolerance for false negatives, pHash6 & pHash7 at diff 0 can be used to retrieve most
matches. For example, storing pHash6, pHash7 (as indices) along with pHash in a MySQL db,
we can retrieve most matches with something like:

  SELECT *
  FROM hash_table
  WHERE (phash7 = @phash7
         OR phash6 = @phash6)
      AND BIT_COUNT(CAST(CONV(phash, 16, 10) AS UNSIGNED) ^ CAST(CONV(@phash, 16, 10) AS UNSIGNED)) < 8;


=head2 C<pHash7>

  my $p7 = $iph->pHash7();

Equivalent to C<$iph-E<gt>pHash(geometry =E<gt> '7x7', reduce =E<gt> 1)>. It is useful for
relational databases that don't support indexing with differences, so using the reduced
pHash will return many of the close full pHash matches. For simple resize/compression manipulations
expect matches in the region of 98% or so to be returned. It can also be used to verify
the match in some cases where a specific pattern might make different photos match in
the full phash but not the limited. It takes the same parameters as C<pHash>.

=head2 C<pHash6>

  my $p6 = $iph->pHash6();

Equivalent to C<$iph-E<gt>pHash(geometry =E<gt> '6x6', reduce =E<gt> 1, method =E<gt> 'median')>. Similar
to pHash7, but will produce more matches when used as an index, along with many more false
positives.

Note that neither reduced version is appropriate to use as an image comparison hash by itself
(too many false positives), and they are chosen to be complimentary, so when used in conjunction
for either indexing or verification, their performance increases considerably.

=head1 HELPER METHODS

=head2 C<reducedimage>

  my $img = $iph->reducedimage();

Returns the reduced (rescaled) image that will be used for the DCT.

=head2 C<dctdump>

  my $dct = $iph->dctdump();

Will return the full 32x32 DCT as an arrayref of floats.

=head2 C<printbitmatrix>

  $iph->printbitmatrix(
     %phash_opt,        # Any pHash method option applies
     separator => '',   # Separator for horizontal values
     filler    => ' '   # For reduced results, filler for the missing positions
  );

Will return a print-friendly reduced size bitmask matrix as a string. Basically a
string with rows/columns of the 1s and 0s you would get from calling C<$iph-E<gt>pHash()>
with the same parameters.

=head1 HELPER FUNCTIONS

=head2 C<b2h>

  my $hash = Image::PHash::b2h(join('', @bits));

Will convert a bit value string to a hex string.

=head2 C<diff>

  my $diff = Image::PHash::diff($phash1, $phash2);

Will calculate the bit difference of two hex string hashes (their Hamming distance
of their bit stream form). On 64 bit systems (checking C<$Config{ivsize}>) it will
actually call C<_diff64> which can calculate the difference of up to 64bit hashes in
a single operation (using C<%064b>). You can call C<_diff64> directly if you prefer
in that scenario.

=head1 NOTES

=head2 Performance

The hashing performance of the module is enough to make the actual pHash generation
from the final 32x32 mono image a trivial part of the process. For a general idea,
on a single core of a 2015 Macbook Pro, over 18000 hashes/sec can be processed thanks
in part to the fast L<Math::DCT> XS module (developed specifically for Image::PHash).

So, most of the processing time is spent on loading the image, resizing, extracting
pixel values, removing color, all of which depend on the specific image module. On an
Apple M1, hashing 800x600 jpg images was measured at 131 h/s with L<Image::Magick>,
208 h/s with L<Imager>, 241 h/s with L<GD>, 547 h/s with L<Image::Imlib2>.
Higher resolutions make the process slower as you could expect. Since all images will
be resized to 32x32 in the end, the fastest hashing performance would be if you loaded
32x32 thumbnails. In that case, the performance of the libraries in the same order for
the resized imageset were: 659 h/s, 664 h/s, 1883 h/s, 2296 h/s. It is clear that
L<Image::Imlib2> should be preferred when hashing performance is desired, as it offers
dramatically better performance (unless you are hashing 32x32 images in which case L<GD>
also fast). It should be noted that the resulting hashes don't have exactly the same
behaviour/metrics, due to the different resizing algorithms used, but the differences
seem to be very small. You are encouraged to test on your own data set.

Remember, never mix image libraries (or settings), the hashes will most likely not
be compatible.

Finally, if you are curious about the performance of this module compared to the
C++ pHash.org implementation, pHash.org could achieve 33 h/s with the test setup as
above, making L<Image::PHash> over 16x faster with Imlib2. With pre-sized 32x32
images, pHash.org ran at 101 h/s (~23x slower than L<Image::PHash>/Imlin2).

=head2 Compatibility of hashes

As already mentioned, if you produce hashes with different settings, different image
libraries etc, the hashes might not be compatible. It is advisable to even freeze
the version of this module and the image library in a production environment to
avoid any degraded performance.

=head2 Calculation caching

Calculating pHashes with different dct/reduce/median/mirror arguments for the same
image is very fast (when the same object is used), as the resize and DCT transform
will only happen on the very first pHash calculation and are cached for any subsequent
call. You can essentially get the extra phash6/phash7/mirror etc "for free" after
the initial pHash calculation.

=head2 L<Image::PHash> vs L<Image::Hash>

While L<Image::Hash> may still be useful for the aHash and dHash functionality, its
pHash implementation is seriously flawed. It does not actually do a full DCT, using
instead a shortcut that seems to result to hashes with lots of zeros and thus a high
rate of collisions (~2% chance for identical hash on dissimilar images making it useless
for my large data set), which is the reason the hashing was implemented from scratch.
Despite it not doing a full DCT it was really slow (over 80x slower than the XS L<Math::DCT>),
so switching to L<Image::PHash> will give you "correct" hashes at a significant speed
increase, along with several extra features.

=head2 L<Image::PHash> vs L<pHash.org>

Apart from the significant speed advantage of Image::PHash noted above, there are a couple
of important differences, in that pHash.org will apply a 7x7 mean filter to the image
before the resize and the conversion to bits is always done with the median method. This
seems to keep false positives quite low, but its false negatives are higher. Since with
Image::PHash you can get even better hashes with, for example, C<geometry=64> and you can
combine them with C<method='average_x'> or C<method='log'>, you will get even lower false
positive rate than pHash.org, but with less false negatives as well. Feel free to share
your own comparisons with the author if in doubt.

Note that the differences you are to use as a threshold for Image::PHash and pHash.org are
quite different - pHash.org will give about 50% greater diffs on average (e.g. where I would
use 7 for the former, 11 would be the equivalent for the latter).

=head2 Selecting a C<diff> threshold

The appropriate C<diff> threshold for declaring images as "similar" is not a precise
art and will depend on the application (type of images, tolerance for false positives
etc.). The exact application is very important too, if you have 2 images and want to
check whether they are similar, a false positive rate of even over 1% is fine, in which
case the diff can be chosen to be probably over 10, whereas having a big collection of
photos in which you want to check whether a duplicate exists, requires a very low false
positive rate. Example diff ranges for a full pHash are 3-7 if you want to keep false
positives close to 0%. For the small pHash7 and pHash6 probably not more than 3 and 2
respectively are useful for lookups (and still with lots of false positives as noted above).

=cut

my $_64bit;

sub pHash7 {
    my ($self, %opt) = @_;
    return $self->pHash(%opt, geometry => '7x7', reduce => 1);
}

sub pHash6 {
    my ($self, %opt) = @_;
    return $self->pHash(%opt, geometry => '6x6', reduce => 1, method => 'median');
}

sub new {
    my $class = shift;

    my $self = {};
    bless($self, $class);

    $self->{image}    = shift || croak("Image file or data expected.");
    $self->{module}   = shift;
    $self->{settings} = shift || {};

    croak("Hashref expected for settings argument") unless ref($self->{settings}) eq 'HASH';
    $self->{dct_size} = int($self->{settings}->{resize} || 32);
    $self->{imager_qtype} = $self->{settings}->{imager_qtype} || 'mixing';
    $self->{magick_filter} = $self->{settings}->{magick_filter} || 'Cubic';
    croak("resize > 5 expected.") unless $self->{dct_size} > 5;

    my %libs = ( # Library, reduce/resize function, pixels function, support for passing data variable
        Imlib2      => ['Image::Imlib2', \&_reduce_Imlib2, \&_pixels_Imlib2],
        GD          => ['GD', \&_reduce_GD, \&_pixels_GD, 1],
        ImageMagick => ['Image::Magick', \&_reduce_Magick, \&_pixels_Magick, 1],
        Imager      => ['Imager', \&_reduce_Imager, \&_pixels_Imager, 1],
    );

    my $ref  = ref($self->{image});
    my $file = $ref ? undef : -f $self->{image};

    if ($ref) {    # Passed image object
        $self->{module} = undef;
        foreach (_lib_order()) {
            my $type = $_ eq 'GD' ? 'GD::Image' : $libs{$_}->[0];
            if ($type eq $ref) {
                $self->{module} = $_;
                last;
            }
        }
        croak("Object of unknown type $ref.") unless $self->{module};
    } elsif ($self->{module}) {    # User specified image module
        $libs{$libs{$_}->[0]} = $libs{$_} for keys %libs;    # Allow synonyms
        my $lib = $libs{$self->{module}}->[0];

        croak("Unknown image library specified: '$self->{module}'. "
            . "Choose from: ".join(', ', map {/:/ ? () : $_} keys %libs)
        ) unless $lib;

        eval "require $lib"
            or croak("Specified image library '$self->{module}' could not be loaded.");

        $self->{module} = $lib; # Normalize
    } else {
        # Try to load Imlib2, GD, Imager, ImageMagick in that order
        foreach my $lib (_lib_order()) {
            if (eval "require $libs{$lib}->[0]" && ($file || $libs{$lib}->[3])) {
                $self->{module} = $lib;
                last;
            }
        }
        croak("None of the supported image libraries could be loaded. "
            . " Tried loading: ".join(', ', keys %libs)
        ) unless $self->{module};
    }
    croak("No file at $self->{image}")
        unless $ref || $file || (length($self->{image}) > 255 && $libs{$self->{module}}->[3]);

    my $error = '';
    if ($libs{$self->{module}}->[0] eq 'Image::Imlib2') {
        $self->{im} = $ref ? $self->{image} : Image::Imlib2->load($self->{image});
    } elsif ($libs{$self->{module}}->[0] eq 'GD') {
        GD::Image->trueColor(1);
        $self->{im} = $ref ? $self->{image} : GD::Image->new($self->{image});
    } elsif ($libs{$self->{module}}->[0] eq 'Image::Magick') {
        if ($ref) {
            $self->{im} = $self->{image};
        } else {
            $self->{im} = Image::Magick->new();
            $error =
                ($file)
                ? $self->{im}->Read($self->{image})
                : $self->{im}->BlobToImage($self->{image});
            $self->{im} = undef if $error;
        }
    } else {
        my $type = $file ? 'file' : 'data';
        $self->{im} = $ref ? $self->{image} : Imager->new($type => $self->{image});
        $error = Imager->errstr() || '';
    }

    unless ($self->{im}) {
        carp("Cannot load ".($file ? $self->{image} : 'data')." with $self->{module}. $error");
        return;
    }

    $self->{reduced} = $libs{$self->{module}}->[1];
    $self->{pixels}  = $libs{$self->{module}}->[2];

    $self->{methods} = {
        average   => \&_apply_average,
        average_x => \&_apply_average,
        median    => \&_apply_median,
        diff      => \&_apply_diff,
        log       => \&_apply_log_average,
    };

    return $self;
}

# Helper function:
# Convert from binary to hexadecimal
#
# Borrowed from http://www.perlmonks.org/index.pl?node_id=644225
sub b2h {
    my $num   = shift;
    my $WIDTH = 4;
    my $index = length($num) - $WIDTH;
    my $hex   = '';
    do {
        my $width = $WIDTH;
        if ($index < 0) {
            $width += $index;
            $index = 0;
        }
        my $cut_string = substr($num, $index, $width);
        $hex = sprintf('%X', oct("0b$cut_string")) . $hex;
        $index -= $WIDTH;
    } while ($index > (-1 * $WIDTH));
    return $hex;
}

sub _lib_order {qw/Imlib2 GD Imager ImageMagick/}

sub _is_64bit {
    $_64bit //= $Config{ivsize} >= 8;
    return $_64bit;
}

# Difference in bits between two hex strings
# About 30% slower than using %064b directly, but this is portable to 32 bits
sub diff {
    return _diff64(@_) if length($_[0]) <= 16 && ($_64bit || &_is_64bit);
    my $diff;
    for (my $i = 0; $i < length($_[0]); $i += 8) {
        my $d =
            sprintf("%032b", hex(substr($_[0], $i, 8))) ^
            sprintf("%032b", hex(substr($_[1], $i, 8)));
        $diff += $d =~ tr/\0//c;
    }
    return $diff;
}

sub _diff64 {
    my $k = sprintf("%064b", hex($_[0]));
    my $l = sprintf("%064b", hex($_[1]));
    my $diff = $k ^ $l;
    my $num_mismatch = $diff =~ tr/\0//c;
    return $num_mismatch;
}

# Reduce the size of an image using Imlib2
sub _reduce_Imlib2 {
    my $self = shift;
    return $self->{im_scaled} = $self->{im}
        if $self->{im}->width == $self->{dct_size}
        && $self->{im}->height == $self->{dct_size};

    $self->{im_scaled} =
        $self->{im}->create_scaled_image($self->{dct_size}, $self->{dct_size});
}

# Reduce the size of an image using GD
sub _reduce_GD {
    my $self = shift;
    $self->{im_scaled} = $self->{im};
    return
        if $self->{im}->width == $self->{dct_size}
        && $self->{im}->height == $self->{dct_size};

    my $dest = GD::Image->new($self->{dct_size}, $self->{dct_size});

    $dest->copyResampled(
        $self->{im_scaled}, 0, 0,                    # (srcimg, dstX, dstY)
        0, 0, $self->{dct_size}, $self->{dct_size},  # (srcX, srxY, destX, destY)
        $self->{im_scaled}->width, $self->{im_scaled}->height
    );
    $self->{im_scaled} = $dest;
}

# Reduce the size of an image using Image::Magick
sub _reduce_Magick {
    my $self = shift;
    $self->{im_scaled} = $self->{im};
    
    my ($w, $h) = $self->{im}->Get('width', 'height');
    return if $w == $self->{dct_size} && $h == $self->{dct_size};

    $self->{im_scaled}->Set(antialias => 'True');
    $self->{im_scaled}->Resize(
        width  => $self->{dct_size},
        height => $self->{dct_size},
        filter => $self->{magick_filter}
    );
}

# Reduce the size of an image using Imager
sub _reduce_Imager {
    my $self = shift;
    return $self->{im_scaled} = $self->{im}
        if $self->{im}->getwidth() == $self->{dct_size}
        && $self->{im}->getheight() == $self->{dct_size};

    $self->{im_scaled} = $self->{im}->scale(
        xpixels => $self->{dct_size},
        ypixels => $self->{dct_size},
        qtype   => $self->{imager_qtype},
        type    => "nonprop"
    );
}

# Return the pixel values for an image when using Imlib2
sub _pixels_Imlib2 {
    my $self = shift;
    my @pixels;
    for (my $y = 0; $y < $self->{dct_size}; $y++) {
        for (my $x = 0; $x < $self->{dct_size}; $x++) {

            my ($red, $green, $blue, $a) = $self->{im_scaled}->query_pixel($x, $y);
            my $grey = $red * 0.3 + $green * 0.59 + $blue * 0.11;
            push(@pixels, $grey);
        }
    }

    return \@pixels;
}

# Return the pixel values for an image when using GD
sub _pixels_GD {
    my $self = shift;
    my @pixels;
    for (my $y = 0; $y < $self->{dct_size}; $y++) {
        for (my $x = 0; $x < $self->{dct_size}; $x++) {

            my $color = $self->{im_scaled}->getPixel($x, $y);
            my ($red, $green, $blue) = $self->{im_scaled}->rgb($color);
            my $grey = $red * 0.3 + $green * 0.59 + $blue * 0.11;
            push(@pixels, $grey);
        }
    }

    return \@pixels;
}

# Return the pixel values for an image when using Image::Magick
sub _pixels_Magick {
    my $self = shift;
    my @pixels;
    for (my $y = 0; $y < $self->{dct_size}; $y++) {
        for (my $x = 0; $x < $self->{dct_size}; $x++) {
            my @pixel = $self->{im_scaled}->GetPixel(
                x         => $x,
                y         => $y,
                normalize => 0
            );
            my $grey = $pixel[0] * 0.3 + $pixel[1] * 0.59 + $pixel[2] * 0.11;
            push(@pixels, $grey);
        }
    }

    for (my $i = 0; $i <= $#pixels; $i++) {
        $pixels[$i] = $pixels[$i] / 256;
    }

    return \@pixels;
}

# Return the pixel values for an image when using Imager
sub _pixels_Imager {
    my $self = shift;
    my @pixels;
    for (my $y = 0; $y < $self->{dct_size}; $y++) {
        for (my $x = 0; $x < $self->{dct_size}; $x++) {
            my $c = $self->{im_scaled}->getpixel(
                x => $x,
                y => $y
            );
            my ($red, $green, $blue, $alpha) = $c->rgba();
            my $grey = $red * 0.3 + $green * 0.59 + $blue * 0.11;
            push(@pixels, $grey);
        }
    }
    return \@pixels;
}

sub reducedimage {
    my ($self, %opt) = @_;

    $self->{reduced}->($self, %opt) unless $self->{im_scaled};
    return $self->{im_scaled};
}

sub dctdump {
    my ($self, %opt) = @_;

    $self->{reduced}->($self, %opt) unless $self->{im_scaled};
    $self->{dct} ||= dct2d($self->{pixels}->(($self, %opt)));
    my $dctv = $self->_mirroring(%opt);

    return $self->{$dctv};
}

sub printbitmatrix {
    my $self  = shift;
    my %opt   = $self->_validate_options(@_);
    my @array = $self->pHash(%opt);
    my $sep   = $opt{separator} || '';
    my $fill  = $opt{filler} || ' ';

    my ($xs, $ys) = split(/x/, $opt{geometry});
    my $str = '';
    if ($ys) {
        for (my $i = 0; $i < $xs; $i++) {
            $str .= $opt{reduce} && ($i+$_==0 || $i+$_ >= ($xs+$ys)/2) ? "$fill$sep" : shift(@array).$sep
                for (0..$ys-1);
            $str .= "\n";
        }        
    } else {
        my @matrix = ("$fill$sep");
        OUTER:
        for (my $i = 1; $i < $self->{dct_size}; $i++) {
            for (my $j = 0; $j <= $i; $j++) {
                $matrix[$j] //= '';
                $matrix[$j] .= shift(@array).$sep;
                last OUTER unless @array;
            }
        }
        $str .= "$_\n" for @matrix;
    }
    return $str;
}

sub _mirroring {
    my ($self, %opt) = @_;

    my $dctv = 'dct';
    if ($opt{mirrorproof}) {
        $dctv = 'mirrorproof';
        $self->{$dctv} ||= _dct_mirrorproof($self->{dct});
        croak("Options 'mirror' and 'mirrorproof' are mutually exclusive") if $opt{mirror};
    } elsif ($opt{mirror}) {
        $dctv = 'mirror';
        $self->{$dctv} ||= _dct_mirror($self->{dct});
    }
    return $dctv;    
}

sub _validate_options {
    my ($self, %opt) = @_;
    my %valid = (
        geometry    => 1,
        method      => 1,
        mirror      => 1,
        mirrorproof => 1,
        reduce      => 1,
        separator   => 1,
        filler      => 1
    );

    foreach (keys %opt) {
        carp("Unknown option '$_'") unless $valid{$_};
    }

    $opt{geometry} ||= '8x8';
    $opt{method}   ||= 'average';
    if ($opt{geometry} =~ /^(\d+)(x\1)?$/) {
        croak("geometry cannot be greater than the resize value ($self->{dct_size})")
            if $2 && $1 > $self->{dct_size};
    } else {
        croak("geometry expected to be either 'NxN' for square matrix, or number of bits");
    }
    croak("Unsupported method. Choose from: ".keys(%{$self->{methods}}))
        unless $self->{methods}->{$opt{method}};

    return %opt;
}

sub pHash {
    my $self = shift;
    my %opt  = $self->_validate_options(@_);

    $self->{reduced}->($self, %opt) unless $self->{im_scaled};
    $self->{dct} ||= dct2d($self->{pixels}->($self, %opt));

    my $dctv = $self->_mirroring(%opt);

    my (@array, @extra);
    my $x_mult = ($opt{method} eq 'median' || $opt{method} eq 'average_x') ? 1 : 0;
    if ($opt{geometry} =~ /x/) {
        my ($xs, $ys) = split(/x/, $opt{geometry});
        for (my $i = 0; $i < $xs; $i++) {
            for (my $j = 0; $j < $ys; $j++) {
                next if $opt{reduce} && $i + $j == 0;
                if (!$opt{reduce} || ($i + $j < ($xs + $ys) / 2)) {
                    push @array, $self->{$dctv}->[$i * $self->{dct_size} + $j];
                } elsif ($x_mult) {
                    push @extra, $self->{$dctv}->[$i * $self->{dct_size} + $j];
                }
            }
        }
        # Let's allow diff=1 for median, even for NxN matrices
        push(@extra, $self->{$dctv}->[$xs+1], $self->{$dctv}->[($xs+1) * $self->{dct_size}])
            if ($x_mult && !$opt{reduce} && $xs < $self->{dct_size});
    } else {
        OUTER:
        for (my $i = 1; $i < $self->{dct_size}; $i++) {
            for (my $j = 0; $j <= $i; $j++) {
                if (scalar @array < $opt{geometry}) {
                    push(@array, $self->{$dctv}->[($i-$j)*$self->{dct_size}+$j]);
                } else {
                    $x_mult && scalar(@extra) < $x_mult * $opt{geometry}
                        ? push(@extra, $self->{$dctv}->[($i - $j) * $self->{dct_size} + $j])
                        : last OUTER;
                }
            }
        }
    }

    # Convert to binary using median/average threshold
    my $skip = (!$opt{reduce} && $opt{geometry} =~ /x/) ? 1 : 0;
    $self->{methods}->{$opt{method}}->(\@array, $skip, \@extra);


    # Return an array of binary values in array context and a hex representative in scalar context.
    if (wantarray()) {
        return @array;
    } else {
        return b2h(join('', @array));
    }
}

sub _dct_mirror {
    my $dct    = shift;
    my $t      = 1;
    my @mirror = map {($t ^= 1) ? -$_ : $_} @$dct;
    return \@mirror;
}

sub _dct_mirrorproof {
    my $dct    = shift;
    my $t      = 1;
    my @mirror = map {($t ^= 1) ? abs($_) : $_} @$dct;
    return \@mirror;
}

sub _apply_average {
    my $array   = shift;
    my $skip    = shift;
    my $extra   = shift;
    my $average = 0;
    $average += $array->[$_] foreach $skip .. $#$array;
    $average += $_           foreach @$extra;
    $average /= scalar(@$array) + scalar(@$extra) - $skip;
    $array->[$_] = $array->[$_] >= $average ? '1' : '0' foreach 0 .. $#$array;
}

sub _apply_log_average {
    my $array   = shift;
    my $skip    = shift;
    my $exp     = 1 + (scalar(@$array)**(1 / 6));
    my $average = 0;
    foreach ($skip .. $#$array) {
        my $add = abs($array->[$_])**(1 / $exp);
        $average += $array->[$_] < 0 ? -$add : $add;
    }
    $average /= scalar(@$array) - $skip;
    my $thres = abs($average)**$exp;
    $thres *= -1 if $average < 0;
    $array->[$_] = $array->[$_] >= $thres ? '1' : '0' foreach 0 .. $#$array;
}

sub _apply_diff {
    my $array = shift;
    my $prev  = 0;
    foreach (0 .. $#$array) {
        my $diff = $array->[$_] > $prev ? 1 : 0;
        $prev = $array->[$_];
        $array->[$_] = $diff;
    }
}

sub _apply_median {
    my $array = shift;
    my $skip  = shift;
    my $extra = shift;
    my @vals  = sort {$a <=> $b} @$array, @$extra;
    my $len   = scalar @vals - $skip;
    my $thresh =
          $len % 2
        ? $vals[int($len / 2)]
        : ($vals[int($len / 2) - 1] + $vals[int($len / 2)]) / 2;
    $array->[$_] = $array->[$_] >= $thresh ? '1' : '0' foreach 0 .. $#$array;
}

=head1 ACKNOWLEDGEMENTS

Initially based on L<Image::Hash>, so some code to do with loading images, pixels
etc has been kept/adapted.

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>
 
=head1 BUGS

Please report any bugs or feature requests either on GitHub, or on RT (via the email
C<bug-image-phash at rt.cpan.org> or web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-PHash>).

I will be notified, and then you'll be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/dkechag/Image-PHash>
 
=head1 COPYRIGHT & LICENSE

Copyright (C) 2022, SpareRoom & Dimitrios Kechagias.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut


1;
