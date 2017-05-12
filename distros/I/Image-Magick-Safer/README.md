# NAME

Image::Magick::Safer - Wrap Image::Magick Read method to check magic bytes

<div>

    <a href='https://travis-ci.org/Humanstate/image-magick-safer?branch=master'><img src='https://travis-ci.org/Humanstate/image-magick-safer.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/image-magick-safer?branch=master'><img src='https://coveralls.io/repos/Humanstate/image-magick-safer/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.07

# SYNOPSIS

        use Image::Magick::Safer;

        # functions just like Image::Magick but wraps the Read method
        # to check the magic bytes of any images using File::LibMagic
        my $magick = Image::Magick::Safer->new;

        # if any @files have a MIME type that looks questionable then
        # $e will be populated
        if ( my $e = $magick->Read( @files ) ) {
                # bail out, unsafe to continue
                ....
        }

# DESCRIPTION

Image::Magick::Safer is a drop in wrapper around Image::Magick, it adds a
magic byte check to the `Read` method to check the file MIME type using
[File::LibMagic](https://metacpan.org/pod/File::LibMagic). If a file looks questionable then it will prevent the file
being passed to the real Image::Magick::Read method and return an error.
If a file cannot be opened, because it does not exist or it is prefixed
with a pipe, an error will also be returned.

You can replace any calls to `Image::Magick` with `Image::Magick::Safer`
and the functionality will be retained with the added Read protection. The
aliases for `Read` will also be made safe.

If you need to override the default MIME types then you can set the modules
`$Image::Magick::Safer::Unsafe` hash to something else or add extra types:

        # add SVG check to the defaults
        $Image::Magick::Safer::Unsafe->{'image/svg+xml'} = 1;

The default MIME types considered unsafe are as follows:

        text/plain
        application/x-compress
        application/x-compressed
        application/gzip
        application/bzip2
        application/x-bzip2
        application/x-gzip
        application/x-rar
        application/x-z
        application/z

Leading pipes are also considered unsafe, as well as any reference to files
that cannot be found.

Note that i make **NO GUARANTEE** that this will fix and/or protect you from
exploits, it's just another safety check. You should update to the latest
version of ImageMagick to protect yourself against potential exploits.

Also note that to install the [File::LibMagic](https://metacpan.org/pod/File::LibMagic) module you will need to have
both the library (libmagic.so) and the header file (magic.h). See the perldoc
for [File::LibMagic](https://metacpan.org/pod/File::LibMagic) for more information.

# WHY ISN'T THIS A PATCH IN Image::Magick?

Image::Magick moves at a glacial pace, and involves a 14,000 line XS file. No
thanks. This will probably get patched in the next version, so for the time
being this module exists.

# KNOWN BUGS

DOES NOT WORK with BSD 10.1 and 7.0.1 and i can't figure out why. If you can
figure out why then please submit a pull request. This is possibly some libmagic
weirdness going on.

# SEE ALSO

[Image::Magick](https://metacpan.org/pod/Image::Magick) - the library this module wraps

[https://www.imagemagick.org](https://www.imagemagick.org) - ImageMagick

[https://imagetragick.com/](https://imagetragick.com/) - ImageMagick exploits

[http://permalink.gmane.org/gmane.comp.security.oss.general/19669](http://permalink.gmane.org/gmane.comp.security.oss.general/19669) -
GraphicsMagick and ImageMagick popen() shell vulnerability via filename

# AUTHOR

Lee Johnson - `leejo@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/image-magick-safer
