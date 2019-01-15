# Graphics-Framebuffer

### Note, this module does NOT work (natively) in Microsoft Windows

## PREREQUISITES

This module REQUIRES access to the video framebuffer, usually "/dev/fb0".
You must be using a video device and driver that exposes this device to
software.  Video cards with their proprietary drivers are not likely to work.
However, most open-sourced drivers, seem to work fine.  VirtualBox drivers
work too.  You must also have the appropriate permissions to write to this
device (usually membership with group "video").

### ATTENTION CPAN TESTERS!  Please make sure the above is noted before testing (and marking a fail)

I highly recommend you install the system (or package) version of the "Imager"
library, as it is already pre-compiled with all the needed C libraries for it
to work with this module.  In Yum (RedHat) and Aptitude (Debian/Ubuntu) this
module is called "libimager-perl" (or "perl-libImager").  However, if you
desire to install it yourself, please do it manually, and not via CPAN.  When
you do it manually, you can see the missing C libraries it is looking for in
the "Makefile.PL" process and stop it there.  You can then install these
libraries until it no longer says something is missing.  You see, it just
turns off functionality if it can't find a library (when installing from CPAN),
instead of stopping.  Libraries usually missing are those for GIF, JPEG, PNG,
TrueType and FreeType fonts.  These are necessary not optional, if you wish to
be able to work with fonts and images.

The "build-essential" tools need to be installed. This is generally a C
compiler, linker, and standard C libraries (usually gcc variety).  The module
"Inline::C", which this module uses, requires it.  Also, the package
"kernel-headers".

## INSTALLATION

You SHOULD install this module from the console, not X-Windows.

To make your system ready for this module, then please install the following:

### DEBIAN BASED SYSTEMS (Ubuntu, Mint, Raspian, etc):

`sudo apt-get update`
  
`sudo apt-get install build-essential linux-headers-generic libimager-perl libinline-c-perl libmath-gradient-perl libmath-bezier-perl libfile-map-perl`

### REDHAT BASED SYSTEMS (Fedora, CentOS, etc):

`sudo yum update`

`sudo yum upgrade kernel-headers build-essential perl-math-gradient perl-math-bezier perl-file-map perl-imager perl-inline-c`

### Continuing...

With that out of the way, you can now install this module.

To install this module, run the following commands:

`perl Makefile.PL`

`make`

`make test`

`make install`

NOTE:  _The install step may require sudo (root access)._

## FURTHER TEST SCRIPTS

To test the installation properly.  Log into the text console (not X).
Go to the 'examples' directory and run 'primitives.pl'.  It basically calls
most of the features of the module.

The script 'threadstest.pl' requires 'Sys::CPU'.  It is not listed as a
prerequisite for this module (as it isn't), but if you want to run this
one script, then this is a required module.  It demonstrates how to use this
module in a threaded environment.

## GETTING STARTED

There is a script template in the "examples" directory in this package.  You
can use it as a starting point for your script.  It is conveniently called
"template.pl".

## COMPATIBILITY vs. SPEED

This module, suprisingly, runs on a variety of hardware with accessible
framebuffer devices.  The only limitation is CPU power.

Some lower clocked ARM devices may be too slow for practical use of all of the
methods in this module, but the best way to find out is to run
'examples/primitives.pl' to see which are fast enough to use.

Here's what I have tested this module on (all 1920x1080x32):

* **Raspberry PI2** - Tollerable, I did 16 bit mode testing and coding on this machine.  Using a Perlbrew custom compiled Perl helps a bit.  The Raspberry PI (and RP2) are configured, by default, to be in 16 bit graphics mode.  This is not the best mode if you are going to be loading images or rendering TrueType text, as color space conversions can take a long time (with acceleration off).  Overall, 32 bit mode works best on this machine, especially for image loading and text rendering.  This can, however, be minimized using the C acceleration features.

* **Odroid XU3/XU4**  - Surprisingly fast.  All methods plenty fast enough for heavy use.  Works great with threads too, 8 of them (when done properly).  Most coding for this module is done on this machine at 1920x1080x32.  This is fast enough for full screen (1920 x 1080 or less) animations at 30 fps.  If your resolution is lower, then your FPS rating will be higher.

* **Atom 1.60 GHz with NVidia Nouveau driver** - Decent, not nearly as fast as the Odroid XU3/4.  Works good with threads too (when done properly).  Great for normal graphical apps and static displayed output.

* **2.6 GHz MacBook with VirtualBox** - Blazingly fast. Most primitives draw nearly instantly.

* **Windows 10 PC with VirtualBox, 4GHz 6 core CPU, 2 NVidia GeForce 970 Ti** - Holy cow!  No, seriously, this sucker is fast!  I wonder how much faster if it were running Linux natively?

  In addition, 3840x2160x32 (4K) is surprisingly fast.  Who'd have thought?  Full screen animations were choppy, but everything else was plenty fast enough.

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

`perldoc Graphics::Framebuffer`

or

`man Graphics::Framebuffer`

You can also look for information at:

* **RT, CPAN's request tracker (report bugs here)** - http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graphics-Framebuffer

* **AnnoCPAN, Annotated CPAN documentation** - http://annocpan.org/dist/Graphics-Framebuffer

* **CPAN Ratings** - http://cpanratings.perl.org/d/Graphics-Framebuffer

* **Search CPAN** - http://search.cpan.org/dist/Graphics-Framebuffer/

* **YouTube** - https://youtu.be/4Yzs55Wpr7E

## LICENSE AND COPYRIGHT

Copyright (C) 2013-2016 Richard Kelsch

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
