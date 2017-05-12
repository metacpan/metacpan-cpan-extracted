Fuse::PerlSSH::FS
=================

Mount a remote filesystem via FUSE and PerlSSH

## SYNOPSIS

The Fuse::PerlSSH::FS bundle consists of the backend module _Fuse::PerlSSH::FS_, which you
probably want to use through the _perlsshfs_ mounting script:

    perlsshfs [user@]host:[dir] mountpoint [options]

## DESCRIPTION

Fuse::PerlSSH::FS is meant as a drop-in replacement for
[sshfs](http://fuse.sourceforge.net/sshfs.html), written in Perl. The primary goal, for
now, is to add extended file attribute (xattr) functionality to the mounted filesystem
and only later to achieve the full feature-level of sshfs.

Please note:

This here is only a short github placeholder README. More information about
how to use the mounting script _perlsshfs_ and the _Fuse::PerlSSH::FS_ module can be
found in the POD embedded in the source code. So, please hop over to _cpan_ for the 
canonical [documentation](http://search.cpan.org/perldoc?Fuse%3A%3APerlSSH%3A%3AFS).

## INSTALLATION

via CPAN (official releases):

    sudo cpan -i Fuse::PerlSSH::FS

from command-line (latest changes, if any):

    wget https://github.com/clipland/fuse-perlssh-fs/archive/master.tar.gz
    tar xvf master.tar.gz
    cd fuse-perlssh-fs-master
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
