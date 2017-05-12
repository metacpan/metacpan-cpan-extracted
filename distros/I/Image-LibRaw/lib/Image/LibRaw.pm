package Image::LibRaw;
use strict;
use warnings;
our $VERSION = '0.03';
our @ISA;
use 5.008005;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap($VERSION);
};

1;
__END__

=head1 NAME

Image::LibRaw -

=head1 SYNOPSIS

    use Image::LibRaw;
    my $libraw = Image::LibRaw->new();
    $raw->open_file($fname);
    $raw->unpack_thumb;
    $raw->dcraw_thumb_writer('libraw-thumb.jpg');

=head1 DESCRIPTION

Image::LibRaw is a perl binding for libraw.

=head1 METHODS

=over 4

=item my $raw = Image::LibRaw->new();

create a new instance

=item $raw->open_file($fname);

open a file

=item $raw->get_idata();

get a image data.

=item $raw->get_sizes();

get image size informations

=item $raw->get_other();

get other informations

=item $raw->unpack();

unpack the image file to memory

=item $raw->unpack_thumb();

unpack the thumbnail image file to memory

=item $raw->dcraw_thumb_writer($fname);

This method write thumbnail image to the file. You should call ->unpack_thumb() before call this method.

=item $raw->dcraw_ppm_tiff_writer($fname);

This method write image to the file.You should call ->unpack() before call this method.

=item $raw->recycle()

Frees the allocated data of LibRaw instance.

=item $raw->version()

returns  string representation of LibRaw version in MAJOR.MINOR.PATCH-Status format

=item $raw->version_number()

returns integer representation of LibRaw version.

=item $raw->camera_count()

returns the number of cameras supported.

=item $raw->camer_list()

returns list of supported cameras.

=item $raw->rotate_fuji_raw()

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom ah! gmail.comE<gt>

=head1 SEE ALSO

L<http://www.libraw.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as libraw itself.

=cut
