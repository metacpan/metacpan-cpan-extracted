# Graphics::Framebuffer

[![Graphics::Framebuffer Logo](pics/GFB.png?raw=true "Graphics::Framebuffer Click For Demo Video")](https://www.youtube.com/watch?v=X8RpFBq6F9I)

### Windows Incompatibility, Linux Only

![Windows Incompatible](pics/Win-No.png?raw=true "Windows Incompatible") ![Linux Logo](pics/Linux.png?raw=true "Linux Only")

Note, this module does NOT work (natively) in Microsoft Windows.  If run from Windows, it will only function in "emulation" mode, and you will not see any screen output.  See the documentation on emulation mode for more details.

Use a Virtual Machine like VirtualBox or Docker to use on Windows, with a Linux distribution installed.

![Divider](pics/pink.jpg?raw=true "Divider")

## PREREQUISITES

   This module was developed for Linux and only Linux; not because of some fanatical appreciation for Linux, but because of how it accesses a Linux framebuffer.  If you know how to get it to work on Windows, Darwin, or even FreeBSD, then let me know how to do it.  Meanwwhile, it's Linux only.

   This module REQUIRES access to the video framebuffer, usually ```/dev/fb0```.  You must be using a video device and driver that exposes this device to software.  Video cards with their proprietary drivers are not likely to work.  However, most open-sourced drivers, seem to work fine.  VirtualBox drivers work too.  You must also have the appropriate permissions to write to this device (usually membership with group ```video```).

   You may be able to edit the kernel configuration forcing a framebuffer, and compile it in or as a module.

   Sometimes you can force a VESA framebuffer console driver to be loaded by adding a video mode to the grub command line.  You can do this with some proprietary video drivers that don't have their own framebuffer drivers.

   ### ATTENTION CPAN TESTERS!  Please make sure the above is noted before testing (and marking a fail)

   If you want a more detailed instruction than this document, then read ```INSTALL.md```.

   I highly recommend you install the system (or package) version of the "Imager" library, as it is already pre-compiled with all the needed C libraries for it to work with this module.  In Yum (RedHat) and Aptitude (Debian/Ubuntu) this module is called "libimager-perl" (or "perl-libImager").  However, if you desire to install it yourself, please do it manually, and not via CPAN.  When you do it manually, you can see the missing C libraries it is looking for in the ```Makefile.PL``` process and stop it there.  You can then install these libraries until it no longer says something is missing.  You see, it just turns off functionality if it can't find a library (when installing from CPAN), instead of stopping.  Libraries usually missing are those for GIF, JPEG, PNG, TrueType and FreeType fonts.  These are necessary not optional, if you wish to be able to work with fonts and images.

   The "build-essential" tools need to be installed. This is generally a C compiler, linker, and standard C libraries (usually gcc variety).  The module "Inline::C", which this module uses, requires it.  Also, the package "kernel-headers".

   You should also install typical TTF fonts as well.  I suggest the FreeType fonts, the Windows fonts (fonts-wine), Ubuntu fonts (fonts-ubuntu) and anything else you wish to use.

![Divider](pics/pink.jpg?raw=true "Divider")

## OPERATIONAL THEORY

   Linux has a special graphics mode it originally used since its early days called the framebuffer.  It allowed software to draw to the screen without special drivers (as originally Linux didn't have graphics drivers).  All operations were CPU driven.

   Graphics::Framebuffer exploits this feature and allows you to draw to the Linux screen without the overhead and complexity of a GPU driver.  It makes things nearly as easy to draw as they were on old 8 bit computers.

   On Linux, everything is treated as a file path, even hardware.  The framebuffer is just a file that is mapped directly to a Perl string variable.  The way things are "drawn" are by modifying this string.  In the early days of this module, everything was done strictly in Perl and it worked (you can still do that by turning C acceleration off).  However, I have added C code to make things faster.  Since accessing the framebuffer is strictly a CPU operation, you do not have hardware accelerated drawing.  Everything is done by the CPU.  However, today's CPUs are quite fast, even most ARM CPUs and the C code makes it quite fast.

![Divider](pics/pink.jpg?raw=true "Divider")

## INSTALLATION

   You SHOULD install this module from the console, not X-Windows.

   To make your system ready for this module, then please install the following:

   - DEBIAN BASED SYSTEMS (Ubuntu, Mint, Raspian, etc):

      ```bash
      installation/install-prerequisites-debian.sh
      ```

   - REDHAT BASED SYSTEMS (Fedora, CentOS, etc):

      ```bash
      installation/install-prerequisites-redhat.sh
      ```

      You can use the following to detect your distribution type:

      ```bash
      installation/detect.sh
      ```

   - LINUX IN VIRTUALBOX WITH EFI

      Add the following to your "vbox" XML definition file (**do not edit this file while any VirtualBox utility/GUI/VM is running**):

      ```xml
      <ExtraData>
          <ExtraDataItem name="VBoxInternal2/EfiGraphicsResolution" value="3840x2160"/>
      </ExtraData>
      ```

      The "ExtraData" section may already have other definitions in it.  Just place the "ExtraDataItem" as the last definition.  You can Set the resolution to anything sane.

![Divider](pics/pink.jpg?raw=true "Divider")

## Continuing...

   With that out of the way, you can now install this module.

   To install this module, run the following commands:

   ```bash
          perl Makefile.PL
          make
          make test
   [sudo] make install
   ```

   *Build.PL is not supported by Inline::C, and thus not by this module as well.*

![Divider](pics/pink.jpg?raw=true "Divider")

## FURTHER TEST SCRIPTS

   To test the installation properly.  Log into the text console (not X).  Go to the ```examples``` directory and run ```primitives.pl```.  It basically calls most of the features of the module.

   The scripts beginning with 'thread' requires ' *Sys::CPU* '.  It is not listed as a prerequisite for this module (as it isn't), but if you want to run the threaded scripts, then this is a required module.  It demonstrates how to use this module in a threaded environment.

   Mario Roy's MCE test scripts have been added (well, a script to go get them) to demonstrate alternate multiprocessing methods of using Graphics::Framebuffer, even with Perls built without threads support.  You will need to have the modules ```MCE::Shared``` and ```MCE::Hobo``` installed.

![Divider](pics/pink.jpg?raw=true "Divider")

## GETTING STARTED

   There is a script template in the ```examples``` directory in this package.  You can use it as a starting point for your script.  It is conveniently called ```template.pl``` or ```threaded_template.pl```.  I recommend copying it, renaming it, and leaving the original template intact for use on another project.

![Divider](pics/pink.jpg?raw=true "Divider")

## SUPPORT AND DOCUMENTATION

   After installing, you can find documentation for this module with the 'perl-doc' command.

   ```perldoc Graphics::Framebuffer``` *(You may have to install 'perl-doc', but this usually works.)*

   or

   ```man Graphics::Framebuffer``` *(Installing 'perl-doc' usually enables Perl module man pages)*

   You can also look for information at:

   * **Manual** - [MANUAL.md](https://github.com/richcsst/Graphics-Framebuffer/blob/master/MANUAL.md) - A separate indexed manual written in GitHub markdown.  The module POD still exists, but this is easier to read.

   * **MetaCPAN** - [MetaCPAN - Graphics::Framebuffer](https://metacpan.org/pod/Graphics::Framebuffer)

   * **YouTube** - [YouTube](https://www.youtube.com/watch?v=X8RpFBq6F9I)

   * **GitHub** - [GitHub - Graphics-Framebuffer](https://github.com/richcsst/Graphics-Framebuffer)

   * **GitHub Clone** - https://github.com/richcsst/Graphics-Framebuffer.git

   * **Mario Roy's Multiprocessing Examples** - [MCE Examples](https://github.com/marioroy/mce-examples)

![Divider](pics/pink.jpg?raw=true "Divider")

## LICENSE AND COPYRIGHT

   Copyright © 2003-2026 Richard Kelsch

   This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

   See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.

![Divider](pics/pink.jpg?raw=true "Divider")

## MY GITHUB PROJECTS

   * **GitHub** Repositories - [https://github.com/richcsst](https://github.com/richcsst)
