# Linux-Info

API in Perl to recover information about the running Linux OS

## DESCRIPTION

Linux::Info is a fork from [Sys::Statistics::Linux](http://search.cpan.org/~bloonix/Sys-Statistics-Linux/) distribution.

Linux::Info is a front-end module to gather different linux
system information like processor workload, memory usage, network and
disk statistics and a lot more. Refer the documentation of the
distribution modules to get more information about all possible
statistics.

By obvious reasons, this distribution will run only at Linux O.S.

## MOTIVATION

Sys::Statistics::Linux is a great distribution (and I used it a lot),
but it was built to recover only Linux statistics when I was also
looking for other additional information about the OS.

Linux::Info will provide additional information not available in
Sys::Statistics::Linux, as general processor information and hopefully
apply patches and suggestions not implemented in the original project.

Sys::Statistics::Linux is also more forgiving regarding compatibility
with older perls interpreters, modules version that it depends on and
even older OS. If you find that Linux::Info is not available to your old
system, you should try it.

## INSTALL

To install this module, unpack the downloaded tarball and execute the following
commands in the created directory:

```
perl Makefile.PL
make
make install
```

Linux::Info is also available on CPAN, so you can also download and install automatically 
this distribution, dependencies included, by using the CPAN shell (or CPAN Minus or whatever 
you prefer).

## COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas
Junior, <arfreitas@cpan.org>

This file is part of Linux Info project.

Linux Info is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

Linux Info is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with Linux Info. If not, see (http://www.gnu.org/licenses/).

