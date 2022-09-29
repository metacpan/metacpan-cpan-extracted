package GD::Thumbnail;
$GD::Thumbnail::VERSION = '1.46';
use strict;
use warnings;

use GD;
use Carp qw( croak );

use constant ALL_MIME => qw(
    gd
    gd2
    gif
    jpeg
    png
    wbmp
);

use constant MIME_OVERRIDE => qw(
    jpe    jpeg
    jpg    jpeg
);

use constant KNOWN_GD_FONTS => qw(
    Giant
    Large
    MediumBold
    Small
    Tiny
);

use constant {
    BLACK                    => [   0,   0,   0 ],
    WHITE                    => [ 255, 255, 255 ],

    KILOBYTE                 => 1024,
    MEGABYTE                 => 1024 ** 2,
    GIGABYTE                 => 1024 ** 3,

    DEFAULT_MAX_PIXELS       => 50,
    DEFAULT_MIME             => 'png',
    DEFAULT_TTF_PTSIZE       => 18,
    EMPTY_STRING             => q{},
    FALSE                    => 0,
    GD_FONT                  => 'Tiny',
    IMG_X                    => 0,
    IMG_Y                    => 1,
    MAX_JPEG_QUALITY         => 100,
    MAX_PNG_COMPRESSION      => 9,
    PATH_LENGTH              => 255,
    RATIO_CONSTANT           => 100,
    RE_FILE_EXTENSION        => qr{ [.] (png|gif|jpg|jpe|jpeg) \z }xmsi,
    RE_RATIO                 => qr{ (\d+)(?:\s+|)% }xms,
    STAT_SIZE                => 7,
    STRIP_HEIGHT_BUFFER      => 4, # y-buffer for info strips in pixels
    STRIP_TYPE_BOTTOM        => 1,
    STRIP_TYPE_TOP           => 2,
    THUMBNAIL_DIMENSION      => [ 0, 0 ],

    TTF_BOUNDS_LOWER_LEFT_X  => 0,
    TTF_BOUNDS_LOWER_LEFT_Y  => 1,
    TTF_BOUNDS_LOWER_RIGHT_X => 2,
    TTF_BOUNDS_LOWER_RIGHT_Y => 3,
    TTF_BOUNDS_UPPER_RIGHT_X => 4,
    TTF_BOUNDS_UPPER_RIGHT_Y => 5,
    TTF_BOUNDS_UPPER_LEFT_X  => 6,
    TTF_BOUNDS_UPPER_LEFT_Y  => 7,
};

our %TMP = ( # global template. so that one can change the text
    GB   => '%.2f GB',
    MB   => '%.2f MB',
    KB   => '%.2f KB',
    BY   => '%s bytes',
    TEXT => '<WIDTH>x<HEIGHT> <MIME>',
);

my %KNOWN = (
    MIME_OVERRIDE,
    map { ($_, $_) } ALL_MIME
);

my %IS_GD_FONT = map { ( lc($_), $_ ) } KNOWN_GD_FONTS;

GD::Image->trueColor(1) if GD::Image->can('trueColor');

sub new {
    my($class, @args)= @_;
    my %o    = @args % 2 ? () : @args;
    my $self = {
        DEFAULT_TEXT         => undef,
        DIMENSION            => THUMBNAIL_DIMENSION,
        DIMENSION_CONSTRAINT => FALSE,        # don't exceed w/h?
        FORCE_MIME           => EMPTY_STRING, # force output type?
        FRAME                => FALSE,        # add frame?
        FRAME_COLOR          => BLACK,
        GD_FONT              => GD_FONT,      # info text color
        INFO_COLOR           => WHITE,
        MIME                 => EMPTY_STRING,
        OVERLAY              => FALSE,        # overlay info strips?
        SQUARE               => FALSE,        # make square thumb?
        STRIP_COLOR          => BLACK,
        STRIP_HEIGHT_BUFFER  => STRIP_HEIGHT_BUFFER,
        TTF_FONT             => undef,
        TTF_PTSIZE           => DEFAULT_TTF_PTSIZE,
    };

    $self->{FRAME}   = $o{frame}  ? 1          : 0;
    $self->{SQUARE}  = $o{square} ? $o{square} : 0;
    $self->{OVERLAY} = ($o{overlay} || $self->{SQUARE}) ? 1 : 0;

    for my $name ( qw(
        DEFAULT_TEXT
        DIMENSION_CONSTRAINT
        FORCE_MIME
        TTF_PTSIZE
        STRIP_HEIGHT_BUFFER
    ) ) {
        next if ! defined $o{ lc $name };
        $self->{ $name } = $o{ lc $name };
    }

    if ( $o{font} and my $font = $IS_GD_FONT{ lc $o{font} } ) {
        $self->{GD_FONT} = $font;
    }
    elsif ( my $ttf = $o{ttf_font} ) {
        if ( ! -e $ttf || ! -r _ ) {
            die "ttf_font was set as $ttf but either it does not exist or not readable";
        }
        $self->{TTF_FONT} = $ttf;
    }

    for my $id ( qw( STRIP_COLOR INFO_COLOR FRAME_COLOR ) ) {
        if (my $color = $o{ lc $id }) {
            if ( ref $color && ref $color eq 'ARRAY' && $#{$color} == 2 ) {
                $self->{$id} = $color;
            }
        }
    }

    bless  $self, $class;
    return $self;
}

sub _check_type {
    my($self, $image) = @_;
    my $type;
    if ( length $image <= PATH_LENGTH && $image =~ RE_FILE_EXTENSION ) {
        $type = $KNOWN{lc $1};
    }

    $type = DEFAULT_MIME if ! $type;
    return $type;
}

sub _check_ratio {
    my($self, $max, $w, $h) = @_;
    my $ratio;
    if ( $max =~ RE_RATIO ) {
        $ratio = $1;
    }
    else {
        my $n = $self->{DIMENSION_CONSTRAINT}
              ? $w > $h ? $w : $h
              : $w
              ;
        $ratio = sprintf '%.1f', $max * RATIO_CONSTANT / $n;
    }
    croak 'Can not determine thumbnail ratio' if ! $ratio;
    return $ratio;
}

sub _get_iy {
    my($self, $info, $info2, $o, $y, $yy) = @_;
    return 0 if ! $info;
    return $o       ? $y - $yy
          : $info2 ? $y + $yy + $self->{STRIP_HEIGHT_BUFFER}/2
          :          $y       + $self->{STRIP_HEIGHT_BUFFER}/2
          ;
}

sub _strips {
    my($self, $info, $info2, $o, $x, $y, $yy) = @_;
    my $iy = $self->_get_iy( $info, $info2, $o, $y, $yy );
    my @strips;
    push @strips, [ $info , 0, $iy, 0, 0, $x, $y , RATIO_CONSTANT ] if $info;
    push @strips, [ $info2, 0,   0, 0, 0, $x, $yy, RATIO_CONSTANT ] if $info2;
    return @strips;
}

sub _alter_for_crop {
    my($self, $xsmall, $x_ref, $y_ref, $dx_ref, $dy_ref) = @_;
    if ( $xsmall ) {
        my $diff   = (${$y_ref} - ${$x_ref}) / ${$x_ref};
        ${$x_ref} += ${$x_ref} * $diff;
        ${$y_ref} += ${$y_ref} * $diff;
        ${$dy_ref} = -${$dx_ref} * (2 - ${$x_ref} / ${$y_ref})**2;
        ${$dx_ref} = 0;
    }
    else {
        my $diff   = (${$x_ref} - ${$y_ref}) / ${$y_ref};
        ${$x_ref} += ${$x_ref} * $diff;
        ${$y_ref} += ${$y_ref} * $diff;
        ${$dx_ref} = -${$dy_ref} * ( 2 - ${$y_ref}/${$x_ref} )**2;
        ${$dy_ref} = 0;
    }
    return;
}

sub _setup_parameters {
    my($self, $opt, $x_ref, $y_ref, $dx_ref, $dy_ref, $ty_ref ) = @_;
    if ( $opt->{square} ) {
        my $rx = $opt->{width} < $opt->{height} ? $opt->{width}/$opt->{height} : 1;
        my $ry = $opt->{width} < $opt->{height} ? 1 : $opt->{height}/$opt->{width};
        my $d;
        if ( $opt->{xsmall} ) {
            $d         =  ${$x_ref} * $rx;
            ${$dx_ref} = (${$x_ref} - $d) / 2;
            ${$x_ref}  = $d;
        }
        else {
            $d         = ${$y_ref} * $ry;
            ${$dy_ref} = (${$y_ref} - $d) / 2;
            ${$y_ref}  = $d;
        }
    }

    if ( ! $opt->{square} || ( $opt->{square} && $opt->{xsmall} ) ) {
        # does not work if square & y_is_small, 
        # since we may have info bars which eat y space
        ${$ty_ref} = 0; # TODO. test this more and remove from below
        ${$y_ref}  = ${$y_ref} - ${$ty_ref} - $self->{STRIP_HEIGHT_BUFFER}/2 if $opt->{overlay};
    }
    return;
}

sub create {
    my $self      = shift;
    my $image     = shift || croak 'Image parameter is missing';
    my $max       = shift || DEFAULT_MAX_PIXELS;
    my $info      = shift || 0;

    my $info2     = $info && $info == 2;
    my $type      = $self->_check_type( $image );
    my $o         = $self->{OVERLAY};
    my $size      = $info2 ? $self->_image_size( $image ) : 0;
    my $gd        = GD::Image->new($image) or croak "GD::Image->new error: $!";
    my($w, $h)    = $gd->getBounds         or croak "getBounds() failed: $!";
    my $ratio     = $self->_check_ratio($max, $w, $h);
    my $square    = $self->{SQUARE} || 0;
    my $crop      = $square && lc $square eq 'crop';

    my $x         = sprintf '%.0f', $w * $ratio / RATIO_CONSTANT;
    my $def_y     = sprintf '%.0f', $h * $ratio / RATIO_CONSTANT;
    my $y         = $square ? $x : $def_y;
    my $yy        = 0; # yy & yy2 has the same value
    my $yy2       = 0;

    ($info , $yy ) = $self->_strip(
                        $self->_text( $w, $h, $type ),
                        $x,
                        $y,
                        STRIP_TYPE_BOTTOM
                    ) if $info;

    ($info2, $yy2) = $self->_strip(
                        $self->_size( $size ),
                        $x,
                        $y,
                        STRIP_TYPE_TOP,
                    ) if $info2;

    my $ty        = $yy + $yy2;
    my $new_y     = $o ? $y : $y + $ty;
    my $thumb     = GD::Image->new( $x, $new_y );

    # RT#49353 | Alexander Vonk: prefill Thumbnail with strip color, as promised
    $thumb->fill( 0, 0, $thumb->colorAllocate( @{ $self->{STRIP_COLOR} } ) );

    $thumb->colorAllocate(@{ +WHITE }) if ! $info;

    my @strips = $self->_strips( $info, $info2, $o, $x, $y, $yy );
    my $dx     = 0;
    my $dy     = $yy2 || 0;
    my $xsmall = $x < $def_y;

    $self->_setup_parameters(
        {
            xsmall  => $xsmall,
            square  => $square,
            width   => $w,
            height  => $h,
            overlay => $o,
        },
        \$x, \$y, \$dx, \$dy, \$ty
    );

    $self->_alter_for_crop( $xsmall, \$x, \$y, \$dx, \$dy ) if $crop;

    my $resize = $thumb->can('copyResampled') ? 'copyResampled' : 'copyResized';

    $thumb->$resize($gd, $dx, $dy, 0, 0, $x, $y, $w, $h);
    $thumb->copyMerge( @{$_} ) for @strips;

    return $self->_finish( $thumb, $type );
}

sub _finish {
    my($self, $thumb, $type) = @_;
    my @dim = $thumb->getBounds;

    $self->{DIMENSION}[IMG_X] = $dim[IMG_X];
    $self->{DIMENSION}[IMG_Y] = $dim[IMG_Y];

    if ($self->{FRAME}) {
        my $color = $thumb->colorAllocate(@{ $self->{FRAME_COLOR} });
        $thumb->rectangle( 0, 0, $dim[IMG_X] - 1, $dim[IMG_Y] - 1, $color );
    }

    my $mime = $self->_force_mime($thumb);
    $type = $mime if $mime;
    $self->{MIME} = $type;
    my @iopt;
    push @iopt, MAX_JPEG_QUALITY    if $type eq 'jpeg';
    push @iopt, MAX_PNG_COMPRESSION if $type eq 'png';
    return $thumb->$type( @iopt );
}

sub width  { return shift->{DIMENSION}[IMG_X] }
sub height { return shift->{DIMENSION}[IMG_Y] }
sub mime   { return shift->{MIME}             }

sub _force_mime {
    my $self = shift;
    my $gd   = shift || return;
    return if ! $self->{FORCE_MIME};
    my %mime = map { ( $_, $_ ) } ALL_MIME;
    my $type = $mime{ lc $self->{FORCE_MIME} } || return;
    return unless $gd->can($type);
    return $type;
}

sub _text {
    my($self, $w, $h, $type) = @_;
    $type = uc $type;
    my $tmp = $self->{DEFAULT_TEXT} || $TMP{TEXT} || croak 'TEXT template is not set';
    $tmp =~ s{<WIDTH>}{$w}xmsg;
    $tmp =~ s{<HEIGHT>}{$h}xmsg;
    $tmp =~ s{<MIME>}{$type}xmsg;
    return $tmp;
}

sub _image_size {
    my $self     = shift;
    my $image    = shift;
    my $img_size = 0;
    # don't do that at home. very dangerous :p
    my $is_image = GD::Image->can('_image_type')
                    && GD::Image::_image_type($image); ## no critic (ProtectPrivateSubs)
    if ( $is_image ) { # raw data
        use bytes;
        $img_size = length $image;
    }
    elsif ( defined fileno $image ) { # filehandle
        binmode $image;
        use bytes;
        local $/;
        $img_size = length <$image>;
    }
    else { # file
        $img_size = (stat $image)[STAT_SIZE] if -e $image && !-d _;
    }
    return $img_size;
}

sub _strip {
    my $self = shift;
    return $self->{TTF_FONT} ? $self->_strip_ttf_font( @_ )
                             : $self->_strip_gd_font( @_ )
                             ;
}

sub _strip_ttf_font {
    my $self = shift;
    my $string = shift;
    my $x      = shift;
    my $y      = shift;
    my $type   = shift;

    my $ptsize = $self->{TTF_PTSIZE};

    my %ttf_opt = (
        linespacing => 0.6,
        charmap     => 'Unicode',
    );

    # call once to calculate the location
    my @box = GD::Image->stringFT(
                    GD::Image->new(1,1)->colorAllocate( 0, 0, 0 ),
                    $self->{TTF_FONT},
                    $ptsize,
                    0, # angle
                    0, # x
                    0, # y
                    $string,
                    \%ttf_opt,
                );

    my $sw = abs  $box[TTF_BOUNDS_LOWER_RIGHT_X]
                - $box[TTF_BOUNDS_LOWER_LEFT_X];
    my $sh = abs  $box[TTF_BOUNDS_UPPER_RIGHT_Y]
                - $box[TTF_BOUNDS_LOWER_RIGHT_Y];

    my $ybuf  = $self->{STRIP_HEIGHT_BUFFER};
    my $ttf_x = ( $x - $sw ) / 2;
    my $ttf_y = abs( $box[TTF_BOUNDS_UPPER_RIGHT_Y] )
                + ( $ybuf / 2 );

    $ttf_y /= 2 if ! $self->{OVERLAY} && $type == STRIP_TYPE_BOTTOM;

    if ( $x < $sw ) {
        warn "Thumbnail width ($x) is too small for an info text ($sw)\n";
        # reset the position to prevent cropping the start of the text
        $ttf_x = 0;
    }

    my $info = GD::Image->new( $x, $sh + $ybuf );
    my $strip_color  = $info->colorAllocate(@{ $self->{STRIP_COLOR} });
    my $string_color = $info->colorAllocate(@{ $self->{INFO_COLOR}  });

    $info->filledRectangle(
        0,
        0,
        $x,
        $sh + $ybuf,
        $strip_color,
    );

    # The actual call to place the text
    $info->stringFT(
        $string_color,
        $self->{TTF_FONT},
        $ptsize,
        0, # angle
        $ttf_x,
        $ttf_y,
        $string,
        \%ttf_opt,
    );

    return $info, $sh + $ybuf;
}

sub _strip_gd_font {
    my $self   = shift;
    my $string = shift;
    my $x      = shift;
    my $y      = shift;
    my $type   = shift;

    my $gd_font = $self->{GD_FONT};
    my $font    = GD::Font->$gd_font();
    my $sw      = $font->width * length $string;
    my $sh      = $font->height;
    my $ybuf    = $self->{STRIP_HEIGHT_BUFFER};

    warn "Thumbnail width ($x) is too small for an info text\n" if $x < $sw;

    my $info         = GD::Image->new( $x, $sh + $ybuf );
    my $strip_color  = $info->colorAllocate(@{ $self->{STRIP_COLOR} });
    my $string_color = $info->colorAllocate(@{ $self->{INFO_COLOR}  });

    my $gd_y = ! $self->{OVERLAY} && $type == STRIP_TYPE_BOTTOM
                    ? 0
                    : $ybuf / 2
                ;

    $info->filledRectangle(
        0,
        0,
        $x,
        $sh + $ybuf,
        $strip_color,
    );

    $info->string(
        $font,
        ($x - $sw)/2,
        $gd_y,
        $string,
        $string_color,
    );

    return $info, $sh + $ybuf;
}

sub _size {
    my $self = shift;
    my $size = shift || return '0 bytes';
    return sprintf $TMP{GB}, $size / GIGABYTE if $size >= GIGABYTE;
    return sprintf $TMP{MB}, $size / MEGABYTE if $size >= MEGABYTE;
    return sprintf $TMP{KB}, $size / KILOBYTE if $size >= KILOBYTE;
    return sprintf $TMP{BY}, $size;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GD::Thumbnail

=head1 VERSION

version 1.46

=head1 SYNOPSIS

    use GD::Thumbnail;
    my $thumb = GD::Thumbnail->new;
    my $raw   = $thumb->create('test.jpg', 80, 2);
    my $mime  = $thumb->mime;
    warn sprintf "Dimension: %sx%s\n", $thumb->width, $thumb->height;
    open    IMG, ">thumb.$mime" or die "Error: $!";
    binmode IMG;
    print   IMG $raw;
    close   IMG;

or

    use CGI qw(:standard);
    use GD::Thumbnail;
    my $thumb = GD::Thumbnail->new;
    my $raw   = $thumb->create('test.jpg', 80, 2);
    my $mime  = $thumb->mime;
    binmode STDOUT;
    print header(-type => "image/$mime");
    print $raw;

=head1 DESCRIPTION

This is a thumbnail maker. Thumbnails are smaller versions of the
original image/graphic/picture and are used for preview purposes,
where bigger images can take a long time to load. They are also 
used in image galleries to preview a lot of images at a time.

This module also has the capability to add information strips
about the original image. Original image's size (in bytes)
and resolution & mime type can be added to the thumbnail's
upper and lower parts. This feature can be useful for web
software (image galleries or forums).

This is a I<Yet Another> type of module. There are several
other thumbnail modules on C<CPAN>, but they simply don't have
the features I need, so this module is written to increase
the thumbnail generator population on C<CPAN>.

The module can raise an exception if something goes wrong.
So, you may have to use an C<eval block> to catch them. 

=head1 NAME

GD::Thumbnail - Thumbnail maker for GD

=head1 METHODS

All color parameters must be passed as a three element 
array reference:

    $color = [$RED, $GREEN, $BLUE];
    $black = [   0,      0,     0];

=head2 new

Object constructor. Accepts arguments in C<< key => value >> 
format.

    my $thumb = GD::Thumbnail->new(%args);

=head3 dimension_constraint

If set to true, the resulting dimensions will take the original
image dimensions into consideration. Disabled by default.

=head3 default_text

Can be used to alter the bottom info strip text.

=head3 font

Alters the information text font. You can set this to  C<Small>, 
C<Large>, C<MediumBold>, C<Tiny> or C<Giant> (all are case-insensitive). 
Default value is C<Tiny>, which is best for smaller images. If you 
want to use bigger thumbnails, you can alter the used font via this 
argument. It may also be useful for adding size & resolution 
information to existing images. But beware that GD output size may 
be smaller than the actual image and image quality may also differ.

=head3 force_mime

You can alter the thumbnail mime with this parameter. 
Can be set to: C<png>, C<jpeg> or C<gif>.

=head3 frame

If set to true, a 1x1 pixel border will be added to the final
image.

=head3 frame_color

Controls the C<frame> color. Default is black.

=head3 info_color

Sets the info strip text color. Default is white.
You must pass it as a three element array reference containing
the red, green, blue values:

    $thumb = GD::Thumbnail->new(
      info_color => [255, 255, 255]
    );

=head3 overlay

If you want information strips (see L</create>), but you don't
want to get a longer image, set this to a true value, and
the information strips will not affect the image height
(but the actual thumbnail image will be smaller).

=head3 square

You'll get a square thumbnail, if this is set to true. If the 
original image is not a square, the empty parts will be filled 
with blank (color is the same as C<strip_color>) instead of
stretching the image in C<x> or C<y> dimension or clipping
it. If, however, C<square> is set to C<crop>, you'll get a
cropped square thumbnail.

Beware that enabling this option will also B<auto-enable> the 
C<overlay> option, since it is needed for a square image.

=head3 strip_height_buffer

The y buffer for the strips in pixels.

=head3 strip_color

Sets the info strip background color. Default is black.
You must pass it as a three element array reference containing
the red, green, blue values:

    $thumb = GD::Thumbnail->new(
      strip_color => [255, 0, 0]
    );

=head3 ttf_font

The file path to the TTF font, if you want to use that instead of the built-in
GD fonts. You also need to unset the C<font> parameter, otherwise it will
take precedence.

=head3 ttf_ptsize

The point size of the TTF font you want to use. If not set, htne it will default
to C<18>.

=head2 create

Creates the thumbnail and returns the raw image data.
C<create()> accepts three arguments:

    my $raw = $thumb->create($image    , $max, $info);
    my $raw = $thumb->create('test.jpg',   80, 1    );

=head3 image

Can be a file path, a file handle or raw binary data.

=head3 max

Defines the maximum width of the thumbnail either in pixels or 
percentage. You'll get a warning, if C<info> parameter is set 
and your C<max> value is to small to fit an info text.

=head3 info

If info parameter is not set, or it has a false value, you'll get
a normal thumbnail image:

     _____________
    | ........... |
    | ........... |
    | ...IMAGE... |
    | ........... |
    | ........... |
    |_____________|

If you set it to C<1>, original image's dimensions and mime will be
added below the thumbnail:

     _____________
    | ........... |
    | ........... |
    | ...IMAGE... |
    | ........... |
    | ........... |
    |_____________|
    | 20x20 JPEG  |
     -------------

If you set it to C<2>, the byte size of the image will be added
to the top of the thumbnail:

     _____________
    |    25 KB    |
    |-------------|
    | ........... |
    | ........... |
    | ...IMAGE... |
    | ........... |
    | ........... |
    |_____________|
    | 20x20 JPEG  |
     -------------

As you can see from the examples above, with the default options,
thumbnail image dimension is constant when adding information strips 
(i.e.: strips don't overlay, but attached to upper and lower parts of
thumbnail). Each info strip increases thumbnail height by 8 pixels 
(if the default tiny C<GD> font C<Tiny> is used).

But see the C<overlay> and C<square> options in L</new> to alter this
behavior. You may also need to increase C<max> value if C<square> is
enabled.

=head2 mime

Returns the thumbnail mime. 
Must be called after L</create>.

=head2 width

Returns the thumbnail width in pixels. 
Must be called after L</create>.

=head2 height

Returns the thumbnail height in pixels. 
Must be called after L</create>.

=head1 WARNINGS

You may get a warning, if there is something odd.

=over 4

=item *

B<I<"Thumbnail width (%d) is too small for an info text">>

C<max> argument to C<create> is too small to fit information.
Either disable C<info> parameter or increase C<max> value.

=back

=head1 EXAMPLES

You can reverse the strip and info colors and then add a frame
to the thumbnail to create a picture frame effect:

    my $thumb = GD::Thumbnail->new(
      strip_color => [255, 255, 255],
      info_color  => [  0,   0,   0],
      square      => 1,
      frame       => 1,
    );
    my $raw = $thumb->create('test.jpg', 100, 2);

If you have a set of images with the same dimensions, 
you may use a percentage instead of a constant value:

    my $raw = $thumb->create('test.jpg', '10%', 2);

Resulting thumbnail will be 90% smaller (x-y dimensions)
than the original image.

=head1 CAVEATS

Supported image types are limited with GD types, which include
C<png>, C<jpeg> and C<gif> and some others. See L<GD> for more information.
Usage of any other image type will be resulted with a fatal
error.

=head1 SEE ALSO

L<GD>, L<Image::Thumbnail>, L<GD::Image::Thumbnail>, L<Image::GD::Thumbnail>
L<Image::Magick::Thumbnail>, L<Image::Magick::Thumbnail::Fixed>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
