Animated JPEG
=============

Proposed JPEG/JFIF APP0 marker application extension for playback control of
concatenated JPEGs as stand-alone animation stream or Motion-JPEG.

## DESCRIPTION

This repository provides a reference implementation of the proposed _Animated
JPEG_ standard through a collection of routines and helper scripts in Perl.
Bundled scripts illustrate how to form a single "animated jpeg file" out of a
number of single images, and how to revert this non-destructive process, by
allowing a user to extract single images from an "animated jpeg file" and
store these frames as individual files again.

An _Animated JPEG file_ is a stream of concatenated individual JPEG files, then
representing a frame within the animation. This is similar to the non-standard
Motion-JPEG (MJPEG) format, but with additional metadata to control the
animation, stored along with the first frame, or each subsequent, added as APP0
marker application data segment.

Why?

Animated JPEG files are more efficient than animated GIFs. That said, the file
format described here is simply a concatenation of JPEGs, so there is no
inter-frame compression, resulting in lower overall compression in comparison
with modern video formats.

Animated JPEG files are very suitable for flip-book like short animations, with
low frame-rates. Each frame can have it's own display duration - uncommon or not
possible with most video containers.

As adding and removing the control APP0 tag to a JPEG does not trigger a
recompression of the actual image data payload, forming an animation, or
breaking it into individual files again, is a lossless (no new "generation")
JPEG/JFIF transform and non-destructive.

MJPEG commonly has no "playback control" metadata embedded. Frame rate is either
set via HTTP header (not available when the stream is not served by a web
server) or assumed by the player application (to be a common video frame-rate
of about 25fps; try mplayer, avplay, vlc). AJPEG offers a facility to set fps,
and current specs define a default of 10 frames-per-second.

## SPECIFICATIONS

Please refer to the [Official Specifications](SPECIFICATIONS.md) for details.

## REFERENCE IMPLEMENTATION

Bundled with this distribution is a reference implementation, written in Perl,
[Image::Animated::JPEG](http://search.cpan.org/perldoc?Image::Animated::JPEG).

### INSTALLATION

To install this implementation and accompanying scripts, do this on
command-line:

    wget https://github.com/clipland/animated-jpeg/archive/master.tar.gz
    tar xvf master.tar.gz
    cd animated-jpeg-master
    perl Makefile.PL
    make
    make test
    sudo make install

or, via CPAN:

    sudo cpan -i CLIPLAND/Image-Animated-JPEG-0.01.tar.gz

If you'd like to set a MIME-Type for AJPEGs on your system and want to play
such files with bundled playajpeg, then there's a .desktop and a .xml file
in the /debian directory of this release. For a local install, on Ubuntu/Linux
do this:

    cp ./debian/image-ajpeg.xml ~/.local/share/mime/packages/image-ajpeg.xml
    cp ./debian/playajpeg.desktop ~/.local/share/applications/playajpeg.desktop
    update-mime-database ~/.local/share/mime
    update-desktop-database ~/.local/share/applications    

### CAVEATS

This is alpha quality software. Do not test it on important data or files.

## SEE ALSO

Related technology:

* [Motion-JPEG](http://en.wikipedia.org/wiki/Motion_JPEG)
* [Animated GIF](http://en.wikipedia.org/wiki/GIF#Animated_GIF)
* [Animated PNG, APNG specs](https://wiki.mozilla.org/APNG_Specification#Structure)
* [Multiple-image Network Graphics, MNG](http://en.wikipedia.org/wiki/Multiple-image_Network_Graphics)
* [WebP animation](http://en.wikipedia.org/wiki/WebP)
* AVI container with JPEG codec

## AUTHOR

Clipland GmbH, [clipland.com](http://www.clipland.com/)

## COPYRIGHT & LICENSE

Copyright 2013-2017 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under [GPLv3](http://www.gnu.org/licenses/gpl)
and [Perl Artistic 2](http://opensource.org/licenses/Artistic-2.0).
You can redistribute it and/or modify it under the same terms as Perl itself.

AJPEG specifications are licensed to the public under the GNU Free Documentation
License (GNU FDL or GFDL) Version 1.3.
