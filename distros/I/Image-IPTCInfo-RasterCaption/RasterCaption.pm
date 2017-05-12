package Image::IPTCInfo::RasterCaption;

use vars qw/$VERSION/;
$VERSION = 0.1;

=head1 NAME

Image::IPTCInfo::RasterCaption - get/set IPTC raserized caption w/Image::Magick

=head1 SYNOPSIS

	use Image::IPTCInfo::RasterCaption;

	# Access the raw rasterized caption field:
	$info = new Image::IPTCInfo::RasterCaption
		('C:/new_caption.jpg')
		or die "No raster caption!";
	$raw_raster_caption = $info->Attribute('rasterized caption');

	...

=head1 DESCRIPTION

Add to C<Image::IPTCInfo> support for the IPTC IIM4
Dataset 2:125 Rasterized Caption.

This is an alpha-state module that sub-classes Josh Carter's
C<Image::IPTCInfo>, and you should consult the L<Image::IPTCInfo>
for details of how to use it before proceding with this documentation.

This module will loose its alpha status once I've verified
it matches the IPTC standard. If anyone has a rasterized
caption not produced by this module, please send me a copy!

=head1 BACKGROUND

The IPTC is the International Press & Telecommunications Council.
The IIM4 is version four of the Information Interchange Model,
which amongst other things allows the embedding of text (and now
XML) within images (though XML support is not yet provided by
the Perl modules in this namespace).

The IPTC IIM4 specification describes a rasterized caption as
containing "...the rasterized object data description and is used
where characters that have not been coded are required for
the caption."

	Not repeatable, 7360 octets, consisting of binary data,one bit
	per pixel,two value bitmap where 1 (one) represents black and
	0 (zero) represents white.

	     -- IPTC-NAA Information Interchange Model Version No. 4,
	        October 1997, Page 41


=cut

use Image::Magick;
use Image::IPTCInfo;
push @ISA, 'Image::IPTCInfo';

use Carp;
use strict;

# Add the rasterized caption to the Image::IPTCInfo dataset
$Image::IPTCInfo::datasets{125} = 'rasterized caption';
$Image::IPTCInfo::RasterCpation::datasets{125} = 'rasterized caption';


#
# SUB _blank_canvas
# 	Returns a plain white canvas of the standard size
#
sub _blank_canvas {
	my $image = new Image::Magick;
    $image = Image::Magick->new;
    $image->Set(size=>'460x128');
    $image->ReadImage('xc:white');
	return $image;
}


#
# SUB _get_raster_caption
#	ACCEPTS an image magick object and threshold value.
#	RETURNS a scalar representing the bits
#	of a rasterized caption extracted from
#	the field of the same name.
#
sub _get_raster_caption { my ($image,$threshold)=(shift,shift);
	my $iptc='';
	for (my $x=0; $x<460; $x++){
		for (my $y=127; $y>=0; $y--){
			my ($r,$g,$b,$ugh) = split',',$image->Get( "pixel[$x,$y]" );
			if ($r<$threshold){
				$iptc.="1";
				# print "1";
			} else {
				$iptc.="0";
				# print " ";
			}
		}
		# print "\n";
	}
	return pack('B*', $iptc)
}


=head1 METHOD save_raster_caption

Writes to the file specified in the sole argument
the rasterized caption stored in the object's IPTC
field of the same name.

Image creation is via C<Image::Magick> so see L<Image::Magick>
for further details.

On failure returns C<undef>.

On success returns the path written to.

=cut

sub save_raster_caption { my ($self,$path) = (shift, shift);
	croak "No path!" if not $path;
	if (not $self->{_data}->{"rasterized caption"}){
		carp "No rasterized caption data availabel";
		return undef;
	}
	my $image = &_blank_canvas;
	my $rc = unpack( 'B*', $self->{_data}->{"rasterized caption"} );
	my $o=-1; # Offset for reading IPTC field
	for (my $x=0; $x<460; $x++){
		for (my $y=127; $y>=0; $y--){
			++$o;
			if (substr($rc,$o,1)==1){
			   $image->Set("pixel[$x,$y]"=>'black');
			}
		}
	}
	my $err = $image->Write($path);
	if ($err){
		carp "Could not write to file $path: $err / $!";
		return undef;
	}
	return $path;
}



=head1 METHOD load_raster_caption

Sets the IPTC field 'rasterized caption' with
a rasterized version of the image located at
the path specified in the first argument.

If a second argument is provided, it should be
an integer in the range 1-255, representing the
threshold at which source image pixels will be
included in the rasterized monochrome. The default
is 127.

If the image is larger than the standard size,
it will be resized. No attempt is made to maintain
its aspect ratio, though if there is a demand for
this I shall add it.

On failure carps and returns C<undef>.

On success returns a referemce to a scalar containing
the rasterized caption.

=cut

sub load_raster_caption { my ($self,$path,$threshold) = (shift, shift,shift);
	croak "load_raster_caption requires a 'path' paramter" if not $path;
	$threshold = 127 if not defined $threshold;
	croak "Threshold param must be 1-255" if $threshold<1 or $threshold>255;
	my $image = new Image::Magick;
	my $err = $image->Read($path);
	if ($err){
		carp "Could not read file $path: $!";
		return undef;
	}
	$image->Quantize(colorspace=>'gray');
	$image->Set("monochrome"=>1);
	$image->Resize(geometry=>'460x128');
	my $iptc = _get_raster_caption($image,$threshold);
	$self->SetAttribute('rasterized caption',  $iptc);
	return \$iptc;
}




=head1 METHOD set_raster_caption

Fills the rasterized caption with binary data representing
supplied text.

This is very elementry: no font metrics what so ever,
just calls C<Image::Magick>'s C<Annotate>
with the text supplied in the first argument, using the
point size specified in the second argument, and the font
named in the third.

If no size is supplied, defaults to 12 points.

If no font is supplied, then C<arialuni.ttf> is looked
for in the C<fonts> directory beneath the directory specified
in the environment variable C<SYSTEMROOT>. Failing that, the
ImageMagick default is used - YMMV. See the I<Annotate> method
in L<Image::Magick> (C<imagemagick.org>) for details.

On failure carps and returns C<undef>

On success returns a referemce to a scalar containing
the rasterized caption.

=cut

sub set_raster_caption { my ($self,$text,$size,$font) = (@_);
	my $image = &_blank_canvas;
	if (not $font and -e "$ENV{SYSTEMROOT}/Fonts/Arialuni.TTF"){
		$font = "$ENV{SYSTEMROOT}/Fonts/Arialuni.TTF";
	}
	my $err = $image->Annotate(
		font      => $font,
		y			=> 40,
		pointsize => $size || 12,
		fill      => 'black',
		text      => $text
	);
	if ($err){
		carp "Image Magick error: $err";
		return undef;
	}
	my $rc = _get_raster_caption ($image,127);
	$self->SetAttribute('rasterized caption',  $rc);
#	$image->Write('c:/text.jpg');
	return \$rc;
}


1;
__END__

=head1 AUTHOR

Lee Goddard <lgoddard -at- cpan -dot org>.

=head1 COPYRIGHT

This module is Copyright (C) 2003, Lee Goddard.
All Rights Are Reserved.

When included as part of the Standard Version of Perl or as part of its
complete documentation whether printed or otherwise, this work may be
distributed only under the terms of Perl's Artistic License. Any
distribution of this file or derivatives thereof *outside* of that
package requires that special arrangements be made with copyright
holder.

Irrespective of its distribution, all code examples in these files are
hereby placed into the public domain. You are permitted and encouraged
to use this code in your own programs for fun or for profit as you see
fit. A simple comment in the code giving credit would be courteous but
is not required.

=head1 DISCLAIMER

This information is offered in good faith and in the hope that it may be
of use, but is not guaranteed to be correct, up to date, or suitable for
any particular purpose whatsoever. The author accepts no liability in
respect of this module, code, information or its use.



