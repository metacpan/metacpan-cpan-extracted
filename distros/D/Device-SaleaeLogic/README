Device-SaleaeLogic version 0.02
===============================

This module provides a direct mapping of the Saleae Device SDK version 1.1.14
into perl using XS for the logic analyzer made by Saleae Logic.

#SUPPORTED OS

- Linux 32 bit (x86)
- Linux 64 bit (x86_64)
- Mac OSX 32 bit (x86)
- Windows 32 bit (x86)

The reason for only the above OSes being supported is that the Device SDK
provides libraries only for the above OSes. You will need a 32-bit Perl for
running it in case you're using Mac OSX 64-bit and Windows 64-bit.

If you are desperate to use 64-bit on Mac OSX or Windows, then you are better
off using Saleae Logic's GUI software instead of this module.

#PRE-REQUISITES

- ExtUtils::MakeMaker
- File::ShareDir::Install
- LWP::Simple
- Archive::Zip
- Test::More

#BUILD PROCESS

At the command prompt type the following. This step will download the SDK from
SaleaeLogic and build everything.

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

On Windows, if using Strawberry Perl, you may need to use `dmake`.

#RUNTIME PRE-LOAD PRE-REQUISITES

Despite the fact that `Makefile.PL` tries to install the Saleae Device SDK
libraries in the right spot, they may not be present when the Perl module is
loading it up or it doesn't find it correctly sometimes.

You may want to make sure that the distributed library `libSaleaeDevice.so` or
`libSaleaeDevice.dylib` or `SaleaeDevice.dll` is placed in the appropriate
library paths like `/usr/lib` or set the appropriate environment variables for
it to get loaded.

_NOTE_: If you know of a better way to do this, please provide a patch or let me
know.

#EXAMPLE

There is a simple example on how to use the SDK and it works with any number of
devices connected to the system via USB.

    $ ./share/example.pl

This example will detect if a Saleae Logic or Logic16 has been connected,
receive some data from it for some time, and then stop receiving the data. It
will also print all the device information on screen.

This example demonstrates how to use the API.

#LINUX UDEV RULES

We provide a sample `udev` rule for Linux in the file
`share/99-SaleaeLogic.rules`.

#CONTRIBUTORS

- Vikas N Kumar [@vikasnkumar](https://github.com/vikasnkumar/)

#COPYRIGHT

Copyright (C) 2014 by Vikas N Kumar <vikas@cpan.org>

Read the LICENSE file for information.
