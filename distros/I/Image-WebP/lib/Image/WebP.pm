package Image::WebP;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;

require DynaLoader;

=head1 NAME

Image::WebP - binding to Google's libwebp.

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Image::WebP;

    my $foo = Image::WebP->new();
    
    # get info about image
    my $img_info = $foo->WebPGetInfo($webp_image_data);

    # uncompress Webp-encoded data:
    my $raw_data = $foo->WebPDecodeSimple($webp_image_data, "RGB");

=head1 SUBROUTINES/METHODS

=head3 new

  Constructor. No params needed.

=cut

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}


# =head3 WebPGetInfo($img_data)
#  
# Return hashref with information about passed $img_data - the raw data
# of webp image file. Check field 'status', if it 0, then the webp data
# was invalid and image decoding failed. The other fileds is 'width' and
# 'height'.
#  
# =cut

sub WebPGetInfo {
    my ($self, $img_data) = @_;

    my @res = xs_WebPGetInfo($img_data, length($img_data));
    return {
        'status' => shift @res,
        'width'  => shift @res,
        'height' => shift @res
       };
}


=head3 WebPGetFeatures(img_data)

Return hashref with information about passed <img_data> - the raw data
of webp image file. Check field 'status', if it 0, then the webp data
was invalid and image decoding failed. The other fileds is 'width' and
'height', and 'has_alpha'.

=cut

sub WebPGetFeatures {
    my ($self, $img_data) = @_;

    my @res = xs_WebPGetFeatures($img_data, length($img_data));
    return {
        'status'    => shift @res,
        'width'     => shift @res,
        'height'    => shift @res,
        'has_alpha' => shift @res
       };
}


=head3 WebPDecodeSimple (data, format)

Decode Webp image <data> into specified rgb <format>. Format can be:
"RGBA", "ARGB", "BGRA", "RGB", "BGR". Returns raw string. If you
pass wrong webp data, you can catch segfault!

Returns hash like:

  {
     'data'   => ...,
     'width'  => ...,
     'height' => ...
  }

=cut

sub WebPDecodeSimple {
    my ($self, $img_data, $format ) = @_;

    my %formats = ( "RGBA" => 1, "ARGB" => 2, "BGRA" => 3, "RGB" => 4, "BGR" => 5 );

    my @res = xs_WebPDecodeSimple($img_data, length($img_data), $formats{$format} || 1);

    return {
        'data'   => shift @res,
        'width'  => shift @res,
        'height' => shift @res
       };
}


=head3 WebPEncodeSimple(data, width, height, format, opts)

Encode raw RGB <data> with specified <width> and <height> into webp image and return it as string. Parameter <format> stands for raw data format, you pass to function, it can be one of "RGBA", "BGRA", "RGB", "BGR". The <format> must be exactly same as your data, or you will encounter segfault!

The <opts> parameter stands for encoding options. For understanding them see L<https://developers.google.com/speed/webp/docs/api>. Supported options are:

 {
    stride  => integer, # not specify it unless you really know what you want
    quality => float,   # 0.0 - 100.0, needed if you compress to lossy format
    loseless=> 0 || 1,  #  0 for lossy encoding and 1 for loseless
 }

=cut

sub WebPEncodeSimple {
    my ($self, $data, $w, $h, $fmt, $opts) = @_;

    my %formats = ( "RGBA" => 3, "BGRA" => 4, "RGB" => 1, "BGR" => 2 );

    $opts->{'quality'} = 95.0 if !defined($opts->{'quality'});
    $opts->{'stride'}  = $w*3;

    my @res = xs_WebPEncode(
        $data, $w, $h,
        $opts->{'stride'},
        $formats{$fmt},
        $opts->{'loseless'} ? 2 : 1,
        $opts->{'quality'}
       );

    return {
        size => shift(@res),
        data => shift(@res)
    }
}


require XSLoader;
XSLoader::load('Image::WebP', $VERSION);


=head1 AUTHOR

Zargener, C<< <zargener at gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Zargener.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Image::WebP
