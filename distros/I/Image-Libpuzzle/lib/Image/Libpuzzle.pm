package Image::Libpuzzle;

use strict;
use warnings;

our $VERSION = '0.07';
require XSLoader;
XSLoader::load('Image::Libpuzzle', $VERSION);

our $DEFAULT_NGRAM_SIZE = 10;

# Convenient package variables for the defines in puzzle.h; changing them does nothing.
our $PUZZLE_VERSION_MAJOR                   = Image::Libpuzzle->PUZZLE_VERSION_MAJOR;
our $PUZZLE_VERSION_MINOR                   = Image::Libpuzzle->PUZZLE_VERSION_MINOR;
our $PUZZLE_CVEC_SIMILARITY_THRESHOLD       = Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_THRESHOLD;
our $PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD  = Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD;
our $PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD   = Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD;
our $PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD = Image::Libpuzzle->PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD;

# uses unpack as bin to char and $self accessor to get signature directly from the internal cvec
sub signature_as_char_string {
  my $self = shift;
  my @sig  = unpack("C*", $self->get_signature());
  my $sig  = q{};
  foreach my $i (@sig) {
    $sig .= sprintf("%02d", $i);
  }
  return $sig;
}

# returns an ARRAY ref of all ngrams, of L-R sliding window of size $ngram_size
sub signature_as_char_ngrams {
  my $self       = shift;
  my $ngram_size = shift || $DEFAULT_NGRAM_SIZE;
  my $sig        = $self->signature_as_char_string;
  my @ngrams     = ();
  for (my $i = 0; $i <= length($sig) - $ngram_size; $i++) {
    push @ngrams, substr($sig, $i, $ngram_size);
  }
  return \@ngrams;
}

# uses unpack as bin to hex and $self accessor to get signature directly from the internal cvec
sub signature_as_hex_string {
  my $self = shift;
  my @sig  = unpack("H*", $self->get_signature());
  my $sig  = q{};
  foreach my $i (@sig) {
    $sig .= sprintf("%s", $i);
  }
  return $sig;
}

# returns an ARRAY ref of all ngrams, of L-R sliding window of size $ngram_size
sub signature_as_hex_ngrams {
  my $self       = shift;
  my $ngram_size = shift || $DEFAULT_NGRAM_SIZE;
  my $sig        = $self->signature_as_hex_string;
  my @ngrams     = ();
  for (my $i = 0; $i <= length($sig) - $ngram_size; $i++) {
    push @ngrams, substr($sig, $i, $ngram_size);
  }
  return \@ngrams;
}

1;

__END__
=pod

=head1 NAME

Image::Libpuzzle - Perl interface to libpuzzle. 

=head1 SYNOPSIS

 use Image::Libpuzzle; 
 
 my $pic1 = q{pics/luxmarket_tshirt01.jpg};
 my $pic2 = q{pics/luxmarket_tshirt01_sal.jpg};
 
 my $p1 = Image::Libpuzzle->new;
 my $p2 = Image::Libpuzzle->new;
 
 my $sig1 = $p1->fill_cvec_from_file($pic1);
 my $sig2 = $p2->fill_cvec_from_file($pic2);

 # contrived example to show the setting of some parameters that affect the signature
 
 foreach my $i ( 11, 9, 7, 5 ) {
   foreach my $j ( 2.0, 1.0, 0.5 ) {
     print "Lambda: $i, p ratio: $j\n";

     # set some params for sig1
     $p1->set_lambdas($i);
     $p1->set_p_ratio($j);

     # get signature for pic1
     $sig1 = $p1->fill_cvec_from_file($pic1);

     # set same params for sig2
     $p2->set_lambdas($i);
     $p2->set_p_ratio($j);

     # get signature for pic2
     $sig2 = $p2->fill_cvec_from_file($pic2);

     # stringify sig1
     my $string1 = $p1->signature_as_char_string;
     print qq{$string1\n};

     # stringify sig2
     my $string2 = $p2->signature_as_char_string;
     print qq{$string2\n};

     # generate a "document" of ngrams from sig1
     my $words1_ref = $p1->signature_as_char_ngrams; # defaults to $ngram size of $Image::Libpuzzle::DEFAULT_NGRAM_SIZE
     print join ' ', @$words1_ref;

     # generate a "document" of ngrams from sig2
     my $words2_ref = $p2->signature_as_char_ngrams(6); # example overriding $Image::Libpuzzle::DEFAULT_NGRAM_SIZE 
     print join ' ', @$words2_ref;

     # print Euclidean length of sig1
     printf("\nEuclidean length: %f",$p1->vector_euclidean_length);

     # print Euclidean length of sig2
     printf("\nDiff with \$p2: %f", $p1->vector_normalized_distance($p2));

     # compare images with a helper method
     printf("\nCompare 1: Is %s",($p1->is_most_similar($p2)) ? q{most similar} : q{not most similar});
     print "\n";

     # compare images directly
     printf("\nCompare 2: Is %s",( $p1->vector_normalized_distance($p2) < $Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD ) ? q{most similar} : q{not most similar});
     print "\n";
     print "\n\n";
   }
 }

=head1 DESCRIPTION

This XS module provdes access to the most common functionality provided by
Libpuzzle, L<http://www.pureftpd.org/project/libpuzzle>.

It also includes some pure Perl helper methods users of Libpuzzle might find
helpful when creating applications based on it.

This module is in its very early form. It may change without
notice. If a feature is missing, please request it at
L<https://github.com/estrabd/p5-puzzle-xs/issues>.

=head1 NOTES ON USING LIBPUZZLE

Below are some brief notes on how to use this module in order to get the most
out of the underlying Libpuzzle library.

=head2 Comparing Images

Libpuzzle presents a robust, fuzzy way to compare the similarity of images. Read
more about the technique in the paper that describes it,

L<http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.104.2585&rep=rep1&type=pdf>

=head2 Working With Signatures

Signatures are typically not printable date, so one may either use the native
Libpuzzle methods to work with them, such as C<vector_euclidean_length> and
C<vector_normalized_distance>.

C<Image::Libpuzzle> provides two methods for generating signatures in a
printable form that may be used to deal with signatures in a more printable way,
C<signature_as_char_string> and C<signature_as_ngrans>. See below for more details.

=head2 Comparing Millions of Images

This Stack Overflow URL seems to be the best resources for addressing this
question:

L<http://stackoverflow.com/questions/9703762/libpuzzle-indexing-millions-of-pictures>

The C<Image::Libpuzzle::signature_as_char_ngrams> methods may be used to generate
ngrams (words of size N) for use with the oft suggested approach to searching
for similar images in a database of signatures.

=head2 Working With Compressed Signatures

Working with compressed signatures is not currently supported in this module,
but may be added in the future if there is demand.

=head1 XS METHODS AND SUBROUTINES

=head2 C<new()>

Constructor, returns a C<Image::Libpuzzle> reference. Use C<set_*> methods to change the
default values outlined in C<man puzzle_set(3)>.

=head2 C<get_cvec()>

Returns a Image::Libpuzzle::Cvec reference, currently one can't do much with
this.

=head2 C<fill_cvec_from_file(q{/path/to/image})>

Generates the signature for the given file.

=head2 C<get_signature()>

Returns the signature in the original form.

Assumes C<fill_cvec_from_file> has been called on a valid image already.

=head2 C<set_lambdas($integer)>

Wrapper around Libpuzzle's function. Sets the number of samples taken for each
image.

The default is set in puzzle.h is 9; i.e., by default, pictures are divided in 9
x 9 blocks.

C<man puzzle_set(3)> says,

For large databases, for complex images, for images with a lot of text or for
sets of near-similar images, it might be better to raise that value to 11 or
even 13

However, raising that value obviously means that vectors will require more
storage space.

The lambdas value should remain the same in order to get comparable vectors. So
if you pick 11 (for instance), you should always use that value for all pictures
you will compute a digest for. C<puzzle_set_p_ratio()>

The average intensity of each block is based upon a small centered zone.

The "p ratio" determines the size of that zone. The default is 2.0, and that
ratio mimics the behavior that is described in the reference algorithm.

For very specific cases (complex images) or if you get too many false positives,
as an alternative to increasing lambdas, you can try to lower that value, for
instance to 1.5.

The lowest acceptable value is 1.0.

=head2 C<set_p_ratio($double)>

Wrapper around Libpuzzle's function. Sets the size of the samples. Used in
conjunction with C<set_lambdas> to get more or less precise signatures.

C<man puzzle_set(3)> says,

The "p ratio" determines the size of that zone. The default is 2.0, and that
ratio mimics the behavior that is described in the reference algorithm.

=head2 C<set_max_width($integer)>

Wrapper around Libpuzzle's function.

C<man puzzle_set(3)> says,

In order to avoid CPU starvation, pictures won't be processed if their width or
height is larger than 3000 pixels.

=head2 C<set_max_height($integer)>

Wrapper around Libpuzzle's function.

See C<set_max_width>.

=head2 C<set_noise_cutoff($integer)>

Wrapper around Libpuzzle's function.

C<man puzzle_set(3)> says,

The noise cutoff defaults to 2. If you raise that value, more zones with little
difference of intensity will be considered as similar.

Unless you have very specialized sets of pictures, you probably don't want to
change this.

=head2 C<set_autocrop(1|0)>

Wrapper around Libpuzzle's function.

C<man puzzle_set(3)> says,

By default, featureless borders of the original image are ignored. The size
of each border depends on the sum of absolute values of differences between
adjacent pixels, relative to the total sum.

That feature can be disabled with C<puzzle_set_autocrop(0)> Any other value will
enable it.

C<puzzle_set_contrast_barrier_for_cropping()> changes the tolerance. The default
value is 5. Less shaves less, more shaves more.

C<puzzle_set_max_cropping_ratio()> This is a safe-guard against unwanted
excessive auto-cropping.

The default (0.25) means that no more than 25% of the total width (or height)
will ever be shaved.

=head2 C<set_contrast_barrier_for_cropping($integer)>

Wrapper around Libpuzzle's function.

See C<set_autocrop> for details.

=head2 C<set_max_cropping_ratio($double)>

Wrapper around Libpuzzle's function.

See C<set_autocrop> for details.

=head2 C<vector_euclidean_length()>

Wrapper around Libpuzzle's function. Returns a length value for
the signature, used when computing distances between two images in
C<vector_normalized_distance>.

=head2 C<vector_normalized_distance(Image::Libpuzzle $instance2)>

Returns the computed distance between two C<Image::Libpuzzle> instances.

 my $distance = $instance1->vector_normalized_distance($instance2);

NOTE: internally, "fix_for_texts" is set to 1; there is currently no way to toggle this behavior.

According to C<man 3 libpuzzle>: 

If the fix_for_texts of puzzle_vector_normalized_distance() is 1 , a fix
is applied to the computation in order to deal with bitmap pictures that
contain text. That fix is recommended, as it allows using the same
threshold for that kind of picture as for generic pictures.

=head2 C<is_similar(Image::Libpuzzle $instance2)>

Convenience methods, compares images using C<PUZZLE_CVEC_SIMILARITY_THRESHOLD>

=head2 C<is_very_similar(Image::Libpuzzle $instance2)>

Convenience methods, compares images using
C<PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD>

=head2 C<is_most_similar(Image::Libpuzzle $instance2)>

Convenience methods, compares images using C<PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD>

=head2 C<PUZZLE_VERSION_MAJOR()>

Returns constant defining major version.

=head2 C<PUZZLE_VERSION_MINOR()>

Returns constant defining minor version.

=head2 C<PUZZLE_CVEC_SIMILARITY_THRESHOLD()>

Returns constant defining the average normalized distance cutoff for considering
two images as similar. Used by C<is_similar>.

=head2 C<PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD()>

Returns constant defining the upper limit normalized distance cutoff for
considering two images as similar. Must be used directly.

=head2 C<PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD()>

Returns constant defining more precise normalized distance cutoff for
considering two images as similar. Used by C<is_very_similar>.

=head2 C<PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD()>

Returns constant defining the most precise normalized distance cutoff for
considering two images as similar. Used by C<is_most_similar>.

=head1 Pure Perl METHODS AND SUBROUTINES

=head2 C<signature_as_char_string()>

Returns a stringified version of the signature. The string is generated by
unpack'ing into an array of ASCII characters (C*). Before the array of character
codes is joined into a string, they are padded. For example, 1 turns into 001;
25 turns into 025; 211 remains the same.

Assumes C<fill_cvec_from_file> has been called on a valid image already.

=head2 C<signature_as_char_ngrams()>

Takes the output of C<signature_as_char_string> and returns an ARRAY ref of C<words>
of size C<$ngram_size>. The default, C<$DEFAULT_NGRAM_SIZE> is set to 10. An
optional argument may be passed to override this default.

The paragraph of ngrams is constructed in a method consistent with the one
described in the following link:

L<http://stackoverflow.com/questions/9703762/libpuzzle-indexing-millions-of-pict
ures>

Assumes C<fill_cvec_from_file> has been called on a valid image already.

=head2 C<signature_as_hex_string()>

Returns a stringified version of the signature. The string is generated by
unpack'ing into an array of hexidecimal digits (H*). Before the array of character
codes is joined into a string. They are not padded like the C* based strings that
are generated with C<signature_as_char_ngrams>. As a result, the signatures are
not as long and therefore create fewer ngrams with C<signature_as_hex_ngrams>.

=head2 C<signature_as_hex_ngrams()>

Takes the output of C<signature_as_hex_string> and returns an ARRAY ref of C<words>
of size C<$ngram_size>. The default, C<$DEFAULT_NGRAM_SIZE> is set to 10. An
optional argument may be passed to override this default.

=head1 ENVIRONMENT

This module assumes that libpuzzle is installed and puzzle.h is able to be found
in a default LIBRARY path.

Libpuzzle is available via most Ports/package repos. It also builds easily,
though it requires C<libgd.so>.

Also see, L<http://www.pureftpd.org/project/libpuzzle>.

=head2 Package Variables

There also exist corresponding methods to return these. Changing these package variables
affects nothing at this time.

=over 4

=item C<Image::Libpuzzle::PUZZLE_VERSION_MAJOR>

=item C<Image::Libpuzzle::PUZZLE_VERSION_MINOR>

=item C<Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_THRESHOLD>

=item C<Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_HIGH_THRESHOLD>

=item C<Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOW_THRESHOLD>

=item C<Image::Libpuzzle::PUZZLE_CVEC_SIMILARITY_LOWER_THRESHOLD>

=back

=head1 BUGS AND LIMITATIONS

Please report them via L<https://github.com/estrabd/p5-puzzle-xs/issues>.

=head1 AUTHOR

B. Estrade <estrabd@gmail.com>

=head2 THANK YOU

My good and ridiculously smart friend, Xan Tronix (~xan), helped me patiently as
I was working through n00b XS bits during the writing of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Estrade

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.14.4 or, at your option,
any later version of Perl 5 you may have available.

=cut
