package Graphics::DZI;

use strict;
use warnings;
use POSIX;

use Moose;

our $log;
use Log::Log4perl;
BEGIN {
    $log = Log::Log4perl->get_logger ();
}

=head1 NAME

Graphics::DZI - DeepZoom Image Pyramid Generation

=head1 SYNOPSIS

  use Graphics::DZI;
  my $dzi = Graphics::DZI     (image    => $image,
                               overlap  => $overlap,
                               tilesize => $tilesize,
                               format   => $format,
                               );

  write_file ('/var/www/xxx.xml', $dzi->descriptor);
  $dzi->iterate ();
  # !!! this does only display the tiles on the screen
  # !!! see Graphics::DZI::Files for a subclass which 
  # !!! actually writes to files

=head1 DESCRIPTION

This base package generates tiles from a given image in such a way that they follow the DeepZoom
image pyramid scheme. Consequently this image becomes zoomable with tools like Seadragon.

  http://en.wikipedia.org/wiki/Deep_Zoom

As this is a base class, you may want to look either at the I<deepzoom> script which operators on
the command line, or at one of the subclasses.

=head1 INTERFACE

=head2 Constructor

The constructor accepts the following fields:

=over

=item C<image>

The L<Image::Magick> object which is used as canvas.

(since 0.05)

The image can also be a whole stack (L<Image::Magick> allows you to do that). In that case the
bottom image is regarded as the one with the I<highest> degree of detail, and that is tiled first
(at the higher resolutions). Images up the stack are then taken in turn, until only the top-level
image remains. See C<pop> if you want to influence this policy.

=item C<scale> (integer, default: 1)

Specifies how much the image is stretched in the process.

=item C<overlap> (integer, default: 4)

Specifies how much the individual tiles overlap.

=item C<tilesize> (integer, default: 128)

Specifies the quadratic size of each tile.

=item C<overlays> (list reference, default: [])

An array of L<Graphics::DZI::Overlay> objects which describe how further images are supposed to be
composed onto the canvas image.

=back

=cut

has 'image'    => (isa => 'Image::Magick', is => 'rw', required => 1);
has 'scale'    => (isa => 'Int',           is => 'ro', default => 1);
has 'overlap'  => (isa => 'Int',           is => 'ro', default => 4);
has 'tilesize' => (isa => 'Int',           is => 'ro', default => 256);
has 'format'   => (isa => 'Str'   ,        is => 'ro', default => 'png');
has 'overlays' => (isa => 'ArrayRef',      is => 'rw', default => sub { [] });

=head2 Methods

=over

=item B<crop>

I<$tile> = I<$dzi>->crop (I<$scale>, I<$x>, I<$y>, I<$dx>, I<$dy>)

Given the dimensions of a tile and a current (not the original)
stretch factor this method will return a tile object.

=cut

sub crop {
    my $self = shift;
    my $scale = shift;
    my ($tx, $ty, $tdx, $tdy) = @_;

    my $tile  = $self->{image}->[-1]->clone;                                                 # always take the "last" (lowest) image
    if ($scale != 1) {                                                                       # if our image is not quite the total space
#	warn "new canvas tile scaled $scale";
	my ($htx, $hty, $htdx, $htdy) = map { int ($_ / $scale) }
	                                ($tx, $ty, $tdx, $tdy);                              # rescale this tile to the image dims we have
	$log->debug ("rescale $tx, $ty  -->  $htx, $hty");
	$tile->Crop   (geometry => "${htdx}x${htdy}+${htx}+${hty}");                         # cut that smaller one out
	$tile->Resize ("${tdx}x${tdy}");                                                     # and make it bigger
    } else {                                                                                 # otherwise we are happy with what we have, dimension-wise
#	warn "new canvas tile unscaled";
	$tile->Crop (geometry => "${tdx}x${tdy}+${tx}+${ty}");                               # cut one out
    }
    $log->debug ("tiled ${tdx}x${tdy}+${tx}+${ty}");
#    $tile->Display();
    return $tile;
}

=item B<dimensions>

(I<$W>, I<$H>) = I<$dzi>->dimensions ('total')

(I<$W>, I<$H>) = I<$dzi>->dimensions ('canvas')

This method computes how large (in pixels) the overall image will be. If C<canvas> is passed in,
then any overlays are ignored. Otherwise their size (with their squeeze factors) are used to blow up
the canvas, so that the overlays fit onto the canvas.

=cut

sub dimensions {
    my $self = shift;
    my $what = shift || 'total';

    my ($W, $H);
    if ($what eq 'total') {
	use List::Util qw(max);
	my $max_squeeze = max map { $_->squeeze } @{ $self->overlays };
	$self->{scale} = defined $max_squeeze ? $max_squeeze : 1;
	($W, $H) = map { $_ * $self->{scale} } $self->image->GetAttributes ('width', 'height');
    } else {
	($W, $H) = $self->image->GetAttributes ('width', 'height');
    }
    use POSIX;
    my $level = POSIX::ceil (log ($W > $H ? $W : $H) / log (2));
    $log->debug (" dimensions: $W, $H  --> levels: $level");
    return ($W, $H, $level);
}

=item B<iterate>

I<$dzi>->iterate

This method will generate all necessary tiles, invoking the I<manifest> method. You may want to
override that one, if you do not want the tiles to be simply displayed on screen :-) Any options
you add as parameters will be passed on to I<manifest>.

B<NOTE>: During the process the image  will be modified!

=cut

sub iterate {
    my $self = shift;

    my $overlap_tilesize = $self->{tilesize} + 2 * $self->{overlap};
    my $border_tilesize  = $self->{tilesize} +     $self->{overlap};

    my ($CWIDTH, $CHEIGHT, $CANVAS_LEVEL) = $self->dimensions ('canvas');
    my ($WIDTH,  $HEIGHT,  $MAXLEVEL)     = $self->dimensions ('total');

    my ($width, $height) = ($WIDTH, $HEIGHT);
    my $scale = $self->{scale};
    foreach my $level (reverse (0..$MAXLEVEL)) {

	my ($x, $col) = (0, 0);
	while ($x < $width) {
	    my ($y, $row) = (0, 0);
	    my $tile_dx = $x == 0 ? $border_tilesize : $overlap_tilesize;
	    while ($y < $height) {

		my $tile_dy = $y == 0 ? $border_tilesize : $overlap_tilesize;

		my @tiles = grep { defined $_ }                                                # only where there was some intersection
                            map {
				$_->crop ($x, $y, $tile_dx, $tile_dy);                         # and for each overlay crop it onto a tile
			    } @{ $self->overlays };                                            # look at all overlays

		if (@tiles) {                                                                  # if there is at least one overlay tile
		    my $tile = $self->crop ($scale, $x, $y, $tile_dx, $tile_dy);               # do a crop in the canvas and try to get a tile
		    map {
			$tile->Composite (image => $_, x => 0, 'y' => 0, compose => 'Over')
		    } @tiles;
		    $self->manifest ($tile, $level, $row, $col);                               # we flush it

		} elsif ($level <= $CANVAS_LEVEL) {                                            # only if we are in the same granularity of the canvas
		    my $tile = $self->crop ($scale, $x, $y, $tile_dx, $tile_dy);               # do a crop there and try to get a tile
#warn "tile ";		    $tile->Display();
		    $self->manifest ($tile, $level, $row, $col);                               # we flush it
		}

		$y += ($tile_dy - 2 * $self->{overlap});                                       # progress y forward
		$row++;                                                                        # also the row count
	    }
	    $x += ($tile_dx - 2 * $self->{overlap});                                           # progress x forward
	    $col++;                                                                            # the col count
	}

#-- resizing canvas
	($width, $height) = map { POSIX::ceil ($_ / 2) } ($width, $height);
	if (@{ $self->overlays }) {                                                            # do we have overlays from which the scale came?
	    $scale /= 2;                                                                       # the overall magnification is to be reduced
	    foreach my $o (@{ $self->overlays }) {                                             # also resize all overlays
		$o->halfsize;
	    }
	} else {
	    # keep scale == 1
	    $self->{image}->Resize (width => $width, height => $height);                       # resize the canvas for next iteration
	}
	$self->pop;                                                                            # for multi-level images
    }
}

=pod

=item B<pop>

(since 0.05)

This method is only interesting to you if your canvas images is a whole stack, not just a single
image. In that case, it will remove the first of the stack (a shift) to make the next in the line
visible to the further tiling process. As the tiling starts with the highest resolution, your image
stack should be organized that the one with the most details is on the bottom (highest index, pushed
last).

This method will do a C<pop> B<at every> half-sizing step and obviously only that long as there is
something to shift. If you are not happy with this default policy, you will have to subclass.

=cut

sub pop {
    my $self = shift;
    pop @{ $self->image } if scalar @{ $self->image } > 1;                                   # if we have a stack of images, remove that with the most details (i.e. first)
}

=item B<manifest>

I<$dzi>->manifest (I<$tile>, I<$level>, I<$row>, I<$col>)

This method will get one tile as parameter and will simply display the tile on the screen.
Subclasses which want to persist the tiles, can use the additional parameters (level, row and
column) to create file names.

=cut

sub manifest {
    my $self = shift;
    my $tile = shift;
    $tile->Display();
}

=item B<descriptor>

I<$string> = I<$dzi>->descriptor

This method returns the DZI XML descriptor as string.

=cut

sub descriptor {
    my $self     = shift;
    my $overlap  = $self->{overlap};
    my $tilesize = $self->{tilesize};
    my $format   = $self->{format};
    my ($width, $height) = $self->dimensions ('total');
    return qq{<?xml version='1.0' encoding='UTF-8'?>
<Image TileSize='$tilesize'
       Overlap='$overlap'
       Format='$format'
       xmlns='http://schemas.microsoft.com/deepzoom/2008'>
    <Size Width='$width' Height='$height'/>
</Image>
};


}

=back

=head1 TODOs

See the TODOs file in the distribution.

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = '0.05';

"against all odds";
