package Image::Signature;

use strict;
our $VERSION = '0.01';

use Image::Magick;

use Image::Signature::Vars;

use Image::Signature::ColorHistogram;
use Image::Signature::GrayMoment;

our @ISA =
    qw(
     Image::Signature::ColorHistogram
     Image::Signature::GrayMoment

       );


sub new {
    my $pkg = shift;
    my $arg = shift;
    my $img;
    if(! ref($arg) ){
	$img = Image::Magick->new;
	$img->Read($arg);
    }
    else {
	$img = $arg;
    }
    my ($row, $col) = $img->Get(qw/rows columns/);

    bless {
	version => $VERSION,
	img => $img,
	row => $row,
	col => $col,
    }, $pkg;
}



sub signature {
    my $self = shift;
    $self->color_histogram();
    $self->gray_moment();
    return { 
	'produced by' => __PACKAGE__." $VERSION",
	'color_signature' => $self->{color_histogram},
	'moment' => $self->{std_moment},
    }
}


sub compare {
    my $this = shift;
    my $that = shift;
    my $sqrsum = 0;
    my ($this_len, $that_len, $innproduct, $length_sqr);
    my %retval;
    local $_;

    # color histograms
    foreach my $color (@colorname){
	$sqrsum = 0;
	foreach my $level (0..65535){
	    $innproduct += ($this->{$color}->{$level} *
			    $that->{$color}->{$level} )
	}

	$length_sqr = 0;
	foreach (keys %{$this->{color_histogram}->{$color}}){
	    $length_sqr += $this->{color_histogram}->{$color}->{$_}**2;
	}
	$this_len = sqrt $length_sqr;

	$length_sqr = 0;
	foreach (keys %{$that->{color_histogram}->{$color}}){
	    $length_sqr += $that->{color_histogram}->{$color}->{$_}**2;
	}
	$that_len = sqrt $length_sqr;
	$retval{color_similarity}->{$color} = $innproduct / ($this_len*$that_len);
    }

    # gray-level moment
    $retval{moment_similarity} = abs($this->{std_moment} - $that->{std_moment});

    return %retval;

}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Signature - Deriving signatures of images


=head1 SYNOPSIS

  use Image::Signature;


  # initiation from the ground
  $sig_obj = new Image::Signature("pic.jpg");

  # initiation from an image-magick object
  $sig_obj = new Image::Signature $image_object;

  # calculation of signature
  $sig_object_A->signature();

  # comparison of two signature
  $sig_object_A->compare($sig_object_B);

=head1 DESCRIPTION

Image signature is something that can be capable of describing properties of an image without knowing the entire picture. It is analogous to index of texts. Signatures are produced using various algorithms, including color histograms, texture properties, local and global attributes, etc. This module is aimed at being able to implement some practical, general-purpose, and I<easy-to-implement> algorithms for producing signatures. With signatures, one can develop further applications, such as image retrieval systems. Fortunately, with the L<ImageMagick> backend, multiple formats of images are supported.


Since I'm just a newbie in image processing, currently, only color histogram and gray-level moments are implemented, and the modules are poorly documented. The code is entirely written in PERL, and so it may be inevitably slow. The module will be expanded and upgraded in the future with the growth of my knowledge I<if it grows>.

=head1 METHODS

=head2 new

The argument can be an image file or an ImageMagick object.

 $sig_obj = new Image::Signature $arg;

=head2 signature

Derives image signature.

The current methods available are color histograms and gray-level moment.

=head3 color_histogram

 $sig_obj->color_histogram;

=head3 gray_moment

 $sig_obj->gray_moment;

=head2 compare

Compares the similarity between two image objects.

 $sig_objA->compare($sig_objB);

=head1 SEE ALSO

L<GD>, L<Image::Magick>

=head1 BUGS AND TODOs

Must be many. Please report them to me.

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
