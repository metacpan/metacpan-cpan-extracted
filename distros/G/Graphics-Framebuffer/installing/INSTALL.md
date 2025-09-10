# Installing Graphics::Framebuffer Instructions

## DETERMINING IF YOUR SYSTEM HAS A FRAMEBUFFER FIRST

  You need to make sure your system has a Framebuffer driver installed.  The
  easiest way to find this out, is to look in the "/dev" directory and see if
  there are files in there called "fb" and end with a number between 0 and 31.
  Most systems have "/dev/fb0", but there can be more.

  If such a file exists, then you have a framebuffer.

  If no such file exists, then you need to either learn how to enable it, or
  as a last resort, you can use the VESA video drivers that are minimalist
  framebuffer devices.  This usually involves editing the grub configuration
  files and passing the video type to the kernel command line.  This is
  typically the "vga" variable.

  * Mario Roy has an excellent tutorial on enabling the Framebuffer on a
     CentOS system.  This may be helpful on other distributions as well:

     [Mario Roy's Explation of enabling the Framebuffer on CentOS](https://github.com/marioroy/mce-examples/tree/master/framebuffer)

  * Raspberry PI Users!  Change the settings to use a 24/32 bit framebuffer.
     The PI defaults to 16 bit color and this module is much faster using
	 24/32 bit color mode.  This module's 16 bit mode is a hack layered on
	 top of the 24/32 bit routines, so more CPU time is involved in
	 conversion.

## MAKE SURE YOUR USER ACCOUNT HAS ACCESS TO THE VIDEO DEVICE

     sudo usermod -a -G video username

Change "username" with the username of your account

## DETERMINE YOUR DISTRIBUTION

  There are various distributions of operating systems this module should work
  on.  Those are POSIX or Unix like systems that map devices to the file
  system.  This includes, but is not limited to Unix, Linux, and BSD.

  The two I will concentrate on in this document are Debian and RedHat based
  Linux distributions.

  Debian distributions use "apt" utility to manage packages.  Debian
  distributions are typically:

*  Debian
*  Ubuntu
*  Kubuntu
*  Xubuntu
*  Mint
*  Raspian

  RedHat distributions use the "yum" utility to manage packages.  RedHat
  distributions are typically:

*  RedHat
*  Fedora
*  CentOS
*  ClearOS
*  Scientific Linux
*  SME
*  Aurora
*  Berry
*  Yellow Dog

  I have added two shell scripts to make installation of this module very easy.

  For Debian based systems:

    installing/install-prerequisites-debian.sh

  For RedHat based systems:

    installing/install-prerequesites-redhat.sh

  I have also included a script to detect the type of distribution you have.
  It's not 100% accurate, but usually works:

    detect.sh

  Pick the appropriate prerequisie script to run.

  It will install the absolute minimum packages on your system needed to use
  this module.

  Next it will ask you if you are using the packaged version of Perl, the one
  included in your distribution.  If you are, then you need to answer "yes"
  to the question and allow it to install the Perl prerequisites.

### INSTALLING LINUX ON VIRTUAL BOX WITH EFI

   If your distribution of Linux has EFI install capability, then I encourage you install that version and set up the virtual machine accordingly.

   Make sure NOTHING VirtualBox is running, not the GUI nor any virtual machine.  This is *important*.

   Open the "vbox" definition file in you virtual machine directory in your favorite text editor.  You will see it is an XML file.  Look for the ```<ExtraData>``` section (usually near the beginning).  It is likely there are already items called ```ExtraDataItem``` listed in there.  Insert the following "ExtraDataItem" at the end of that list, before ```</ExtraData>```, so it looks something like this:

   ```
      <ExtraData>

		 <ExtraDataItem name="VBoxInternal2/EfiGraphicsResolution" value="3840x2160"/>
      </ExtraData>
   ```

   You can change "3840x2160" to any sane resolution you wish.

   Using the EFI install means no need to fiddle with Grub.  VirtualBox already has a framebuffer for EFI.  Just make sure that you install the extensions (and re-install everytime the Kernel is updated)

## INSTALLING WITH PACKAGED PERL

  Acquiring (use only one method):
  
*  Use CPAN, run (inside CPAN):

       install Graphics::Framebuffer

*  ```git clone https://github.com/richcsst/Graphics-Framebuffer.git```

       perl Makefile.PL
       make
       make test
       [sudo] make install

## INSTALLING WITH PERLBREW (and installing Perlbrew)

  If you do not want to use the package version of Perl, but would rather use
  a customized and more optimized version of Perl, then do the following:

       wget -O - https://install.perlbrew.pl | bash

  Append the following line to your " ~/.bash_profile " then log out and log in
  again:

       source ~/perl5/perlbrew/etc/bashrc

  Now to install Perlbrew (you can use higher or lower version numbers where applicable):

       perlbrew init
       perlbrew install-cpanm
       perlbrew install-patchperl
       perlbrew install -n perl-5.40 -Dusethreads
       perlbrew clean
       perlbrew switch perl-5.40
       cpanm -n Inline Inline::C Math::Bezier Math::Gradient
	   cpanm -n File::Map Imager Term::ReadKey Test::Most File::Map
	   cpanm -n MCE::Shared Sereal::Encoder Sereal::Decoder Sys::CPU
	   cpanm -n Graphics::Framebuffer
