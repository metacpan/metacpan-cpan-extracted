package Imager::Filter::RoundedCorner;
use strict;
use warnings;

use Imager;
use Imager::Fill;

our $VERSION = '0.02';

Imager->register_filter(
    type     => 'rounded_corner',
    defaults => {
        radius       => '5',
        bg           => '#ffffff',
        aa           => 0,
        border_width => 0,
        border_color => '#000000'
    },
    callseq => [qw/imager radius bg aa border_width border_color/],
    callsub => \&round_corner,
);

sub round_corner {
    my %args = @_;
    my ( $imager, $radius, $bg, $aa, $border_width, $border_color ) =
      @args{qw/imager radius bg aa border_width border_color/};

    my $transparent = Imager::Color->new( 0, 0, 0, 0 );

    my $corner = Imager->new(
        xsize    => $radius,
        ysize    => $radius,
        channels => 4,
    );
    $corner->box( filled => 1, color => Imager::Color->new( $bg ) );

    if ($border_width) {
        $corner->circle(
            color  => Imager::Color->new($border_color),
            r      => $radius,
            x      => $radius,
            y      => $radius,
            aa     => 0,
            filled => 0,
        );
    }
    $corner->circle(
        color  => $transparent,
        r      => $radius - $border_width,
        x      => $radius,
        y      => $radius,
        aa     => 0,
        filled => 1
    );

    my $mask = Imager->new(
        xsize    => $imager->getwidth,
        ysize    => $imager->getheight,
        channels => 4,
    );
    $mask->box( filled => 1, color => $transparent );
    if ($border_width) {
        $mask->box(
            filled => 0,
            color  => Imager::Color->new($border_color),
            xmin   => $_,
            ymin   => $_,
            xmax   => $imager->getwidth - 1 - $_,
            ymax   => $imager->getheight - 1 - $_,
          )
          for 0 .. ($border_width-1);
    }

    # left top
    $mask->paste( src => $corner );

    # left bottom
    $corner->flip( dir => 'v' );
    $mask->paste( src => $corner, top => $imager->getheight - $radius );

    # right bottom
    $corner->flip( dir => 'h' );
    $mask->paste(
        src  => $corner,
        top  => $imager->getheight - $radius,
        left => $imager->getwidth - $radius
    );

    # right top
    $corner->flip( dir => 'v' );
    $mask->paste( src => $corner, left => $imager->getwidth - $radius );

    $imager->box(
        fill => Imager::Fill->new( image => $mask, combine => 'normal' ) );

    if ($aa) {
        my $copy = Imager->new(
            xsize    => $imager->getwidth,
            ysize    => $imager->getheight,
            channels => 4,
        );
        $copy->box( fill => Imager::Fill->new( image => $imager, combine => 'normal' ) );

        $copy->flood_fill( x => 0, y => 0, color => $transparent );
        $copy->flood_fill(
            x     => $copy->getwidth - 1,
            y     => 0,
            color => $transparent
        );
        $copy->flood_fill(
            x     => 0,
            y     => $copy->getheight - 1,
            color => $transparent
        );
        $copy->flood_fill(
            x     => $copy->getwidth - 1,
            y     => $copy->getheight - 1,
            color => $transparent
        );

        $imager->filter( type => 'conv', coef => [ 1, 2, 1 ] );
        $imager->box( fill => Imager::Fill->new( image => $copy, combine => 'normal' ) );
    }
}

=head1 NAME

Imager::Filter::RoundedCorner - Make nifty images with Imager

=head1 SYNOPSIS

    use Imager;
    use Imager::Filter::RoundedCorner;
    
    my $image = Imager->new;
    $image->read( file => 'source.jpg' );
    
    $image->filter(
        type   => 'rounded_corner',
        radius => 10,
        bg     => '#ffffff'
    );
    
    $image->write( file => 'dest.jpg' );

=head1 DESCRIPTION

This filter fill image's corner with 'bg' color as rounded corner.

Filter parameters are:

=over

=item radius

corner's radius

=item bg

background color

=item aa

antialias flag. 1 = on (default: 0)

=item border_width

border width (default: 0)

=item border_color

border color (default: #000000)

=back

=head1 SUBROUTINES

=head2 round_corner

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
