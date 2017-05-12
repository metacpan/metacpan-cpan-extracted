package Display::Resolution;

our $DATE = '2016-10-07'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       get_display_resolution_name
                       get_display_resolution_size
                       list_display_resolution_names
               );

our %SPEC;

our $size_re = qr/\A(\d+)\s*[x*]\s*(\d+)\z/;

our %res_sizes = (
    'QQVGA'     => '160x120', # one fourth QVGA
    'qqVGA'     => '160x120',

    'HQVGA'     => '240x160', # half QVGA

    'QVGA'      => '320x240', # one quarter VGA

    'WQVGA'     => '400x240',

    # XXX there are actually variants of HVGA, e.g. 480x270, 640x240, ...
    'HVGA'      => '480x320', # half VGA

    'VGA'       => '640x480',
    'SD'        => '640x480',

    '480p'      => '720x480',

    'WVGA'      => '768x480',
    'WGA'       => '768x480',

    'FWVGA'     => '854x480',

    '576p'      => '720x576',

    'qHD'       => '960x540', # one quarter of full HD

    'SVGA'      => '800x600',
    'UVGA'      => '800x600',

    # XXX WSVGA also has resolution 1024x576
    'WSVGA'     => '1024x600',

    'DGA'       => '960x640', # double-size vga

    'HD'        => '1280x720',
    '720p'      => '1280x720',
    'WXGA 16:9' => '1280x720',

    'XGA'       => '1024x768',

    'WXGA 5:3'  => '1280x768',

    'WXGA 16:10'=> '1280x800',

    'XGA+'      => '1152x864',

    'WXGA+'     => '1440x900',

    'HD+'       => '1600x900',

    'SXGA'      => '1280x1024',

    'Full HD'   => '1920x1080',
    'FHD'       => '1920x1080',
    '1080p'     => '1920x1080',

    'DCI 2K'    => '2048x1080',
    'Cinema 2K' => '2048x1080',

    'UXGA'      => '1600x1200',

    'WUXGA'     => '1920x1200',

    'QHD'       => '2560x1440', # four times HD
    'WQHD'      => '2560x1440',
    '1440p'     => '2560x1440',

    'UWQHD'     => '3440x1440',

    'WQXGA'     => '2560x1600',

    'WQXGA+'    => '3200x1800',
    'QHD+'      => '3200x1800',

    'UHD 4K'    => '3840x2160',
    '4K UHD'    => '3840x2160',
    'UHDTV-1'   => '3840x2160',
    '4K'        => '3840x2160',

    'DCI 4K'    => '4096x2160',
    'Cinema 4K' => '4096x2160',

    'UHD+'      => '5120x2880',
    '5K'        => '5120x2880',

    'UHD 8K'    => '7680x4320',
    '8K UHD'    => '7680x4320',
    'UHDTV-2'   => '7680x4320',
    '8K'        => '7680x4320',

    'UHD 16K'   => '15360x8640',
    '16K UHD'   => '15360x8640',
    '16K'       => '15360x8640',
);

my @res_names = sort keys %res_sizes;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Convert between display resolution size (e.g. 1280x720) '.
        'and name (e.g. HD, 720p)',
};

$SPEC{get_display_resolution_name} = {
    v => 1.1,
    summary => 'Get the known name for a display resolution size',
    description => <<'_',

Will return undef if there is no known name for the resolution size.

_
    args => {
        size => {
            schema => ['str*', match => $size_re],
            pos => 0,
        },
        width => {
            schema => ['posint*'],
        },
        height => {
            schema => ['posint*'],
        },
        all => {
            summary => 'Return all names instead of the first one',
            schema => 'bool',
            description => <<'_',

When set to true, an arrayref will be returned instead of string.

_
            cmdline_aliases => {a=>{}},
        },
    },
    args_rels => {
        choose_all => [qw/width height/],
        req_one    => [qw/size width/],
    },
    result => {
        schema => ['any', of=>['str', ['array*', of=>'str*']]],
    },
    result_naked => 1,
    examples => [
        {
            summary => 'You can specify width and height ...',
            args    => {width => 640, height => 480},
        },
        {
            summary => '... or size directly (in "x x y" or "x*y" format)',
            args    => {size => "1280x720"},
        },
        {
            summary => "Return all names",
            args    => {size => "1280x720", all => 1},
        },
        {
            summary => "Unknown resolution size",
            args    => {size => "999x666"},
        },
    ],
};
sub get_display_resolution_name {
    my %args = @_;

    my $all = $args{all};

    my ($x, $y, $size);
    if (defined $args{size}) {
        ($x, $y) = $args{size} =~ $size_re;
    } else {
        $x = $args{width};
        $y = $args{height};
    }
    $size = "${x}x${y}";

    my @res;
    for my $name (@res_names) {
        if ($res_sizes{$name} eq $size) {
            push @res, $name;
            last unless $all;
        }
    }

    if ($all) {
        return \@res;
    } else {
        return $res[0];
    }
}

$SPEC{get_display_resolution_size} = {
    v => 1.1,
    summary => 'Get the size of a display resolution name',
    description => <<'_',

Will return undef if the name is unknown.

_
    args => {
        name => {
            schema => ['str*'],
            completion => sub {
                require Complete::Util;
                my %args = @_;
                Complete::Util::complete_hash_key(
                    word => $args{word},
                    hash => \%res_sizes,
                );
            },
            req => 1,
            pos => 0,
        },
#        all => {
#            summary => 'Return all names instead of the first one',
#            schema => 'bool',
#            description => <<'_',
#
#When set to true, an arrayref will be returned instead of string.
#
#_
#            cmdline_aliases => {a=>{}},
#        },
    },
    result => {
        #schema => ['any*', of=>['str', ['array*', of=>'str*']]],
        schema => 'str',
    },
    result_naked => 1,
    examples => [
        {
            args    => {name => 'VGA'},
        },
        {
            summary => 'Unknown name',
            args    => {name => 'foo'},
        },
    ],
};
sub get_display_resolution_size {
    my %args = @_;

    #my $all = $args{all};

    my $name = $args{name};

    return $res_sizes{$name};

    #my @res;
    #if ($all) {
    #    return \@res;
    #} else {
    #    return $res[0];
    #}
}

$SPEC{list_display_resolution_names} = {
    v => 1.1,
    result => {
        schema => ['hash*', of=>'str*'],
    },
    result_naked => 1,
    examples => [
        {args=>{}},
    ],
};
sub list_display_resolution_names {
    return \%res_sizes;
}

1;
# ABSTRACT: Convert between display resolution size (e.g. 1280x720) and name (e.g. HD, 720p)

__END__

=pod

=encoding UTF-8

=head1 NAME

Display::Resolution - Convert between display resolution size (e.g. 1280x720) and name (e.g. HD, 720p)

=head1 VERSION

This document describes version 0.002 of Display::Resolution (from Perl distribution Display-Resolution), released on 2016-10-07.

=head1 FUNCTIONS


=head2 get_display_resolution_name(%args) -> str|array[str]

Get the known name for a display resolution size.

Examples:

=over

=item * You can specify width and height ...:

 get_display_resolution_name(height => 480, width => 640); # -> "SD"

=item * ... or size directly (in "x x y" or "x*y" format):

 get_display_resolution_name(size => "1280x720"); # -> "720p"

=item * Return all names:

 get_display_resolution_name(size => "1280x720", all => 1); # -> ["720p", "HD", "WXGA 16:9"]

=item * Unknown resolution size:

 get_display_resolution_name(size => "999x666"); # -> undef

=back

Will return undef if there is no known name for the resolution size.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

Return all names instead of the first one.

When set to true, an arrayref will be returned instead of string.

=item * B<height> => I<posint>

=item * B<size> => I<str>

=item * B<width> => I<posint>

=back

Return value:  (str|array[str])


=head2 get_display_resolution_size(%args) -> str

Get the size of a display resolution name.

Examples:

=over

=item * Example #1:

 get_display_resolution_size(name => "VGA"); # -> "640x480"

=item * Unknown name:

 get_display_resolution_size(name => "foo"); # -> undef

=back

Will return undef if the name is unknown.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name>* => I<str>

=back

Return value:  (str)


=head2 list_display_resolution_names() -> hash

Examples:

=over

=item * Example #1:

 list_display_resolution_names();

Result:

 {
   "1080p"      => "1920x1080",
   "1440p"      => "2560x1440",
   "16K"        => "15360x8640",
   "16K UHD"    => "15360x8640",
   "480p"       => "720x480",
   "4K"         => "3840x2160",
   "4K UHD"     => "3840x2160",
   "576p"       => "720x576",
   "5K"         => "5120x2880",
   "720p"       => "1280x720",
   "8K"         => "7680x4320",
   "8K UHD"     => "7680x4320",
   "Cinema 2K"  => "2048x1080",
   "Cinema 4K"  => "4096x2160",
   "DCI 2K"     => "2048x1080",
   "DCI 4K"     => "4096x2160",
   "DGA"        => "960x640",
   "FHD"        => "1920x1080",
   "Full HD"    => "1920x1080",
   "FWVGA"      => "854x480",
   "HD"         => "1280x720",
   "HD+"        => "1600x900",
   "HQVGA"      => "240x160",
   "HVGA"       => "480x320",
   "qHD"        => "960x540",
   "QHD"        => "2560x1440",
   "QHD+"       => "3200x1800",
   "QQVGA"      => "160x120",
   "qqVGA"      => "160x120",
   "QVGA"       => "320x240",
   "SD"         => "640x480",
   "SVGA"       => "800x600",
   "SXGA"       => "1280x1024",
   "UHD 16K"    => "15360x8640",
   "UHD 4K"     => "3840x2160",
   "UHD 8K"     => "7680x4320",
   "UHD+"       => "5120x2880",
   "UHDTV-1"    => "3840x2160",
   "UHDTV-2"    => "7680x4320",
   "UVGA"       => "800x600",
   "UWQHD"      => "3440x1440",
   "UXGA"       => "1600x1200",
   "VGA"        => "640x480",
   "WGA"        => "768x480",
   "WQHD"       => "2560x1440",
   "WQVGA"      => "400x240",
   "WQXGA"      => "2560x1600",
   "WQXGA+"     => "3200x1800",
   "WSVGA"      => "1024x600",
   "WUXGA"      => "1920x1200",
   "WVGA"       => "768x480",
   "WXGA 16:10" => "1280x800",
   "WXGA 16:9"  => "1280x720",
   "WXGA 5:3"   => "1280x768",
   "WXGA+"      => "1440x900",
   "XGA"        => "1024x768",
   "XGA+"       => "1152x864",
 }

=back

This function is not exported by default, but exportable.

No arguments.

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Display-Resolution>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Display-Resolution>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Display-Resolution>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
