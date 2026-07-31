package Image::WebP;

use 5.010;
use strict;
use warnings FATAL => 'all';

require DynaLoader;

=head1 NAME

Image::WebP - binding to Google's libwebp.

=cut

our $VERSION = '0.03';


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

Decode WebP image C<data> into the specified RGB C<format>. The format can be:
"RGBA", "ARGB", "BGRA", "RGB", "BGR". Returns raw string. If you
pass invalid WebP data, the method throws an exception.

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
    die "WebP decode format is required\n"
        if !defined($format);
    die "Unsupported WebP decode format '$format'\n"
        if !exists($formats{$format});

    my @res = xs_WebPDecodeSimple($img_data, length($img_data), $formats{$format});

    return {
        'data'   => shift @res,
        'width'  => shift @res,
        'height' => shift @res
       };
}


=head3 WebPEncodeSimple(data, width, height, format, opts)

Encode raw RGB or RGBA C<data> with the specified C<width> and C<height>
into WebP data. C<format> must describe the raw data and can be one of
"RGBA", "BGRA", "RGB", "BGR".

The <opts> parameter stands for encoding options. For understanding them see L<https://developers.google.com/speed/webp/docs/api>. Supported options are:

 {
    stride  => integer, # not specify it unless you really know what you want
    quality => float,   # 0.0 - 100.0, needed if you compress to lossy format
    lossless => 0 || 1, # 0 for lossy encoding and 1 for lossless
 }

The historical misspelling C<loseless> remains accepted for compatibility.

=cut

sub WebPEncodeSimple {
    my ($self, $data, $w, $h, $fmt, $opts) = @_;

    my %formats = ( "RGBA" => 3, "BGRA" => 4, "RGB" => 1, "BGR" => 2 );
    my %channels = ( "RGBA" => 4, "BGRA" => 4, "RGB" => 3, "BGR" => 3 );
    die "WebP encode format is required\n"
        if !defined($fmt);
    die "Unsupported WebP encode format '$fmt'\n"
        if !exists($formats{$fmt});

    my %options = %{ $opts || {} };
    $options{'quality'} = 95.0 if !defined($options{'quality'});
    $options{'stride'} = $w * $channels{$fmt}
        if !defined($options{'stride'});
    my $lossless = $options{'lossless'} || $options{'loseless'};

    my @res = xs_WebPEncode(
        $data, $w, $h,
        $options{'stride'},
        $formats{$fmt},
        $lossless ? 2 : 1,
        $options{'quality'}
       );

    return {
        size => shift(@res),
        data => shift(@res)
    }
}


require XSLoader;
XSLoader::load('Image::WebP', $VERSION);


=head1 AUTHOR

Yalexwander, C<< <yalexvandr at gmail.com> >>
Zen Dodd, C<< <mail at steadytao.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2026 Yalexwander.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of Image::WebP
