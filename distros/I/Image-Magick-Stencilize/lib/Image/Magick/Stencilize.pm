package Image::Magick::Stencilize;
use strict;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

#use Exporter;
#use vars qw(@ISA @EXPORT);
#@ISA = qw/Exporter/;
#@EXPORT = 'Stencilize';
#use Smart::Comments '###';

#Imaeg

#$Image::Magick::

# in the tradition of image magick names:

no strict 'refs';
*Image::Magick::Stencilize = \&Stencilize;

sub Stencilize {
   my $self = shift; # image magick object
   my $threshold = shift;
   $threshold ||= 40;
   my $blur_percentage = shift;
   $blur_percentage||= 4;
   $blur_percentage > 0 and $blur_percentage < 100 or die('blur percentage must be over 0 and under 100');
   
   $blur_percentage = ($blur_percentage / 100 );
   ### $blur_percentage 

   if ($threshold > 75 or $threshold < 15){
      warn("threshold is set at $threshold, that will likely produce no results, should be between 15 and 75");
   }
   $threshold = ( $threshold * 1000 );
   
   # i guess ideally return same size

   # resize by 50%
   my($h,$w)=$self->Get('height','width');
   my($_h,$_w) = (int ($h * 2), int ($w * 2));

   

   

   my $blur = int($blur_percentage * ((($_h + $_w)/2)/3) );
   ### $blur
   $blur||=1;

   $self->Resize( geometry => $_w.'x'.$_h,);#blur => 1.3);#blur => 1.2 );
   $self->Blur( geometry => $blur.'x'.$blur );
   $self->Set( colorspace => 'rgb' );
   #$self->Equalize;

   
   $self->Threshold( threshold => $threshold );

   #$self->Set( colorspace => 'gray' );

   #$self->Normalize;
   #$self->Negate;
   #$self->Threshold( threshold => 0 );
   #$self->Negate;

   
   $self->Resize( geometry => $w.'x'.$h, blur => 1);

   return;
}



1;


__END__

=pod

=head1 NAME

Image::Magick::Stencilize

=head1 SYNOPSIS

   use Image::Magick;
   use Image::Magick::Stencilize;

   my $image = new Image::Magick;
   $image->Read('./image.jpg');
   $image->Stencilize;
   $image->Write('./image_stencilized.jpg');
   
=head1 DESCRIPTION

Adds method to Image::Magick namespace to make an image you can make a silk-screen out of.
Makes the image black and white.
If you do graphic design or like Andy Warhol, this may be for you.

=head1 Stencilize()

optional arguments are threshold (15-75) and blur percentage (0-100)
defaults are thrshold 40 and blur percentage 4

=head1 AUTHOR

Leo Charre

=cut
