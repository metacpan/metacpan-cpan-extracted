Fuse::TagLayer
==============

A read-only tag-filesystem overlay for hierarchical filesystems

## SYNOPSIS

The Fuse::TagLayer bundle consists of the backend module _Fuse::TagLayer_, which you
probably want to use through the _taglayer_ mounting script:

    taglayer <real directory> <tag directory mountpoint>

## DESCRIPTION

Fuse::TagLayer offers all the tags found in one subdir/volume as a tag-based file-system
at the mountpoint you specify, currently read-only. This is in addition to the real
filesystem which is considered to be 'canonical' - with the tag-file-system being
just another "layer" to access these files (thus the name).

Please note:

This here is only a short github placeholder README. More information about
how to use the mounting script _taglayer_ and the _Fuse::TagLayer_ module can be found
in the POD embedded in the source code. So, please hop over to _cpan_ for canonical the
[documentation](http://search.cpan.org/perldoc?Fuse%3A%3ATagLayer).

## INSTALLATION

via CPAN (official releases):

    sudo cpan -i Fuse::TagLayer

from command-line (latest changes, if any):

    wget https://github.com/clipland/fuse-taglayer/archive/master.tar.gz
    tar xvf master.tar.gz
    cd fuse-taglayer-master
    perl Makefile.PL
    make
    make test
    sudo make install

## AUTHOR

Clipland GmbH, [clipland.com](http://www.clipland.com/)

## COPYRIGHT & LICENSE

Copyright 2012-2013 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under [GPLv3](http://www.gnu.org/licenses/gpl)/[AL2](http://opensource.org/licenses/Artistic-2.0).
You can redistribute it and/or modify it under the same terms as Perl itself.
