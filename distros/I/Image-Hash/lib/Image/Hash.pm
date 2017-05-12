package Image::Hash;

use strict;
use warnings;

use List::Util qw(sum);
use Carp;

our $VERSION = '0.06';


=head1 NAME

Image::Hash - Perceptual image hashing [aHash, dHash, pHash].

=head1 SYNOPSIS

  use Image::Hash;
  use File::Slurp;
  
  # Read a image from the command line
  my $image = read_file( shift @ARGV, binmode => ':raw' ) ;

  my $ihash = Image::Hash->new($image);

  # Calculate the average hash
  my $a = $ihash->ahash();

  # Calculate the difference hash
  my $b = $ihash->dhash();

  # Calculate the perception hash
  my $p = $ihash->phash();

  print "$a\n$b\n$p\n";



=head1 DESCRIPTION

Image::Hash allows you to calculate the average hash, difference hash and perception hash an image.

Depending on what is available on your system Image::Hash will use GD, Image::Magick or Imager to interact with your image.



=head1 CONSTRUCTOR METHODS

  my $ihash = Image::Hash->new($image [, $module ]);
  
The first argument is a scalar with a binary representation of an image.

You may also optionally specify a second argument of "GD", "ImageMagick" or "Imager" to force Image::Hash to use the specific image module when it interacts with the image.
The different image modules may give direct hashes for the same image. Using GD normally hives the best results, and are is highly recommended.


=cut

sub new {
	my $class = shift;


	my $self = {};  
	bless( $self, $class );
	
	$self->{'image'} = shift;
	$self->{'module'} = shift;
	
	if ($self->{'module'}) {
		# Try to load the image handler the user asked for
		if ($self->{'module'} eq "GD") {
			require GD;
		}
		elsif ($self->{'module'} eq "ImageMagick" || $self->{'module'} eq "Image::Magick") {
			require Image::Magick;
			$self->{'module'} = 'ImageMagick';
		}
		elsif ($self->{'module'} eq "Imager") {
			require Imager;
		}
		else {
			croak("Unknown mudule: '" . $self->{'module'} . "'. Please use either GD, ImageMagick or Imager as module.");
		}
	}
	else {
		# Try to load GD, ImageMagic or Imager
		if (eval 'require GD') {
			$self->{'module'} = "GD";
		}
		elsif (eval 'require Image::Magick') {
			$self->{'module'} = "ImageMagick";
		}
		elsif (eval 'require Imager') {
			$self->{'module'} = "Imager";
		}
		else {
			croak("No image maudule avalibal. Can't load  GD, ImageMagic or Imager.");
		}
	}
	
	

	
	if ($self->{'module'} eq 'GD') {
		$self->{'im'} = GD::Image->new( $self->{'image'} );
		if (not defined $self->{'im'}) {
			carp("Can't make image from this value");
			return undef;
		}
		$self->{'reduse'} = \&reduse_GD;
		$self->{'pixels'} = \&pixels_GD;
		$self->{'blob'}   = \&blob_GD;
	}
	elsif ($self->{'module'} eq 'ImageMagick') {
		$self->{'im'} = Image::Magick->new();
		my $ret = $self->{'im'}->BlobToImage( $self->{'image'} );
		if ($ret == 0) {
			carp("Can't make image from this value");
			return undef;
		}
		$self->{'reduse'} = \&reduse_ImageMagick;
		$self->{'pixels'} = \&pixels_ImageMagick;
		$self->{'blob'}   = \&blob_ImageMagick;

	}
	elsif ($self->{'module'} eq 'Imager') {
		$self->{'im'} = Imager->new(data=>$self->{'image'});
		if (not defined $self->{'im'}) {
			carp("Can't make image from this value: " . Imager->errstr());
			return undef;
		}
		$self->{'reduse'} = \&reduse_Imager;
		$self->{'pixels'} = \&pixels_Imager;
		$self->{'blob'}   = \&blob_Imager;
	}
	


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
    my $hex = '';
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

# Reduse the size of an image using GD
sub reduse_GD {
	my ($self, %opt) = @_;
	$self->{ $opt{'im'} } = $self->{'im'};

	my ($xs, $ys) = split(/x/, $opt{'geometry'});

	my $dest = GD::Image->new($xs, $ys);

	$dest->copyResampled($self->{ $opt{'im'} },
		0, 0, 		# (destX, destY)
		0, 0, 		# (srcX,  srxY )
		$xs, $ys, 	# (destX, destY)
		$self->{ $opt{'im'} }->width, $self->{ $opt{'im'} }->height
	);
	$self->{ $opt{'im'} } = $dest;
}

# Reduse the size of an image using Image::Magick
sub reduse_ImageMagick {
	my ($self, %opt) = @_;
	$self->{ $opt{'im'} } = $self->{'im'};

    $self->{ $opt{'im'} }->Set(antialias=>'True');
    $self->{ $opt{'im'} }->Resize($opt{'geometry'});
}

# Reduse the size of an image using Imager
sub reduse_Imager {
	my ($self, %opt) = @_;
	my ($xs, $ys) = split(/x/, $opt{'geometry'});

	$self->{ $opt{'im'} } = $self->{ 'im' }->scale(xpixels => $xs, ypixels => $ys, type => "nonprop");
}


# Return the image as a blob using GD
sub blob_GD {
        my ($self, %opt) = @_;

	return $self->{ $opt{'im'} }->png;
}

# Return the image as a blob using Image::Magick
sub blob_ImageMagick {
        my ($self, %opt) = @_;

	my $blobs = $self->{ $opt{'im'} }->ImageToBlob(magick => 'png');

	return $blobs;
}

# Return the image as a blob using Imager
sub blob_Imager {
        my ($self, %opt) = @_;
	
	my $data;
	$self->{ $opt{'im'} }->write(data => \$data, type => 'png') or carp $self->{ $opt{'im'} }->errstr;

	return $data;
}

# Return the pixel values for an image when using GD
sub pixels_GD {
	my ($self, %opt) = @_;
	
	my ($xs, $ys) = split(/x/, $opt{'geometry'});
	
	my @pixels;
	for(my $y=0; $y<$ys;$y++) {
			for(my $x=0; $x<$xs;$x++) {

					my $color = $self->{ $opt{'im'} }->getPixel($x, $y);
					my ($red, $green, $blue) = $self->{ $opt{'im'} }->rgb($color);
					my $grey = $red*0.3 + $green*0.59 + $blue*0.11;
					push(@pixels, $grey);
			}
	}
	
	return @pixels;
}

# Return the pixel values for an image when using Image::Magick
sub pixels_ImageMagick {
	my ($self, %opt) = @_;
	my ($xs, $ys) = split(/x/, $opt{'geometry'});
	
	my @pixels;
	for(my $y=0; $y<$ys;$y++) {
			for(my $x=0; $x<$xs;$x++) {
					my @pixel = $self->{ $opt{'im'} }->GetPixel(x=>$x,y=>$y,normalize => 0);
					my $grey = $pixel[0]*0.3 + $pixel[1]*0.59 + $pixel[2]*0.11;
					push(@pixels, $grey);
			}
	}
	
	
	for (my $i = 0; $i <= $#pixels; $i++) {
		$pixels[$i] = $pixels[$i] / 256;
	}
	
	return @pixels;
}

# Return the pixel values for an image when using Imager
sub pixels_Imager {
	my ($self, %opt) = @_;
	my ($xs, $ys) = split(/x/, $opt{'geometry'});
	my @pixels;
	for(my $y=0; $y<$ys;$y++) {
			for(my $x=0; $x<$xs;$x++) {
					my $c = $self->{ $opt{'im'} }->getpixel(x => $x, y => $y);
					my ($red, $green, $blue, $alpha) = $c->rgba();
					my $grey = $red*0.3 + $green*0.59 + $blue*0.11;
					push(@pixels, $grey);
			}
	}
	return @pixels;
}

=head1 HASHES

=head2 ahash

  $ihash->ahash();
  $ihash->ahash('geometry' => '8x8');

Calculate the Average Hash
	
Return an array of binary values in array context and a hex representative in scalar context.

=cut
sub ahash {
	my ($self, %opt) = @_;

	$opt{'geometry'} ||= '8x8';
	$opt{'im'} ||= 'im_' . $opt{'geometry'};

	if(!$self->{ $opt{'im'} }) {
		$self->{'reduse'}->($self, %opt );
	}

	my @pixels = $self->{'pixels'}->($self, %opt );
	
	# aHash specific code
	
	# Find the mean values of all the values in the array
	my $m = sum(@pixels)/@pixels; 

	my @binvalue;

	foreach my $p (@pixels) {
		if ($p > $m) {
			push(@binvalue,'1');
		}
		else {
			push(@binvalue,'0');
		}
	}
	
	# Return an array of binary values in array context and a hex representative in scalar context.
	if ( wantarray() ) {
		return @binvalue;
	}
	else {
		return b2h( join('',@binvalue) );
	}

}

=head2 dhash

  $ihash->dhash();
  $ihash->dhash('geometry' => '8x8');

Calculate the Dynamic Hash
	
Return an array of binary values in array context and a hex representative in scalar context.
	
=cut
sub dhash {
	my ($self, %opt) = @_;
	
	$opt{'geometry'} ||= '9x8';
	$opt{'im'} ||= 'im_' . $opt{'geometry'};

	if(!$self->{ $opt{'im'} }) {
		$self->{'reduse'}->($self, %opt );
	}

	my @pixels = $self->{'pixels'}->($self, %opt );
	
	# dHash specific code

	my ($xs, $ys) = split(/x/, $opt{'geometry'});

	my @binvalue;

	for (my $i = 0; $i <= $#pixels; $i++) {

		if(($i % $xs) != $xs -1) {
			if ($pixels[$i] < $pixels[$i+1]) {
				push(@binvalue,'1');
			}
			else {
				push(@binvalue,'0');
			}
		}
	}

	# Return an array of binary values in array context and a hex representative in scalar context.
	if ( wantarray() ) {
		return @binvalue;
	}
	else {
		return b2h( join('',@binvalue) );
	}
}

=head2 phash

  $ihash->phash();
  $ihash->phash('geometry' => '8x8');

Calculate the Perceptual Hash
	
Return an array of binary values in array context and a hex representative in scalar context.

=cut
# Some code taken from http://jax-work-archive.blogspot.no/2013/05/php-ahash-phash-dhash.html
sub getDctConst{  
     
       my @_dctConst;  
       for (my $dctP=0; $dctP<8; $dctP++) {  
           for (my $p=0;$p<32;$p++) {  
               $_dctConst[$dctP][$p] =   
                   cos( ((2*$p + 1)/64) * $dctP * '3.1415926535898' );  
           }  
       }  
  
       return @_dctConst;  
} 

# Some code taken from http://jax-work-archive.blogspot.no/2013/05/php-ahash-phash-dhash.html   
sub phash {
	my ($self, %opt) = @_;

	$opt{'geometry'} ||= '32x32';
	$opt{'im'} ||= 'im_' . $opt{'geometry'};

	if(!$self->{ $opt{'im'} }) {
		$self->{'reduse'}->($self, %opt );
	}

	my @pixels = $self->{'pixels'}->($self, %opt );
	
	# Put the pixel into a multi dimentional array
	my @grays;  
	for (my $y=0; $y<32; $y++){  
	   for (my $x=0; $x<32; $x++){  
		   $grays[$y][$x] = shift @pixels;  
	   }  
	} 
	   
	# pHash specific code
	# DCT 8x8 
	my @dctConst = getDctConst();  
	my $dctSum = 0;  
	my @dcts;  
	for (my $dctY=0; $dctY<8; $dctY++) {  
	   for (my $dctX=0; $dctX<8; $dctX++) {  

		   my $sum = 1;  
		   for (my $y=0;$y<32;$y++) {  
			   for (my $x=0;$x<32;$x++) {  
				   $sum +=   
					   $dctConst[$dctY][$y] *   
					   $dctConst[$dctX][$x] *   
					   $grays[$y][$x];  
			   }  
		   }  

		   # apply coefficients  
		   $sum *= .25;  
		   if ($dctY == 0 || $dctX == 0) {  
			   $sum *= 1/sqrt(2);  
		   }  

		   push(@dcts,$sum);  
		   $dctSum +=  $sum;  
	   }  
	}  

	 
	my $average = $dctSum/64;  

	my @binvalue;
	foreach my $dct (@dcts) {
		push(@binvalue,($dct>=$average) ? '1' : '0');
	}

	# Return an array of binary values in array context and a hex representative in scalar context.
	if ( wantarray() ) {
		return @binvalue;
	}
	else {
		return b2h( join('',@binvalue) );
	}
}

=head1 HELPER

=head2 greytones

  $ihash->greytones();
  $ihash->greytones('geometry' => '8x8');

Return the number of different shades of grey after the image are converted to grey tones. The number of shades can be used to indicate the complexity of an image, and exclude images that has a very low complexity.

For example, all images with only a single color will be reduced to an image with a single grey color and thus give the same hash.

=cut
sub greytones {
	my ($self, %opt) = @_;

	$opt{'geometry'} ||= '8x8';
	$opt{'im'} ||= 'im_' . $opt{'geometry'};

	if(!$self->{ $opt{'im'} }) {
		$self->{'reduse'}->($self, %opt );
	}

	my @pixels = $self->{'pixels'}->($self, %opt );
	
	# aHash specific code
	
	# Find the mean values of all the values in the array
	my $m = sum(@pixels)/@pixels; 

	my %seen;
	my $count = 0;
	foreach my $p (@pixels) {
		if ($seen{$p}) {next;}
		$seen{$p} = 1;
		$count++;

	}
	
	return $count;
}

=head1 DEBUGGING

Functions useful for debug purposes. 

=head2 dump



  my $ihash = Image::Hash->new($image, $module);

  my @hash = $ihash->ahash();
  $ihash->dump('hash' => \@hash );

  
  array(  [ 183 (1), 189 (1), 117 (0),  80 (0), 183 (1), 189 (1), 189 (1), 189 (1) ],
          [ 183 (1), 158 (0),  89 (0), 211 (1),  89 (0), 189 (1), 168 (1), 162 (1) ],
          [ 176 (1), 151 (0),  93 (0), 160 (1), 160 (1), 191 (1), 154 (0), 154 (0) ],
          [ 195 (1), 139 (0),  53 (0), 168 (1),  83 (0), 205 (1), 146 (0), 146 (0) ],
          [ 195 (1), 195 (1), 183 (1), 160 (1), 160 (1), 199 (1), 124 (0), 129 (0) ],
          [ 187 (1), 183 (1), 183 (1), 195 (1), 180 (1), 193 (1), 129 (0), 135 (0) ],
          [ 176 (1), 180 (1), 174 (1), 183 (1), 176 (1), 176 (1), 135 (0), 146 (0) ],
          [ 162 (1), 171 (1),  99 (0), 149 (0), 129 (0), 162 (1), 140 (0), 146 (0) ])

Dump the array used when generating hashes. Option 'hash' may be specified to show with pixel has witch value in the hash.

=cut	  
sub dump {
	my ($self, %opt) = @_;
		
	$opt{'geometry'} ||= '8x8';
	$opt{'im'} ||= 'im_' . $opt{'geometry'};

	if(!$self->{ $opt{'im'} }) {
		$self->{'reduse'}->($self, %opt );
	}

	my @pixels = $self->{'pixels'}->($self, %opt );
	
	# dump specific code
	if ($opt{'hash'} && $opt{'geometry'} ne '8x8') {
		carp("The geometry must be 8x8 when calling dump with a hash to highlight.");
	}

	if (scalar @{ $opt{'hash'} } != 64) {
		carp("'hash' must be a 64 element array.");
	}
	
	my ($xs, $ys) = split(/x/, $opt{'geometry'});

	print "array(\t[ ";
	for (my $i = 0; $i <= $#pixels; $i++) {
		if (($i % $xs) == 0 && $i != 0) {print " ],\n\t[ "} elsif($i != 0) { print ', '; }

		if ($opt{'hash'}) {
			printf("%3s (%1s)", int($pixels[$i]), shift @{ $opt{'hash'} });
		}
		else {
			printf("%3s", int($pixels[$i]));
		}
	}
	print " ])\n";

}

=head2 reducedimage

  use Image::Hash;
  use File::Slurp;

  my $file = shift @ARGV or die("Pleas spesyfi a file to read!");

  my $image = read_file( $file, binmode => ':raw' ) ;

  my $ihash = Image::Hash->new($image);

  binmode STDOUT;
  print STDOUT $ihash->reducedimage();
 
 Returns the reduced image that will be used by the hash functions.
 
=cut
sub reducedimage {
	my ($self, %opt) = @_;

		
	$opt{'geometry'} ||= '8x8';
	$opt{'im'} ||= 'im_' . $opt{'geometry'};


	if(!$self->{ $opt{'im'} }) {
		$self->{'reduse'}->($self, %opt );
	}

	$self->{'blob'}->($self, %opt );
}

=head1 EXAMPLES

Please see the C<eg/> directory for further examples.

=head1 BUGS

Image::Hash support different back ends (GD, Image::Magick or Imager), but because the different back ends work slightly different they will not produce the same hash for the same image. More info is available at https://github.com/runarbu/PerlImageHash/blob/master/Hash_differences.md .

=head1 AUTHOR

    Runar Buvik
    CPAN ID: RUNARB
    runarb@gmail.com
    http://www.runarb.com

=head1 Git

https://github.com/runarbu/PerlImageHash

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Articles L<Looks like it|http://www.hackerfactor.com/blog/index.php?/archives/432-Looks-Like-It.html> and L<Kind of like that|http://www.hackerfactor.com/blog/?/archives/529-Kind-of-Like-That.html> by Neal Krawetz that describes the theory behind aHash, dHash, pHash.

L<ImageHash|https://github.com/JohannesBuchner/imagehash> image hashing library written in Python that dos the same thing.

L<Class ImageHash|http://jax-work-archive.blogspot.no/2013/05/php-ahash-phash-dhash.html> a PHP class that do the same thing.

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

