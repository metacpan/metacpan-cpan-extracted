package Gimp::Util;

use Exporter 'import';
use strict;
use warnings;
use File::Basename;
Gimp->import;
our @EXPORT_OK = qw(
  layer_create
  text_draw
  image_create_text
  layer_add_layer_as_mask
);

sub __ ($); # declare - defined in Gimp

our $VERSION = "2.38";

sub get_state() {
   [
    Palette->get_foreground,
    Palette->get_background,
    Gradients->get_gradient,
    scalar Patterns->get_pattern,
    scalar Brushes->get_brush,
   ]
}

sub set_state($) {
   my $s = shift;
   Palette->set_foreground($s->[0]);
   Palette->set_background($s->[1]);
   Gradients->set_gradient($s->[2]);
   Patterns->set_pattern($s->[3]);
   Brushes->set_brush($s->[4]);
}

# [12/23/98] v0.0.1 Tels - First version
sub layer_create {
  my ($image,$name,$color,$pos) = @_;
  my $layer;
  my $tcol; # scratch color

  # create a colored layer
  $layer = Gimp::Layer->new ($image,Gimp->image_width($image),
                           Gimp->image_height($image),
                           &RGB_IMAGE,$name,100,&LAYER_MODE_NORMAL_LEGACY);
  $tcol = Gimp->palette_get_background ();
  Gimp->palette_set_background ($color);
  Gimp->drawable_fill ($layer,&FILL_BACKGROUND);
  Gimp->image_insert_layer($image, $layer, 0, $pos);
  Gimp->palette_set_background ($tcol); # reset
  $layer;
  }

# [12/23/98] v0.0.1 Tels - First version
sub text_draw {
  my ($image,$layer,$text,$font,$size,$fgcolor) = @_;
  my ($bg_layer,$text_layer);
  my $tcol; # temp. color

  warn __"text string is empty" if $text eq "";
  warn __"no font specified, using default" if $font eq "";
#FIXME: The following line always sets font to Helvetica if uncommented.
#  $font = "Helvetica" if ($font eq "");

  $tcol = Gimp->palette_get_foreground ();
  Gimp->palette_set_foreground ($fgcolor);
  # Create a layer for the text.
  $text_layer = Gimp->text($image,-1,0,0,$text,10,1,$size,
			    &PIXELS,"*",$font,"*","*","*","*");

  # Do the fun stuff with the text.
  Gimp->layer_set_preserve_trans($text_layer, &FALSE);

  # add text to image
  $image->insert_layer($text_layer, 0, 0);
  # merge white and text
  Gimp->image_merge_visible_layers ($image,1);
  # cleanup the left over layer (!)
  Gimp->layer_delete($text_layer);
  $layer;
}

sub image_create_text {
  my ($text,$font,$size,$fgcolor,$bgcolor) = @_;
  my $tcol; # temp. color
  my $text_layer;
  my $bg_layer;
  my $image;

  warn (__"text string is empty") if ($text eq "");
  warn (__"no font specified, using default") if ($font eq "");
#FIXME: The following line always sets font to Helvetica if uncommented.
# This was preventing use of different fonts in gimp_text_fontname() calls.
#  $font = "Helvetica" if ($font eq "");
  # create an image. We'll just set whatever size here because we want
  # to resize the image when we figure out how big the text is.
  $image = Gimp::Image->new(64,64,&RGB); # don't waste too much  resources ;-/

  $tcol = Gimp->palette_get_foreground ();
  Gimp->palette_set_foreground ($fgcolor);
  # Create a layer for the text.
  $text_layer = Gimp->text($image,-1,0,0,$text,10,1,$size,
                          &PIXELS,"*",$font,"*","*","*","*","*","*");
  Gimp->palette_set_foreground ($tcol);

  Gimp->layer_set_preserve_trans($text_layer, &FALSE);

  # Resize the image based on size of text.
  Gimp->image_resize($image,Gimp->drawable_width($text_layer),
                    Gimp->drawable_height($text_layer),0,0);

  # create background and merge them
  $bg_layer = Gimp->layer_create ($image,"text",$bgcolor,1);
  Gimp->image_merge_visible_layers ($image,1);

  # return
  $image;
  }

sub layer_add_layer_as_mask {
  my ($image,$layer,$layer_mask) = @_;
  my $mask;

  Gimp->selection_all ($image);
  $layer_mask->edit_copy ();
  Gimp->layer_add_alpha ($layer);
  $mask = Gimp->layer_create_mask ($layer,0);
  $mask->edit_paste (0);
  Gimp->floating_sel_anchor(Gimp->image_floating_selection($image));
  Gimp->image_add_layer_mask ($image,$layer,$mask);
  $mask;
  }

sub gimp_image_layertype {
   my($type,$alpha) = ($_[0]->base_type,$_[1]);
   $type == &RGB     ? $alpha ? &RGBA_IMAGE     : &RGB_IMAGE     :
   $type == &GRAY    ? $alpha ? &GRAYA_IMAGE    : &GRAY_IMAGE    :
   $type == &INDEXED ? $alpha ? &INDEXEDA_IMAGE : &INDEXED_IMAGE :
   die;
}

sub gimp_layer2imagetype {
   my $type = shift;
   $type == &RGB_IMAGE		? &RGB		:
   $type == &RGBA_IMAGE		? &RGB		:
   $type == &GRAY_IMAGE		? &GRAY		:
   $type == &GRAYA_IMAGE	? &GRAY		:
   $type == &INDEXED_IMAGE	? &INDEXED	:
   $type == &INDEXEDA_IMAGE	? &INDEXED	:
   die;
}

sub gimp_image_add_new_layer {
   my ($image,$index,$filltype,$alpha)=@_;
   my $layer = Gimp::Layer->new(
      $image, $image->width, $image->height,
      $image->layertype (defined $alpha ? $alpha : 1),
      join(':', map { basename($_) } (caller 2)[1,2]),
      100, &LAYER_MODE_NORMAL_LEGACY
   );
   $layer->fill (defined $filltype ? $filltype : &FILL_BACKGROUND);
   $image->insert_layer ($layer, 0, $index*1);
   $layer;
}

sub gimp_image_set_visible {
   my $image = shift;
   my %layers; @layers{map $$_,@_}=(1) x @_;
   for ($image->get_layers) {
      $_->set_visible ($layers{$$_} // 0);
   }
}

sub gimp_image_set_invisible {
   my $image = shift;
   my %layers; @layers{map $$_,@_}=(1) x @_;
   for ($image->get_layers) {
      $_->set_visible (!$layers{$$_} // 0);
   }
}

1;
__END__
=head1 NAME

Gimp::Util - Handy routines for Gimp-Perl users

=head1 SYNOPSIS

 use Gimp;
 use Gimp::Util;

=head1 DESCRIPTION

Gimp-Perl is nice, but when you have to write everytime 10 lines just to
get some simple functions done, it very quickly becomes tedious :-/

This module tries to define some functions that aim to automate frequently
used tasks, i.e. its a sort of catch-all-bag for (possibly) useful macro
functions.  If you want to add a function just mail the author of the
Gimp-Perl extension (see below).

In Gimp-Perl (but not in Gimp as seen by the enduser) it is possible to
have layers that are NOT attached to an image. This is, IMHO a bad idea,
you end up with them and the user cannot see them or delete them. So we
always attach our created layers to an image here, too avoid memory leaks
and debugging times.

These functions try to preserve the current settings like colors, but not
all do.

These functions can also be handled in exactly the same way as
PDB-Functions, i.e. the (hypothetical) function C<gimp_image_xyzzy> can be
called as $image->xyzzy, if the module is available.

The need to explicitly C<use Gimp::Util> will go away in the future.

=head1 FUNCTIONS

=over 4

=item C<get_state ()>, C<set_state state>

C<get_state> returns a scalar representing most of gimps global state
(at the moment foreground colour, background colour, active gradient,
pattern and brush). The state can later be restored by a call to
C<set_state>. This is ideal for library functions such as the ones used
here, at least when it includes more state in the future.

=item C<layer_create image,name,color,pos>

create a colored layer, insert into image and return layer

=item C<text_draw image,layer,text,font,size,fgcolor>

Create a colored text, draw over a background, add to img, ret img.

=item C<image_create_text text,font,size,fgcolor,bgcolor>

Create an image, add colored text layer on a background layer, return img.

=item C<layer_add_layer_as_mask image,layer,layermask>

Take a layer and add it as a mask to another layer, return mask.

=item C<gimp_image_layertype $alpha>

returns the corresponding layer type for an image, alpha controls wether the layer type
is with alpha or not. Example: imagetype: RGB -> RGB_IMAGE (or RGBA_IMAGE).

=item C<gimp_layer2imagetype $layertype>

returns the corresponding layer type for an image, alpha controls wether the layer type
is with alpha or not. Example: imagetype: RGB -> RGB_IMAGE (or RGBA_IMAGE).

=item C<$image-E<gt>add_new_layer($index,$fill_type,$alpha)>

creates a new layer and adds it at position $index (default 0) to the
image, after filling it with gimp_drawable_fill $fill_type (default
BG_IMAGE_FILL). If $alpha is non-zero (default 1), the new layer has
alpha. Makes up a name based on the 2nd-level caller filename and line.

=item C<$image-E<gt>set_visible(@layers)>, C<$image-E<gt>set_invisible(@layers)>

mark the given layers visible (invisible) and all others invisible (visible).

=back

=head1 AUTHOR

Various, version 1.000 written mainly by Tels (http://bloodgate.com/). The
author of the Gimp-Perl extension (contact him to include new functions)
is Marc Lehmann <pcg@goof.com>

