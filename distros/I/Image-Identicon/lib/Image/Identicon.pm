## ----------------------------------------------------------------------------
#  Image::Identicon.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Image-Identicon/lib/Image/Identicon.pm 344 2007-02-02T16:41:20.275333Z hio  $
# -----------------------------------------------------------------------------
package Image::Identicon;

use strict;
use warnings;

use GD;
BEGIN{ 
	# GD::Polyline raise noisy redefine warning.
	local($^W) = 0;
	require GD::Polyline;
}
use Digest::SHA qw(sha1);

our $VERSION = '0.03';

our $SCALE_LIMIT = 100;
our $SIZE_LIMIT = 300;

our $DEBUG = 0;

1;

# -----------------------------------------------------------------------------
# Image::Indenticon->new(salt=>$salt);
# 
sub new
{
	my $pkg = shift;
	my $opts = @_ && ref($_[0]) ? shift : {@_};
	my $this = {};
	$this->{salt} = $opts->{salt};
	$this->{render} = $opts->{render};
	$this->{salt} or die "no salt";
	bless $this, $pkg;
}

# -----------------------------------------------------------------------------
# my $code = $obj->identicon_code();
# my $code = $obj->identicon_code($addr);
#  calc 32bit identicon code from ip address.
# 
sub identicon_code
{
	my $this = shift;
	my $addr = shift || $ENV{REMOTE_ADDR} || '0.0.0.0';
	
	$this->{salt} or die "isalt must be set prior to retrieving identicon code";
	my @ip = $addr =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
	my $packed = pack("C*", @ip);
	join('.', unpack("C*",$packed)) eq $addr or die "invalid ip addr: $addr";
	
	my $ipint = unpack("N", $packed);
	my $code  = unpack("N", sha1("$ipint+$this->{salt}"));
	$code;
}

# -----------------------------------------------------------------------------
# $obj->decode($code);
#
sub decode
{
	my $this = shift;
	my $code = shift;
	
	#  decode the code into parts
	#
	#  bit 0-1: center patch type
	#  bit 2: center invert
	#  bit 3-6: corner patch type
	#  bit 7: corner invert
	#  bit 8-9: corner turns
	#  bit 10-13: side patch type
	#  bit 14: side invert
	#  bit 15: corner turns
	#  bit 16-20: blue color component
	#  bit 21-26: green color component
	#  bit 27-31: red color component
	my $center_type   =  ($code & 0x3);
	my $center_invert = (($code >>  2) & 0x01) != 0;
	my $corner_type   = (($code >>  3) & 0x0f);
	my $corner_invert = (($code >>  7) & 0x01) != 0;
	my $corner_turn   = (($code >>  8) & 0x03);
	my $side_type     = (($code >> 10) & 0x0f);
	my $side_invert   = (($code >> 14) & 0x01) != 0;
	my $side_turn     = (($code >> 15) & 0x03);
	my $blue  = (($code >> 16) & 0x01f)<<3;
	my $green = (($code >> 21) & 0x01f)<<3;
	my $red   = (($code >> 27) & 0x01f)<<3;
	
	if( $DEBUG )
	{
		print "[decode]\n";
		print "- (center) = ($center_type, -, $center_invert)\n";
		print "- (corner) = ($corner_type, $corner_turn, $corner_invert)\n";
		print "- (side)   = ($side_type, $side_turn, $side_invert)\n";
		print "- (r,g,b)  = ($red, $green, $blue)\n";
	}
	
	my $decode = {
		center_type   => $center_type,
		center_invert => $center_invert,
		corner_type   => $corner_type,
		corner_invert => $corner_invert,
		corner_turn   => $corner_turn,
		side_type     => $side_type,
		side_invert   => $side_invert,
		side_turn     => $side_turn,
		
		red   => $red,
		green => $green,
		blue  => $blue,
	};
	$decode;
}

# -----------------------------------------------------------------------------
# my $result = $obj->identicon_code(\%opts);
#  render image.
#  returns GD::Image through $result->{image}.
# 
sub render
{
	my $this = shift;
	my $opts;
	if( !@_ )
	{
		$opts = {};
	}elsif( ref($_[0]) )
	{
		$opts = shift;
	}elsif( $_[0]=~/^[-a-z]/ )
	{
		$opts = {@_};
	}else
	{
		# deprecated interface: $obj->identicon_code($code);
		$opts->{code}  = shift || $this->identicon_code;
		$opts->{scale} = shift || 10;
	}
	my $code  = $opts->{code};
	my $scale = $opts->{scale};
	my $size  = $opts->{size};
	
	if( !$scale )
	{
		if( !$size )
		{
			$scale = 3;
		}else
		{
			my $patch_size = 5;
			$scale = int($size*4/3/$patch_size);
		}
	}
	$scale >= $SCALE_LIMIT and $scale = $SCALE_LIMIT;
	$size && $size>=$SIZE_LIMIT and $size = $SIZE_LIMIT;
	
	if( $DEBUG )
	{
		$size  ||= '';
		print "[render.prepare]\n";
		print "- size = $size\n";
		print "- scale = $scale\n";
		print "- code = $code\n";
	}
	
	my $decode = $this->decode($code);
	
	# render.
	my $rpkg = $opts->{render} || $this->{render} || 'Image::Identicon::Render';
	my $r = $rpkg->new({
		%$decode,
		code       => $code,
		scale      => $scale,
		size       => $size,
	});
	$r->render();
	$r->_resize();
	
	$r;
}

# -----------------------------------------------------------------------------
# Renderer.
#
package Image::Identicon::Render;

# 5x5 matrix.
#  00 01 02 03 04
#  05 06 07 08 09
#  10 11 12 13 14
#  15 16 17 18 19
#  20 21 22 23 24
our $PATCHES = [
	[ 0, 4, 24, 20, 0,              ], # 0
	[ 0, 4, 20, 0,                  ], # 1
	[ 2, 24, 20, 2,                 ], # 2
	[ 0, 2, 20, 22, 0,              ], # 3
	[ 2, 14, 22, 10, 2,             ], # 4
	[ 0, 14, 24, 22, 0,             ], # 5
	[ 2, 24, 22, 13, 11, 22, 20, 2, ], # 6
	[ 0, 14, 22, 0,                 ], # 7
	[ 6, 8, 18, 16, 6,              ], # 8
	[ 4, 20, 10, 12, 2, 4,          ], # 9
	[ 0, 2, 12, 10, 0,              ], # 10
	[ 10, 14, 22, 10,               ], # 11
	[ 20, 12, 24, 20,               ], # 12
	[ 10, 2, 12, 10,                ], # 12
	[ 0, 2, 10, 0,                  ], # 14
	[ 0, 5, 11, 15, 20, 21, 17, 23, 24, 19, 13, 9, 4, 3, 7, 1, 0], # 15
];

our $PATCH_SYMMETRIC = 1;
our $PATCH_INVERTED  = 2;

our $PATCH_FLAGS = [
  $PATCH_SYMMETRIC, 0, 0, 0,
  $PATCH_SYMMETRIC, 0, 0, 0,
  $PATCH_SYMMETRIC, 0, 0, 0,
  0, 0, 0, $PATCH_SYMMETRIC,
];

our $CENTER_PATCHES = [ 0, 4, 8, 15, ];

our $PATCH_SIZE = 5;

1;

sub _patch_size() { $PATCH_SIZE }

sub new
{
	my $pkg = shift;
	my $opts = shift;
	my $this = bless {%$opts}, $pkg;
	
	$this->{center_type} = $CENTER_PATCHES->[$this->{center_type}&3];
	
	my $scale = $opts->{scale};
	my $patch_size = $pkg->_patch_size;
	my $patch_width = ($patch_size-1) * $scale + 1;
	my $source_size = $patch_width * 3;
	my $image = new GD::Image($source_size, $source_size, 1);
	
	# color components are used at top of the range for color difference
	# use white background for now.
	# TODO: support transparency.
	my ($red, $green, $blue) = @$this{qw(red green blue)};
	my $fore_color = $image->colorAllocate($red, $green, $blue);
	my $back_color = $image->colorAllocate(255,255,255);
	$image->transparent($back_color);

	# outline shapes with a noticeable color (complementary will do) if
	# shape color and background color are too similar (measured by color
	# distance).
	my $stroke_color = undef;
	{
		my $dr = $red-255;
		my $dg = $green-255;
		my $db = $blue-255;
		my $distance = sqrt($dr**2 + $dg**2 + $db**2);
		$DEBUG and print "distance $distance (< 32.0 ?)\n";
		if( $distance < 32.0 )
		{
			$stroke_color = $image->colorAllocate($red^255, $green^255, $blue^255);
		}
	}
	
	$this->{image} = $image;
	$this->{patch_size} = $patch_size;
	$this->{patch_width} = $patch_width;
	$this->{scale}      = $scale;
	$this->{fore_color} = $fore_color;
	$this->{back_color} = $back_color;
	$this->{stroke_color} = $stroke_color;
	$this;
}

sub render
{
	my $r = shift;
	my $center_type   = $r->{center_type};
	my $center_invert = $r->{center_invert};
	my $corner_type   = $r->{corner_type};
	my $corner_invert = $r->{corner_invert};
	my $corner_turn   = $r->{corner_turn};
	my $side_type     = $r->{side_type};
	my $side_invert   = $r->{side_invert};
	my $side_turn     = $r->{side_turn};
	
	# center patch
	$DEBUG and print "[center]\n";
	$r->draw({ x=>1, y=>1, patch=>$center_type, turn=>0, invert=>$center_invert});
	
	# side patchs, starting from top and moving clock-wise
	$DEBUG and print "[sides]\n";
	$r->draw({ x=>1, y=>0, patch=>$side_type, turn=>$side_turn++, invert=>$side_invert});
	$r->draw({ x=>2, y=>1, patch=>$side_type, turn=>$side_turn++, invert=>$side_invert});
	$r->draw({ x=>1, y=>2, patch=>$side_type, turn=>$side_turn++, invert=>$side_invert});
	$r->draw({ x=>0, y=>1, patch=>$side_type, turn=>$side_turn++, invert=>$side_invert});

	# corner patchs, starting from top left and moving clock-wise
	$DEBUG and print "[corneres]\n";
	$r->draw({ x=>0, y=>0, patch=>$corner_type, turn=>$corner_turn++, invert=>$corner_invert});
	$r->draw({ x=>2, y=>0, patch=>$corner_type, turn=>$corner_turn++, invert=>$corner_invert});
	$r->draw({ x=>2, y=>2, patch=>$corner_type, turn=>$corner_turn++, invert=>$corner_invert});
	$r->draw({ x=>0, y=>2, patch=>$corner_type, turn=>$corner_turn++, invert=>$corner_invert});
	
	return $r;
}

sub draw
{
	my $r = shift;
	my $opts = ref($_[0])?shift:{@_};
	
	my $image  = $r->{image};
	my $scale  = $r->{scale};
	my $fore   = $r->{fore_color};
	my $back   = $r->{back_color};
	my $stroke = $r->{stroke_color};
	
	my $patch_size = $r->{patch_size} || $PATCH_SIZE;
	my $width = $r->{patch_width} || ($patch_size-1) * $scale + 1;
	
	my $x = $opts->{x};
	my $y = $opts->{y};
	my $patch  = $opts->{patch};
	my $turn   = $opts->{turn};
	my $invert = $opts->{invert};
	
	$patch>=0 or die "\$patch >= 0 failed, got $patch";
	$turn >=0 or die "\$turn >= 0 failed, got $turn";
	
	$x *= $width;
	$y *= $width;
	$patch %= @$PATCHES;
	$turn %= 4;
	if( ($PATCH_FLAGS->[$patch] & $PATCH_INVERTED) != 0 )
	{
		$invert = !$invert;
	}
	$invert ||= 0;
	$invert and ($fore, $back) = ($back, $fore);

	$DEBUG and print "(x,y) = ($x, $y)\n";
	$DEBUG and print "(patch, turn, invert) = ($patch, $turn, $invert)\n";
	
	# paint background
	$image->filledRectangle($x, $y, $x+$width, $y+$width, $back);
	
	# polything.
	$DEBUG and print "- poly\n";
	my $pl = GD::Polyline->new();
	foreach my $pt (@{$PATCHES->[$patch]})
	{
		my $dx = $pt % $patch_size;
		my $dy = int( $pt / $patch_size );
		
		my $px = int( $dx / ($patch_size-1) * $width );
		my $py = int( $dy / ($patch_size-1) * $width );
		
		$turn==1 and ($px, $py) = ($width-$py, $px);
		$turn==2 and ($px, $py) = ($width-$px, $width-$py);
		$turn==3 and ($px, $py) = ($py, $width-$px);
		
		$pl->addPt($x+$px, $y+$py);
		$DEBUG and print "- ($px, $py) ($dx, $dy, $pt)\n";
	}
	
	# render rotated patch using fore color (back color if inverted)
	$image->filledPolygon($pl, $fore);
	
	# if stroke color was specified, apply stroke
	# stroke color should be specified if fore color is too close to the
	# back color.
	if( $stroke )
	{
		$image->polyline($pl, $stroke);
		$DEBUG and print "- stroke\n";
	}

	$r;
}

sub _resize
{
	my $r = shift;
	my $image = $r->{image};
	my $size  = $r->{size};
	
	if( $size && $image->width!=$size )
	{
		my $orig = $image;
		my $image = GD::Image->new($size, $size, 1);
		$image->copyResampled($orig, 0, 0, 0, 0, $size, $size, $orig->width, $orig->height);
		$image->transparent($r->{back_color});
		if( $DEBUG )
		{
			my $ox = $orig->width;
			my $r = sprintf('%.1f', $ox/$size);
			print "resize: ($ox, $ox) => ($size, $size) [1/$r]\n";
		}
		$r->{image} = $image;
	}
	
	$r;
}

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
  YAMASHINA
  Hio
  ACKNOWLEDGEMENTS
  AnnoCPAN
  CPAN
  RT
  GPL2
  Identicon
  identicon
  IP

=head1 NAME

Image::Identicon - Generate Identicon image


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

  use Image::Identicon;
  my $identicon = Image::Identicon->new(salt=>$salt);
  my $image = $identicon->render(); # or pass 32bit integer.
  
  binmode(*STDOUT);
  print "Content-Type: image/png\r\n\r\n";
  print $image->{image}->png;

=head1 EXPORT

no functions exported.


=head1 METHODS

=head2 $pkg->new({ salt=>$salt })

Create identicon generator.


=head2 $identicon->render(\%opts)

 $opts->{size} - image size (width and height)
 $opts->{code} - 32bit integer code

Create an identicon image.
Returns hashref.
$result->{image} will be GD::Image instance.


=head2 $identicon->identicon_code()

calculate 32bit Identicon code from IP address.


=head2 $identicon->decode($code)

decode patch information from 32bit integer.


=head1 DEPENDENCY

This module uses L<GD> and L<Digest::SHA>.


=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-image-identicon at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-Identicon>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.


    perldoc Image::Identicon

You can also look for information at:


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-Identicon>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-Identicon>


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-Identicon>


=item * Search CPAN

L<http://search.cpan.org/dist/Image-Identicon>


=back

=head1 EXAMPLE

http://clair.hio.jp/~hio/identicon/ 


=head1 ACKNOWLEDGEMENTS

Don Park originally implements identicon.


http://www.docuverse.com/blog/donpark/2007/01/18/visual-security-9-block-ip-identification


=head1 COPYRIGHT & LICENSE

Copyright 2007 YAMASHINA Hio, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


