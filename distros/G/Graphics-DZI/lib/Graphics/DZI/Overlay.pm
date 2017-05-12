package Graphics::DZI::Overlay;

use strict;
use warnings;

use Moose;

our $log;
use Log::Log4perl;
BEGIN {
    $log = Log::Log4perl->get_logger ();
}

=head1 NAME

Graphics::DZI::Overlay - DeepZoom Image Pyramid, Sparse Images

=head1 SYNOPSIS

  # build some overlays first
  use Graphics::DZI::Overlay;
  my $o1 = new Graphics::DZI::Overlay (image => ...,       # what is the image?
                                       x => 1000, y=>1000, # where on the canvas?
                                       squeeze => 64);     # how much smaller than the canvas?
  my $o2 = new Graphics::DZI::Overlay (image => ...,       # what is the image?
                                       x => 2000, y=>2000, # where on the canvas?
                                       squeeze => 32);     # how much smaller than the canvas?
  # then add the overlay over the canvas
  use Graphics::DZI::Files;
  my $dzi = new Graphics::DZI::Files (image    => $image,
                                      overlap  => 4,
                                      tilesize => 512,
                                      format   => 'png',
                                      overlays => [ $o1, $o2],
                                      path     => $path . 'xxx_files/',
                                      prefix   => 'xxx',
                                      );
   # normal DZI generation
   write_file ($path . 'xxx.xml', $dzi->descriptor);
   $dzi->iterate ();

=head1 DESCRIPTION

This package can hold one overlay image, together with a coordinate and a factor how much this
images is smaller than the canvas onto which the image is to be put.

=head1 INTERFACE

=head2 Constructor

It expects the following fields:

=over

=item C<image>: (required)

L<Image::Magick> object.

=item C<x>,C<y>: (integers, no default)

Coordinates of the top-left corner of the above image on the canvas 

=item C<squeeze>: (integers, no default)

A factor how much the image should be made smaller, relative to the canvas. I use a power of two to
avoid that the canvas is a bit fuzzy.

=back

=cut

has 'image'   => (isa => 'Image::Magick', is => 'rw', required => 1);
has 'x'       => (isa => 'Int', is => 'rw');
has 'y'       => (isa => 'Int', is => 'rw');
has 'squeeze' => (isa => 'Num', is => 'rw');

=head2 Methods

=over

=item B<halfsize>

Makes the overlay smaller by 2. This will be called by the DZI algorithm.

=cut

sub halfsize {
    my $self = shift;
    my ($w, $h) = $self->image->GetAttributes ('width', 'height');                     # current dimensions
    $self->image->Resize (width => int($w/2), height => int($h/2));                    # half size
    $self->{x} /= 2;                                                                   # dont forget x, y 
    $self->{y} /= 2;
}

=item B<crop>

Gets a tile off the overlay.

=cut

sub crop {
    my $self = shift;
    my ($tx, $ty, $tdx, $tdy) = @_;

    my ($w, $h) = $self->{image}->GetAttributes ('width', 'height');
    $self->{dx} = $w;
    $self->{dy} = $h;

#    warn "before intersection tile $tile"; $tile->Display() if $tile;
    if (my $r = _intersection ($tx,        $ty,        $tx+$tdx,                 $ty+$tdy,                   # tile and overlay intersect?
			       $self->{x}, $self->{y}, $self->{x} + $self->{dx}, $self->{y} +$self->{dy})) {
#	    warn " intersection!";
	my ($ox, $oy, $dx, $dy) = (
	    $r->[0] - $self->{x},                                                      # x relative to overlay
	    $r->[1] - $self->{y},                                                      # y relative to overlay

	    $r->[2] - $r->[0],                                                         # width of the intersection
	    $r->[3] - $r->[1],                                                         # height
	    );

	my $oc = $self->{image}->clone;
#	warn "overlay clone "; $oc->Display();
	$oc->Crop (geometry => "${dx}x${dy}+${ox}+${oy}");
#	warn "cropped oc";   $oc->Display();

#	unless ($tile) {                                                               # this just makes sure that we are composing onto SOMETHING
##	    warn "XXXXXXXXX generating substitute tile";
	my $tile = Image::Magick->new ("${tdx}x${tdy}");                               # create an empty one
	$tile->Read ('xc:yellow');                                                 # paint it white (otherwise composite would not work?)
	$tile->Transparent (color => 'yellow');
#	warn "substitute tile "; $tile->Display();
#	}
#	warn "before overlay tile "; $tile->Display();
	$tile->Composite (image => $oc,
			  x     => $r->[0] - $tx,                                      # intersection left/top relative to tile
			  'y'   => $r->[1] - $ty,
			  compose => 'Over',
		);
#	warn "after overlay tile "; $tile->Display();
	return $tile;
    }
    return undef;
}

sub _intersection {
    my ($ax, $ay, $axx, $ayy,
	$bx, $by, $bxx, $byy) = @_;

    if (_intersects ($ax, $ay, $axx, $ayy,
		     $bx, $by, $bxx, $byy)) {
	return [
	    $ax  > $bx  ? $ax  : $bx,
	    $ay  > $by  ? $ay  : $by,
	    $axx > $bxx ? $bxx : $axx,
	    $ayy > $byy ? $byy : $ayy
	    ];
    }
}

sub _intersects {
    my ($ax, $ay, $axx, $ayy,
	$bx, $by, $bxx, $byy) = @_;

    return undef
	if $axx < $bx
	|| $bxx < $ax
	|| $ayy < $by
	|| $byy < $ay;
    return 1;
}

=back

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = '0.01';

"against all odds";

