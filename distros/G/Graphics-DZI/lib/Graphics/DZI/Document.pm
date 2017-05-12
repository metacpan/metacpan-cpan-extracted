package Graphics::DZI::Document;

use strict;
use warnings;

our $log;
use Log::Log4perl;
BEGIN {
    $log = Log::Log4perl->get_logger ();
}

=head1 NAME

Graphics::DZI::Document - DeepZoom Image Pyramid, Sparse Document Images

=head1 SYNOPSIS

    # prepare a bunch of Image::Magick objects
    @pages = ......;

    # create the overlay itself
    use Graphics::DZI::Document;
    my $o = new Graphics::DZI::Document (pages => \@pages,
					 x => 80000, 'y' => 40000,
					 pack => 'linear',
					 squeeze => 256);

    # use the Graphics::DZI::Files and add this as overlay

=head1 DESCRIPTION

This subclass of L<Graphics::DZI::Overlay> handles documents as overlays for extremely sparse
DeepZoom images. Documents here are also images, but not a single one, but one for each document
page.

What is also different from a normal overlay image is that document overlays will show a different
number of images, depending on the zoom level. First, when the canvas is the dominant feature, only
a small first page is show. Whenever that first page is fairly readable, the first 4 pages are shown
in the slot. Then the next 9 or 16, depending on whether the growth is C<linear> or C<exponential>.

=cut

use Moose;
extends 'Graphics::DZI::Overlay';

=head1 INTERFACE

=head2 Constructor

Different to the superclass not the image, but a sequence of pages have to be passed in. Optionally,
a parameter C<pack> determines between C<linear> and C<exponential> growth of pages at higher
resolutions. With linear you actually get 1, 4, 9, 16, 25...  documents (so it is actually squared
linear). With exponential you get more aggressively 1, 4, 16, 32, ... pages.

=cut

use Moose::Util::TypeConstraints qw(enum);
enum 'packing' => qw( exponential linear );

has 'pages'     => (isa => 'ArrayRef',       is => 'rw', required => 1);
has '+image'    => (isa => 'Image::Magick',              required => 0);
has 'W'         => (isa => 'Int'   ,        is => 'rw');
has 'H'         => (isa => 'Int'   ,        is => 'rw');
has 'sqrt'      => (isa => 'Num',           is => 'rw');
has 'pack'      => (isa => 'packing',       is => 'rw', default => 'exponential');

sub BUILD {
    my $self = shift;
    ($self->{W}, $self->{H}) = $self->pages->[0]->GetAttributes ('width', 'height');     # single document

    use feature "switch";
    given ($self->{pack}) {
	when ('linear')      {
	    use POSIX;
	    $self->{ sqrt } = POSIX::ceil ( sqrt ( scalar @{$self->pages}) );     # take the root + 1
	}
	when ('exponential') {
	    use POSIX;
	    my $log2 = POSIX::ceil (log (scalar @{$self->pages}) / log (2));      # next fitting 2-potenz
	    $log2++ if $log2 % 2;                                                 # we can only use even ones
	    $self->{ sqrt }  = ( 2**($log2/2) );                                  # how many along one edge when we organize them into a square?
	}
	default { die "unhandled packing"; }
    }

    $self->{ image } = _list2huge ($self->sqrt, $self->W, $self->H, @{ $self->pages }) ;
}

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
	last unless $_[$a];
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

=head2 Methods

=over

=item B<halfsize>

This will be called by the overall DZI algorithm whenever this overlay is to be size-reduced by 2.

=cut

sub halfsize {
    my $self = shift;

    my ($w, $h) = $self->image->GetAttributes ('width', 'height');                     # current dimensions
    if ($self->{ sqrt } > 1) {
	use feature "switch";
	given ($self->{pack}) {
	    when ('linear')      { $self->{ sqrt }--;    }                             # in linear packing we simply reduce the square root by one
	    when ('exponential') { $self->{ sqrt } /= 2; }
	    default {}
	}
	$self->{ image } = _list2huge ($self->sqrt,                                    # pack sqrt x sqrt A4s into one image
				       $self->W, $self->H,
				       @{ $self->pages });
    }
    $self->image->Resize (width => int($w/2), height => int($h/2));                    # half size
    $self->{x} /= 2;                                                                   # dont forget x, y 
    $self->{y} /= 2;
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

__END__
