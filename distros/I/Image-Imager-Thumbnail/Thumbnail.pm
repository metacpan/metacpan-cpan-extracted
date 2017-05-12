package Image::Imager::Thumbnail;

use strict;
use warnings;
our $VERSION = '0.01';

=head1 NAME

Image::Imager::Thumbnail - Produces thumbnail images with Imager

=head1 SYNOPSIS

	use Image::Imager::Thumbnail;
	my $tb = new	Image::Imager::Thumbnail (
		file_src  => $src,
		file_dst  => $dst,
		width     => $w,
		height    => $h
	);
	$tb->save;
	
	
	__END__

=head1 DESCRIPTION

This module uses the Imager library to create a thumbnail image with no side bigger than you specify.


=cut

=head1 PREREQUISITES

	Imager

=cut

use Imager;

my %fields =
    (
     file_src               => '',
     file_dst               => '',
     height             => 0,
     width	             => 0,
     );


sub new {
	my ($proto,%options) = @_;
	my $class = ref($proto) || $proto;
	my $self = {%fields};
	bless $self, $class;
	while (my ($key,$value) = each(%options)) {
		if (exists($fields{$key})) {
			$self->{$key} = $value;
		} else {
			die __PACKAGE__ . "::new: invalid option '$key'\n";
		}
	}
	return $self;
}

sub save {
	my $self				= shift;
	my $type				= shift || 'jpeg';
	my $ret;
	my $height_d 			= $self->{height};
	my $width_d 			= $self->{width};
	my $srcImage 				= Imager->new();
	unless ($srcImage->open(file=>$self->{file_src})) {
		my $errImage		= Imager->new(xsize=>600, ysize=>15,
												 channels=>3, bits=>16);
		
		#$white = $errImage->colorAllocate(255,255,0);	
		my $red = Imager::Color->new( 255, 0, 0 );
		#$red = $errImage->colorAllocate(255,0,0);
		#$errImage->string(gdSmallFont,0,0,"Unable to find " . $self->{file},$red);
		$errImage->string(text=>"Ciao", x=>0,y=>0,size=>10,color=>$red);
		$errImage->write(data => \$ret, type => $type) or die $errImage->errstr;
		return $ret;
	}
		
	my ($width_s,$height_s) = ($srcImage->getwidth,$srcImage->getheight);
	if ($height_d == 0) {
		my $ratio = $width_d/$width_s;
		$height_d = $height_s * $ratio;
	} elsif ($width_d == 0) {
		my $ratio = $height_d/$height_s;
		$width_d = $width_s * $ratio;
	}
	my $dstImage			= $srcImage->scaleX(pixels=>$width_d)->scaleY(pixels=>$height_d);
	my %opts;
	if ($type eq 'gif') {
		$opts{interlace} = 1;
	}
	$dstImage->write(file => $self->{file_dst}, type => $type,%opts) or die $dstImage->errstr;
	# salvo in cache;
}

sub width {
	my $self 	= shift;
  return @_ ? $self->{width} = shift : $self->{width};
}

sub height {
	my $self 	= shift;
  return @_ ? $self->{height} = shift : $self->{height};
}

sub file_src {
	my $self 	= shift;
  return @_ ? $self->{file_src} = shift : $self->{file_src};
}
sub file_dst {
	my $self 	= shift;
  return @_ ? $self->{file_dst} = shift : $self->{file_dst};
}
1;
