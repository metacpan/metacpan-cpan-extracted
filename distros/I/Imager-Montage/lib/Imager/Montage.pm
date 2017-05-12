package Imager::Montage;

use warnings;
use strict;

use Imager;

=head1 NAME

Imager::Montage - montage images 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # Generate a montage image.

    use Imager::Montage;

    my $im = Imager::Montage->new;
    my @imgs = <*.png>;
    my $page = $im->gen_page(
        {   
            files       => \@imgs,
            geometry_w  => 200,  # geometry from source. if not set , the resize_w , resize_h will be the default
            geometry_h  => 200,  # if we aren't going to resize the source images , we should specify the geometry at least.
            cols        => 5,
            rows        => 5,
        }
    );
    $page->write( file => 'page.png' , type => 'png'  );  # generate a 1000x1000 pixels image with 5x5 tiles

=head1 EXPORT


=head1 Methods

=over 4

=item B<new>
=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}


=item B<_load_image>

return a Imager object

    $imager = $self->_load_image( $filename );

=cut

sub _load_image {
    my $self     = shift;
    my $filename = shift;
    my $o        = Imager->new;
    $o->read( file => $filename );
    return $o;
}

=item B<_load_font>
    
Return Imager::Font

    my $font = _load_font( { file => '/path/to/font.ttf' , color => '#000000' , size => 72 } );

=cut

sub _load_font {
    my ( $self , $args ) = @_;
    # get the font path
    my $color = Imager::Color->new(  $args->{color}  );
    my $font  = Imager::Font->new(
        file  => $args->{file},
        color => Imager::Color->new( $args->{color} ),
        size  => $args->{size},
    );
    return $font;
}

=item B<_load_color>
    
return Imager::Color

    $self->_load_color( '#000000' );

=cut

sub _load_color {
    my ( $self , $color ) = @_;
    return Imager::Color->new( $color ),
}

=item B<gen_page>

montage your source image .  it will return an Imager Object.

    my $page = $im->gen_page(
        {   
            files    => \@imgs,
            resize_w => 100,
            resize_h => 100,
            cols     => 3,
            rows     => 3,
            margin_v => 5,
            margin_h => 5,

            page_width       => 800,
            page_height      => 600,
            background_color => '#ffffff',

            flip         => 'h',                             # horizontal flip
            flip_exclude => ' return $file =~ m/d\d+.png/ '
            ,    # don't flip files named \d+.png  ( optional )

            frame       => 4,           # ( optional )
            frame_color => '#000000',

            border       => 4,
            border_color => '#000000',

            res => 600,
        }
    );

Parameters:

I<files>: an array contains filenames

I<background_color>: background color of output image

I<geometry_h, geometry_w>:  geometry from source. if not set , the resize_w , resize_h will be the default

I<resize_w, resize_h>): if it's given , montage will resize your source image to this size

I<cols, rows>: tiles

I<margin_v,margin_h>: margin for each image

I<page_width, page_height>: the output image width & height

I<flip>: do flip to each source image

I<flip_exclude>

I<frame>: frame width (optional)

I<frame_color>: frame color (optional)

I<border>:  border width for each image (optional)

I<border_color>:    border color (optional)

I<res>: resolution , default resolution is 600 (optional)

=cut

# XXX: calculates the max cols and max rows if we specify the page width and page height
sub gen_page {
    my $self = shift;
    my $args = shift;

    $args->{geometry_w} ||= $args->{resize_w};
    $args->{geometry_h} ||= $args->{resize_h};

    $args->{$_} ||= 0
        for(qw/border frame margin_v margin_h/);

    $args->{$_}         ||= '#ffffff'
        for (qw/background_color border_color frame_color/);

    $args->{page_width}
        ||= $args->{frame} * 2 
        + ( $args->{border} * 2 ) * $args->{cols} 
        + $args->{geometry_w} * $args->{cols}
        + ( $args->{margin_h} * 2 ) * $args->{cols};

    $args->{page_height}
        ||= $args->{frame} * 2 
        + ( $args->{border} * 2 ) * $args->{rows}
        + $args->{geometry_h} * $args->{rows}
        + ( $args->{margin_v} * 2 ) * $args->{rows};


    $args->{$_} = $self->_load_color( $args->{$_} )
        for (qw/background_color border_color frame_color/);

    # create a page
    my $page_img = Imager->new( 
        xsize => $args->{page_width},
        ysize => $args->{page_height});

    $self->_set_resolution( $page_img, $args->{res} )
        if ( exists $args->{res} );

    # this could make a frame for page
    if ( exists $args->{frame} ) {
        $page_img->box(
            filled => 1,
            color  => $args->{frame_color} );

        my $box = Imager->new(
                xsize => $args->{page_width} - $args->{frame} * 2 ,
                ysize => $args->{page_height} - $args->{frame} * 2 )->box( filled => 1, color  => $args->{background_color});

        $page_img->paste(
            left => $args->{frame},
            top  => $args->{frame},
            src  => $box);
    }
    else {
        $page_img->box(
            filled => 1,
            color  => $args->{background_color},
        );
    }

    my ( $top, $left ) = (
        $args->{frame}, 
        $args->{frame} );

    for my $col ( 0 .. $args->{cols} - 1 ) {

        $top = $args->{frame};

        for my $row ( 0 .. $args->{rows} - 1 ) {

            # get filename
            my $file = ${ $args->{files} }[ $col * $args->{rows} + $row ];
            next if ( ! defined $file );


            my $canvas_img = $self->_load_image($file);

            # resize it if we define a new size
            if ( exists $args->{resize_w} ) {
                $canvas_img = $canvas_img->scale(
                                    xpixels => $args->{resize_w},
                                    ypixels => $args->{resize_h},
                                    type    => 'nonprop',); }  # XXX: make nonprop as parameter

            # flip
            if ( exists $args->{flip}
                and ( exists $args->{flip_exclude} and !eval( $args->{flip_exclude} ) ) ) {
                $canvas_img->flip( dir => $args->{flip} ); }

            # if border is set
            if( $args->{border} ) {
                # gen border , paste it before we paste image to the page
                my $box = Imager->new(
                    xsize => $args->{geometry_w} + $args->{border} * 2,
                    ysize => $args->{geometry_h} + $args->{border} * 2 )->box( filled => 1, color => $args->{border_color} );
                $page_img->paste(
                    left => $left + $args->{margin_h} ,
                    top  => $top + $args->{margin_v} , 
                    src  => $box );
            } 

            $page_img->paste(
                left => $left + $args->{margin_h} + $args->{border} ,  # default border is 0
                top  => $top + $args->{margin_v} + $args->{border} ,
                src  => $canvas_img);

        } continue {
            $top += ( $args->{border} * 2 + $args->{margin_v} * 2 + $args->{geometry_h} );
        }
    } 
    continue {
        $left += ( $args->{border} * 2 + $args->{margin_h} * 2 + $args->{geometry_w} );
    }

    return $page_img;
}

=item B<_set_resolution>

default resolution is 600 dpi

    $self->_set_resolution( $filename , 600 );
    $self->_set_resolution( $imager  );

=cut

sub _set_resolution {
    my $self = shift;
    my $src  = shift;
    my $res  = shift || 600;
    if ( $src =~ m/^Imager::/ ) {

        # use Imager to set resolution
        $src->settag( name => 'i_xres', value => $res );
        $src->settag( name => 'i_yres', value => $res );
    }
    elsif ( ref($src) eq 'SCALAR' ) {

        # it's a filename
        my $image = Imager->new();
        $image->read( file => $src );    # read from file
        $image->settag( name => 'i_xres', value => $res );
        $image->settag( name => 'i_yres', value => $res );
        $image->write( file => $src, type => 'png' );    # write to reference
    }
}

=back

=head1 AUTHOR

Cornelius, C<< <c9s at aiink.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imager-montage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Imager-Montage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Imager::Montage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-Montage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Imager-Montage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Imager-Montage>

=item * Search CPAN

L<http://search.cpan.org/dist/Imager-Montage>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Cornelius, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Imager::Montage
