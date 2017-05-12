package Graphics::DZI::A4;

use warnings;
use strict;

use Moose;
extends 'Graphics::DZI::Files';

our $log;
use Log::Log4perl;
BEGIN {
    $log = Log::Log4perl->get_logger ();
}

=head1 NAME

Graphics::DZI::A4 - DeepZoom Image Pyramid Generation, specifically for documents

=head1 SYNOPSIS

    use Graphics::DZI::A4;
    $Graphics::DZI::log    ->level ($loglevel);
    $Graphics::DZI::A4::log->level ($loglevel);
    my $dzi = new Graphics::DZI::A4 (A4s      => \@images,
				     overlap  => $overlap,
				     tilesize => $tilesize,
                                     path     => './',
                                     prefix   => 'xxx',
				     'format' => $format,
                             );
    use File::Slurp;
    write_file ('xxx.xml', $dzi->descriptor );
    $dzi->iterate ();

=head1 DESCRIPTION

This subclass of L<Graphics::DZI::Files> is specifically though for images covering document
pages. While it is named C<A4>, this is mostly historical; as long as all your images have the same
dimensions, this package should.

The idea is that the whole document (the set of images) forms a large image, the individual images
organized in a square fashion (1x1, 2x2, 4x4, ...). At the highest zoom level of course all pages
will be visible. But if you zoom out, then not only the pages get smaller. Also the pages shown will
be reduced, so that at the smallest zoom level only the first page is visible.

=head1 INTERFACE

=head2 Constructor

Other than the superclass L<Graphics::DZI::Files> this class takes an array (reference) to a list of
images.

=over

=item C<A4s> (no default, list reference)

Do not be fooled by the A4; any format should do.

=back

=cut

use Moose::Util::TypeConstraints qw(enum);
enum 'packing' => qw( exponential linear );

has '+image'    => (isa => 'Image::Magick', required => 0);
has 'A4s'       => (isa => 'ArrayRef',      is => 'ro'    );
has 'W'         => (isa => 'Int'   ,        is => 'rw');
has 'H'         => (isa => 'Int'   ,        is => 'rw');
has 'sqrt'      => (isa => 'Num',           is => 'rw');
has 'pack'      => (isa => 'packing',       is => 'rw', default => 'exponential');

sub BUILD {
    my $self = shift;
    ($self->{W}, $self->{H}) = $self->A4s->[0]->GetAttributes ('width', 'height');     # single A4

    use feature "switch";
    given ($self->{pack}) {
	when ('linear')      {
	    use POSIX;
	    $self->{ sqrt } = POSIX::ceil ( sqrt ( scalar @{$self->A4s}) );     # take the root + 1
	}
	when ('exponential') {
	    use POSIX;
	    my $log2 = POSIX::ceil (log (scalar @{$self->A4s}) / log (2));      # next fitting 2-potenz
	    $log2++ if $log2 % 2;                                                 # we can only use even ones
	    $self->{ sqrt }  = ( 2**($log2/2) );                                  # how many along one edge when we organize them into a square?
	}
	default { die "unhandled packing"; }
    }
    $self->{ image } = _list2huge ($self->sqrt, $self->W, $self->H, @{ $self->A4s }) ;
}

=head2 Methods

=over

=item B<iterate>

This iterate honors the fact that we are dealing with a set of documents, not ONE large image.

=cut

sub _list2huge {
    my $sqrt = shift;
    my ($W, $H) = (shift, shift);

    my $dim = sprintf "%dx%d", map { $_ * $sqrt } ($W, $H);
    $log->debug ("building composite document: DIM $dim ($sqrt)");
    use Image::Magick;
    my $huge = Image::Magick->new ($dim);
    $huge->Read ('xc:white');
    $huge->Transparent (color => 'white');

    foreach my $a (0 .. $sqrt*$sqrt - 1) {
	my ($j, $i) = ( int( $a / $sqrt)  , $a % $sqrt );
	$log->debug ("    index $a (x,y) = $i $j");

	$huge->Composite (image => $_[$a],
			  x     => $i * $W,
			 'y'    => $j * $H,
			  compose => 'Over',
	    );
    }
#    $huge->Display();
    return $huge;
}


sub iterate {
    my $self = shift;

    my $overlap_tilesize = $self->tilesize + 2 * $self->overlap;
    my $border_tilesize  = $self->tilesize +     $self->overlap;

    my ($WIDTH, $HEIGHT) = $self->image->GetAttributes ('width', 'height');
    $log->debug ("total dimension: $WIDTH, $HEIGHT");
    use POSIX;
    my $MAXLEVEL = POSIX::ceil (log ($WIDTH > $HEIGHT ? $WIDTH : $HEIGHT) / log (2));
    $log->debug ("   --> $MAXLEVEL");

    my ($width, $height) = ($WIDTH, $HEIGHT);
    foreach my $level (reverse (0..$MAXLEVEL)) {

	my ($x, $col) = (0, 0);
	while ($x < $width) {
	    my ($y, $row) = (0, 0);
	    my $tile_dx = $x == 0 ? $border_tilesize : $overlap_tilesize;
	    while ($y < $height) {

		my $tile_dy = $y == 0 ? $border_tilesize : $overlap_tilesize;

		my $tile = $self->crop (1, $x, $y, $tile_dx, $tile_dy);         # scale is here always 1
		$self->manifest ($tile, $level, $row, $col);

		$y += ($tile_dy - 2 * $self->overlap);
		$row++;
	    }
	    $x += ($tile_dx - 2 * $self->overlap);
	    $col++;
	}
	($width, $height) = map { int ($_ / 2) } ($width, $height);             # half size, and remember this is A4!

	if ($self->{ sqrt } > 1) {
	    use feature "switch";
	    given ($self->{pack}) {
		when ('linear')      { $self->{ sqrt }--;    }                             # in linear packing we simply reduce the square root by one
		when ('exponential') { $self->{ sqrt } /= 2; }
		default {}
	    }
	    $self->{ image } = _list2huge ($self->sqrt,                                    # pack sqrt x sqrt A4s into one image
					   $self->W, $self->H,
					   @{ $self->A4s });
	}
	$self->image->Resize (width => $width, height => $height);            # at higher levels we need to resize that properly
    }
}

=item B<descriptor>

Also the descriptor generation is a bit special.

=cut

sub descriptor {
    my $self = shift;
    my $overlap  = $self->overlap;
    my $tilesize = $self->tilesize;
    my $format   = $self->format;
    my ($width, $height) = map { $_ * $self->sqrt }  ($self->W, $self->H);
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

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

our $VERSION = '0.02';

"against all odds";
