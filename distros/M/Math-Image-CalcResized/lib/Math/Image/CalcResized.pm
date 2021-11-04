package Math::Image::CalcResized;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Math-Image-CalcResized'; # DIST
our $VERSION = '0.005'; # VERSION

our @EXPORT_OK = qw(calc_image_resized_size);
our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Calculate dimensions of image/video resized by ImageMagick-like geometry specification',
};

sub _calc_or_human {
    my ($action, %args) = @_;

    my $size;
    my ($w, $h);
    if ($action eq 'calc') {
        $size = $args{size} or return [400, "Please specify image size"];
        $size =~ /\A(\d+)x(\d+)\z/ or return [400, "Invalid size format, please use <width>x<height> syntax"];
        ($w, $h) = ($1, $2);
    }
    my $resize = $args{resize}; defined $resize or return [400, "Please specify resize"];
    my ($w2, $h2) = ($w, $h);
    my $human_general = "no resizing";
    my $human_specific;

    goto SKIP unless length $resize;

    # some instructions are translated to other first
    if ($resize =~ /\A(\d+)\^([<>])\z/) {
        $human_general = ($2 eq '>' ? "shrink" : "enlarge") . " shortest side to ${1}px";
        goto SKIP unless $action eq 'calc';
        if ($w < $h) {
            $resize = "$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " shortest side (width) to ${1}px";
        } else {
            $resize = "x$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " shortest side (height) to ${1}px";
        }
    } elsif ($resize =~ /\A\^(\d+)([<>])\z/) {
        $human_general = ($2 eq '>' ? "shrink" : "enlarge") . " longest side to ${1}px";
        goto SKIP unless $action eq 'calc';
        if ($w > $h) {
            $resize = "$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " longest side (width) to ${1}px";
        } else {
            $resize = "x$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " longest side (height) to ${1}px";
        }
    }

    if ($resize =~ /\A(\d+(?:\.\d*)?)%\z/) {
        $human_general = "scale to $resize";
        goto SKIP unless $action eq 'calc';
        $w2 = $1/100 * $w;
        $h2 = $1/100 * $h;
        $human_specific = "scale to $resize (${w2}px)";
    } elsif ($resize =~ /\A(\d+(?:\.\d*)?)%?x(\d+(?:\.\d*)?)%\z/) {
        $human_general = "scale width to ${1}%, height to ${2}%";
        goto SKIP unless $action eq 'calc';
        $w2 = $1/100 * $w;
        $h2 = $2/100 * $h;
        $human_specific = "scale width to ${1}% (${w2}px), height to ${2}% (${h2}px)";
    } elsif ($resize =~ /\A(\d+)([>^<]?)\z/) {
        my $which = $2;
        if ($which eq '>') { # shrink
            $human_general = "shrink width to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $w <= $1;
        } elsif ($which eq '^' || $which eq '<') { # enlarge
            $human_general = "enlarge width to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $w >= $1;
        } else {
            $human_general = "set width to ${1}px";
            goto SKIP unless $action eq 'calc';
        }

        $w2 = $1;
        $h2 = ($h/$w) * $w2;
        $human_specific = $human_general;
    } elsif ($resize =~ /\Ax(\d+)([>^<]?)\z/) {
        my $which = $2;
        if ($which eq '>') { # shrink
            $human_general = "shrink height to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $h <= $1;
        } elsif ($which eq '^' || $which eq '<') { # enlarge
            $human_general = "enlarge height to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $h >= $1;
        } else {
            $human_general = "set height to ${1}px";
            goto SKIP unless $action eq 'calc';
        }

        $h2 = $1;
        $w2 = ($w/$h) * $h2;
        $human_specific = $human_general;
    } elsif ($resize =~ /\A(\d+)x(\d+)([<>!^]?)\z/) {
        my $which = $3;
        if ($which eq '' || $which eq '>') {
            if ($which eq '>') {
                $human_general = "shrink image to fit inside ${1}x${2}";
                goto SKIP unless $action eq 'calc';
                goto SKIP if $w <= $1 || $h <= $2;
            }

            $human_general = "fit image inside ${1}x${2}";
            goto SKIP unless $action eq 'calc';

            if ($h2 > $2) {
                $h2 = $2;
                $w2 = ($w/$h) * $h2;
            }
            if ($w2 > $1) {
                $h2 = $1/$w2 * $h2;
                $w2 = $1;
            }
            $human_specific = $human_general;
        } elsif ($which eq '^' || $which eq '<') {
            if ($which eq '<') {
                $human_general = "enlarge image to fit ${1}x${2} inside it";
                goto SKIP unless $action eq 'calc';
                goto SKIP if $w >= $1 || $h >= $2;
            }

            $human_general = "fit image to fit ${1}x${2} inside it";
            goto SKIP unless $action eq 'calc';

            if ($h2 < $2) {
                $h2 = $2;
                $w2 = ($w/$h) * $h2;
            }
            if ($w2 < $1) {
                $h2 = $1/$w2 * $h2;
                $w2 = $1;
            }
            $human_specific = $human_general;
        } elsif ($which eq '!') {
            $human_general = "set dimension to ${1}x${2}";
            goto SKIP unless $action eq 'calc';

            $w2 = $1;
            $h2 = $2;
            $human_specific = $human_general;
        }
    } else {
        return [400, "Unrecognized resize instruction '$resize'"];
    }

  SKIP:
    if ($action eq 'human') {
        [200, "OK", $human_general];
    } else {
        [200, "OK", sprintf("%dx%d", $w2, $h2), {
            'func.human_general' => $human_general,
            'func.human_specific' => $human_specific,
        }];
    }
}

$SPEC{calc_image_resized_size} = {
    v => 1.1,
    summary => 'Given size of an image (in WxH, e.g. "2592x1944") and ImageMagick-like resize instruction (e.g. "1024p>"), calculate new resized image',
    args => {
        size => {
            summary => 'Image/video size, in <width>x<height> format, e.g. 2592x1944',
            schema => ['str*', match=>qr/\A\d+x\d+\z/],
            req => 1,
            pos => 0,
            description => <<'_',

_
        },
        resize => {
            summary => 'Resize instruction, follows ImageMagick format',
            schema => 'str*',
            req => 1,
            pos => 1,
            description => <<'_',

Resize instruction can be given in several formats:

    Syntax                     Meaning
    -------------------------- ----------------------------------------------------------------
    ""                         No resizing.

    SCALE"%"                   Height and width both scaled by specified percentage.
    SCALEX"%x"SCALEY"%"        Height and width individually scaled by specified percentages. (Only one % symbol needed.)

    WIDTH                      Width given, height automagically selected to preserve aspect ratio.
    WIDTH">"                   Shrink width if larger, height automagically selected to preserve aspect ratio.
    WIDTH"^"                   Enlarge width if smaller, height automagically selected to preserve aspect ratio.

    "x"HEIGHT                  Height given, width automagically selected to preserve aspect ratio.
    "x"HEIGHT">"               Shrink height if larger, width automagically selected to preserve aspect ratio.
    "x"HEIGHT"^"               Enlarge height if smaller, width automagically selected to preserve aspect ratio.

    WIDTH"x"HEIGHT             Maximum values of height and width given, aspect ratio preserved.
    WIDTH"x"HEIGHT"^"          Minimum values of height and width given, aspect ratio preserved.
    WIDTH"x"HEIGHT"!"          Width and height emphatically given, original aspect ratio ignored.
    WIDTH"x"HEIGHT">"          Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).
    WIDTH"x"HEIGHT"<"          Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).

    NUMBER"^>"                 Shrink shortest side if larger than number, aspect ratio preserved.
    NUMBER"^<"                 Enlarge shortest side if larger than number, aspect ratio preserved.
    "^"NUMBER">"               Shrink longer side if larger than number, aspect ratio preserved.
    "^"NUMBER"<"               Enlarge longer side if larger than number, aspect ratio preserved.

Currently unsupported:

    AREA"@"                    Resize image to have specified area in pixels. Aspect ratio is preserved.
    X":"Y                      Here x and y denotes an aspect ratio (e.g. 3:2 = 1.5).

Ref: <http://www.imagemagick.org/script/command-line-processing.php#geometry>

_
        },
    },
    examples => [
        {args=>{size=>"2592x1944", resize=>""}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"20%"}, naked_result=>"518x388"},

        {args=>{size=>"2592x1944", resize=>"20%x40%"}, naked_result=>"518x777"},
        {args=>{size=>"2592x1944", resize=>"20x40%"}, naked_result=>"518x777"},

        {args=>{size=>"2592x1944", resize=>"1024"}, naked_result=>"1024x768"},

        {args=>{size=>"2592x1944", resize=>"1024>"}, naked_result=>"1024x768"},
        {args=>{size=>"2592x1944", resize=>"10240>"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"1024^"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"10240^"}, naked_result=>"10240x7680"},

        {args=>{size=>"2592x1944", resize=>"x1024"}, naked_result=>"1365x1024"},

        {args=>{size=>"2592x1944", resize=>"x768>"}, naked_result=>"1024x768"},
        {args=>{size=>"2592x1944", resize=>"x7680>"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"x768^"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"x7680^"}, naked_result=>"10240x7680"},

        {args=>{size=>"2592x1944", resize=>"20000x10000"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"20000x1000"}, naked_result=>"1333x1000"},
        {args=>{size=>"2592x1944", resize=>"100x200"}, naked_result=>"100x75"},
        {args=>{size=>"2592x1944", resize=>"100x100"}, naked_result=>"100x75"},

        {args=>{size=>"2592x1944", resize=>"10000x5000^"}, naked_result=>"10000x7500"},
        {args=>{size=>"2592x1944", resize=>"5000x10000^"}, naked_result=>"13333x10000"},
        {args=>{size=>"2592x1944", resize=>"100x100^"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"100x100!"}, naked_result=>"100x100"},

        {args=>{size=>"2592x1944", resize=>"10000x5000>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"5000x10000>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"3000x1000>"}, naked_result=>"2592x1944"}, #?
        {args=>{size=>"2592x1944", resize=>"2000x1000>"}, naked_result=>"1333x1000"},
        {args=>{size=>"2592x1944", resize=>"100x100>"}, naked_result=>"100x75"},

        {args=>{size=>"2592x1944", resize=>"10000x5000<"}, naked_result=>"10000x7500"},
        {args=>{size=>"2592x1944", resize=>"5000x10000<"}, naked_result=>"13333x10000"},
        {args=>{size=>"2592x1944", resize=>"3000x1000<"}, naked_result=>"2592x1944"}, #?
        {args=>{size=>"2592x1944", resize=>"2000x1000<"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"100x100<"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"1024^>"}, naked_result=>"1365x1024"},
        {args=>{size=>"2592x1944", resize=>"10240^>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"1024^<"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"10240^<"}, naked_result=>"13653x10240"},

        {args=>{size=>"2592x1944", resize=>"^1024>"}, naked_result=>"1024x768"},
        {args=>{size=>"2592x1944", resize=>"^10240>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"^1024<"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"^10240<"}, naked_result=>"10240x7680"},
    ],
    links => [
        {url=>'prog:imgsize'},
    ],
};
sub calc_image_resized_size {
    _calc_or_human('calc', @_);
}

$SPEC{image_resize_notation_to_human} = {
    v => 1.1,
    summary => 'Translate ImageMagick-like resize notation (e.g. "720^>") to human-friendly text (e.g. "shrink shortest side to 720px")',
    description => <<'_',

Resize notation supports most syntax from ImageMagick geometry. See
<pm:Math::Image::CalcResized> and ImageMagick documentation on geometry for more
details.

_
    args => {
        resize => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            args => {resize=>''}, naked_result=>'no resizing',
        },

        {
            args => {resize=>'50%'}, naked_result=>'scale to 50%',
        },
        {
            args => {resize=>'50%x50%'}, naked_result=>'scale width to 50%, height to 50%',
        },

        {
            args => {resize=>'720'}, naked_result=>'set width to 720px',
        },
        {
            args => {resize=>'720>'}, naked_result=>'shrink width to 720px',
        },
        {
            args => {resize=>'720^'}, naked_result=>'enlarge width to 720px',
        },

        {
            args => {resize=>'x720'}, naked_result=>'set height to 720px',
        },
        {
            args => {resize=>'x720>'}, naked_result=>'shrink height to 720px',
        },
        {
            args => {resize=>'x720^'}, naked_result=>'enlarge height to 720px',
        },

        {
            args => {resize=>'640x480'}, naked_result=>'fit image inside 640x480',
        },
        {
            args => {resize=>'640x480^'}, naked_result=>'fit image to fit 640x480 inside it',
        },
        {
            args => {resize=>'640x480>'}, naked_result=>'shrink image to fit inside 640x480',
        },
        {
            args => {resize=>'640x480<'}, naked_result=>'enlarge image to fit 640x480 inside it',
        },
        {
            args => {resize=>'640x480!'}, naked_result=>'set dimension to 640x480',
        },

        {
            args => {resize=>'720^>'}, naked_result=>'shrink shortest side to 720px',
        },
        {
            args => {resize=>'720^<'}, naked_result=>'enlarge shortest side to 720px',
        },
        {
            args => {resize=>'^720>'}, naked_result=>'shrink longest side to 720px',
        },
        {
            args => {resize=>'^720<'}, naked_result=>'enlarge longest side to 720px',
        },
    ],
};
sub image_resize_notation_to_human {
    _calc_or_human('human', @_);
}

1;
# ABSTRACT: Calculate dimensions of image/video resized by ImageMagick-like geometry specification

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Image::CalcResized - Calculate dimensions of image/video resized by ImageMagick-like geometry specification

=head1 VERSION

This document describes version 0.005 of Math::Image::CalcResized (from Perl distribution Math-Image-CalcResized), released on 2021-10-12.

=head1 FUNCTIONS


=head2 calc_image_resized_size

Usage:

 calc_image_resized_size(%args) -> [$status_code, $reason, $payload, \%result_meta]

Given size of an image (in WxH, e.g. "2592x1944") and ImageMagick-like resize instruction (e.g. "1024pE<gt>"), calculate new resized image.

Examples:

=over

=item * Example #1:

 calc_image_resized_size(size => "2592x1944", resize => ""); # -> [200, "OK (envelope generated)", "2592x1944"]

=item * Example #2:

 calc_image_resized_size(size => "2592x1944", resize => "20%"); # -> [200, "OK (envelope generated)", "518x388"]

=item * Example #3:

 calc_image_resized_size(size => "2592x1944", resize => "20%x40%");

Result:

 [200, "OK (envelope generated)", "518x777"]

=item * Example #4:

 calc_image_resized_size(size => "2592x1944", resize => "20x40%");

Result:

 [200, "OK (envelope generated)", "518x777"]

=item * Example #5:

 calc_image_resized_size(size => "2592x1944", resize => 1024); # -> [200, "OK (envelope generated)", "1024x768"]

=item * Example #6:

 calc_image_resized_size(size => "2592x1944", resize => "1024>");

Result:

 [200, "OK (envelope generated)", "1024x768"]

=item * Example #7:

 calc_image_resized_size(size => "2592x1944", resize => "10240>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #8:

 calc_image_resized_size(size => "2592x1944", resize => "1024^");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #9:

 calc_image_resized_size(size => "2592x1944", resize => "10240^");

Result:

 [200, "OK (envelope generated)", "10240x7680"]

=item * Example #10:

 calc_image_resized_size(size => "2592x1944", resize => "x1024");

Result:

 [200, "OK (envelope generated)", "1365x1024"]

=item * Example #11:

 calc_image_resized_size(size => "2592x1944", resize => "x768>");

Result:

 [200, "OK (envelope generated)", "1024x768"]

=item * Example #12:

 calc_image_resized_size(size => "2592x1944", resize => "x7680>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #13:

 calc_image_resized_size(size => "2592x1944", resize => "x768^");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #14:

 calc_image_resized_size(size => "2592x1944", resize => "x7680^");

Result:

 [200, "OK (envelope generated)", "10240x7680"]

=item * Example #15:

 calc_image_resized_size(size => "2592x1944", resize => "20000x10000");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #16:

 calc_image_resized_size(size => "2592x1944", resize => "20000x1000");

Result:

 [200, "OK (envelope generated)", "1333x1000"]

=item * Example #17:

 calc_image_resized_size(size => "2592x1944", resize => "100x200");

Result:

 [200, "OK (envelope generated)", "100x75"]

=item * Example #18:

 calc_image_resized_size(size => "2592x1944", resize => "100x100");

Result:

 [200, "OK (envelope generated)", "100x75"]

=item * Example #19:

 calc_image_resized_size(size => "2592x1944", resize => "10000x5000^");

Result:

 [200, "OK (envelope generated)", "10000x7500"]

=item * Example #20:

 calc_image_resized_size(size => "2592x1944", resize => "5000x10000^");

Result:

 [200, "OK (envelope generated)", "13333x10000"]

=item * Example #21:

 calc_image_resized_size(size => "2592x1944", resize => "100x100^");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #22:

 calc_image_resized_size(size => "2592x1944", resize => "100x100!");

Result:

 [200, "OK (envelope generated)", "100x100"]

=item * Example #23:

 calc_image_resized_size(size => "2592x1944", resize => "10000x5000>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #24:

 calc_image_resized_size(size => "2592x1944", resize => "5000x10000>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #25:

 calc_image_resized_size(size => "2592x1944", resize => "3000x1000>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #26:

 calc_image_resized_size(size => "2592x1944", resize => "2000x1000>");

Result:

 [200, "OK (envelope generated)", "1333x1000"]

=item * Example #27:

 calc_image_resized_size(size => "2592x1944", resize => "100x100>");

Result:

 [200, "OK (envelope generated)", "100x75"]

=item * Example #28:

 calc_image_resized_size(size => "2592x1944", resize => "10000x5000<");

Result:

 [200, "OK (envelope generated)", "10000x7500"]

=item * Example #29:

 calc_image_resized_size(size => "2592x1944", resize => "5000x10000<");

Result:

 [200, "OK (envelope generated)", "13333x10000"]

=item * Example #30:

 calc_image_resized_size(size => "2592x1944", resize => "3000x1000<");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #31:

 calc_image_resized_size(size => "2592x1944", resize => "2000x1000<");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #32:

 calc_image_resized_size(size => "2592x1944", resize => "100x100<");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #33:

 calc_image_resized_size(size => "2592x1944", resize => "1024^>");

Result:

 [200, "OK (envelope generated)", "1365x1024"]

=item * Example #34:

 calc_image_resized_size(size => "2592x1944", resize => "10240^>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #35:

 calc_image_resized_size(size => "2592x1944", resize => "1024^<");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #36:

 calc_image_resized_size(size => "2592x1944", resize => "10240^<");

Result:

 [200, "OK (envelope generated)", "13653x10240"]

=item * Example #37:

 calc_image_resized_size(size => "2592x1944", resize => "^1024>");

Result:

 [200, "OK (envelope generated)", "1024x768"]

=item * Example #38:

 calc_image_resized_size(size => "2592x1944", resize => "^10240>");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #39:

 calc_image_resized_size(size => "2592x1944", resize => "^1024<");

Result:

 [200, "OK (envelope generated)", "2592x1944"]

=item * Example #40:

 calc_image_resized_size(size => "2592x1944", resize => "^10240<");

Result:

 [200, "OK (envelope generated)", "10240x7680"]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<resize>* => I<str>

Resize instruction, follows ImageMagick format.

Resize instruction can be given in several formats:

 Syntax                     Meaning
 -------------------------- ----------------------------------------------------------------
 ""                         No resizing.
 
 SCALE"%"                   Height and width both scaled by specified percentage.
 SCALEX"%x"SCALEY"%"        Height and width individually scaled by specified percentages. (Only one % symbol needed.)
 
 WIDTH                      Width given, height automagically selected to preserve aspect ratio.
 WIDTH">"                   Shrink width if larger, height automagically selected to preserve aspect ratio.
 WIDTH"^"                   Enlarge width if smaller, height automagically selected to preserve aspect ratio.
 
 "x"HEIGHT                  Height given, width automagically selected to preserve aspect ratio.
 "x"HEIGHT">"               Shrink height if larger, width automagically selected to preserve aspect ratio.
 "x"HEIGHT"^"               Enlarge height if smaller, width automagically selected to preserve aspect ratio.
 
 WIDTH"x"HEIGHT             Maximum values of height and width given, aspect ratio preserved.
 WIDTH"x"HEIGHT"^"          Minimum values of height and width given, aspect ratio preserved.
 WIDTH"x"HEIGHT"!"          Width and height emphatically given, original aspect ratio ignored.
 WIDTH"x"HEIGHT">"          Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).
 WIDTH"x"HEIGHT"<"          Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).
 
 NUMBER"^>"                 Shrink shortest side if larger than number, aspect ratio preserved.
 NUMBER"^<"                 Enlarge shortest side if larger than number, aspect ratio preserved.
 "^"NUMBER">"               Shrink longer side if larger than number, aspect ratio preserved.
 "^"NUMBER"<"               Enlarge longer side if larger than number, aspect ratio preserved.

Currently unsupported:

 AREA"@"                    Resize image to have specified area in pixels. Aspect ratio is preserved.
 X":"Y                      Here x and y denotes an aspect ratio (e.g. 3:2 = 1.5).

Ref: L<http://www.imagemagick.org/script/command-line-processing.php#geometry>

=item * B<size>* => I<str>

ImageE<sol>video size, in <widthE<gt>x<heightE<gt> format, e.g. 2592x1944.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 image_resize_notation_to_human

Usage:

 image_resize_notation_to_human(%args) -> [$status_code, $reason, $payload, \%result_meta]

Translate ImageMagick-like resize notation (e.g. "720^E<gt>") to human-friendly text (e.g. "shrink shortest side to 720px").

Examples:

=over

=item * Example #1:

 image_resize_notation_to_human(resize => ""); # -> [200, "OK (envelope generated)", "no resizing"]

=item * Example #2:

 image_resize_notation_to_human(resize => "50%"); # -> [200, "OK (envelope generated)", "scale to 50%"]

=item * Example #3:

 image_resize_notation_to_human(resize => "50%x50%");

Result:

 [
   200,
   "OK (envelope generated)",
   "scale width to 50%, height to 50%",
 ]

=item * Example #4:

 image_resize_notation_to_human(resize => 720); # -> [200, "OK (envelope generated)", "set width to 720px"]

=item * Example #5:

 image_resize_notation_to_human(resize => "720>"); # -> [200, "OK (envelope generated)", "shrink width to 720px"]

=item * Example #6:

 image_resize_notation_to_human(resize => "720^"); # -> [200, "OK (envelope generated)", "enlarge width to 720px"]

=item * Example #7:

 image_resize_notation_to_human(resize => "x720"); # -> [200, "OK (envelope generated)", "set height to 720px"]

=item * Example #8:

 image_resize_notation_to_human(resize => "x720>"); # -> [200, "OK (envelope generated)", "shrink height to 720px"]

=item * Example #9:

 image_resize_notation_to_human(resize => "x720^"); # -> [200, "OK (envelope generated)", "enlarge height to 720px"]

=item * Example #10:

 image_resize_notation_to_human(resize => "640x480"); # -> [200, "OK (envelope generated)", "fit image inside 640x480"]

=item * Example #11:

 image_resize_notation_to_human(resize => "640x480^");

Result:

 [
   200,
   "OK (envelope generated)",
   "fit image to fit 640x480 inside it",
 ]

=item * Example #12:

 image_resize_notation_to_human(resize => "640x480>");

Result:

 [
   200,
   "OK (envelope generated)",
   "shrink image to fit inside 640x480",
 ]

=item * Example #13:

 image_resize_notation_to_human(resize => "640x480<");

Result:

 [
   200,
   "OK (envelope generated)",
   "enlarge image to fit 640x480 inside it",
 ]

=item * Example #14:

 image_resize_notation_to_human(resize => "640x480!");

Result:

 [200, "OK (envelope generated)", "set dimension to 640x480"]

=item * Example #15:

 image_resize_notation_to_human(resize => "720^>");

Result:

 [
   200,
   "OK (envelope generated)",
   "shrink shortest side to 720px",
 ]

=item * Example #16:

 image_resize_notation_to_human(resize => "720^<");

Result:

 [
   200,
   "OK (envelope generated)",
   "enlarge shortest side to 720px",
 ]

=item * Example #17:

 image_resize_notation_to_human(resize => "^720>");

Result:

 [200, "OK (envelope generated)", "shrink longest side to 720px"]

=item * Example #18:

 image_resize_notation_to_human(resize => "^720<");

Result:

 [
   200,
   "OK (envelope generated)",
   "enlarge longest side to 720px",
 ]

=back

Resize notation supports most syntax from ImageMagick geometry. See
L<Math::Image::CalcResized> and ImageMagick documentation on geometry for more
details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<resize>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Math-Image-CalcResized>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Math-Image-CalcResized>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Image-CalcResized>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
