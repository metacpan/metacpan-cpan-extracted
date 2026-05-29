# Installing Graphics::Framebuffer Instructions

[![Graphics::Framebuffer Logo](../pics/GFB.png?raw=true "Graphics::Framebuffer")](https://youtu.be/qU5IFmtHmUo)

## OPERATING SYSTEM REQUIREMENT

   Graphics::Framebuffer only works (for the moment) on Linux.  FreeBSD is planned for the future, but is not yet implemented.

![Divider](../pics/pink.jpg?raw=true "Divider")

## DETERMINING IF YOUR SYSTEM HAS A FRAMEBUFFER FIRST

   You need to make sure your system has a Framebuffer driver installed.  The easiest way to find this out, is to look in the "/dev" directory and see if there are files in there called "fb" and end with a number between 0 and 31.  Most systems have "/dev/fb0", but there can be more.

   If such a file exists, then you have a framebuffer.

   If no such file exists, then you need to either learn how to enable it, or as a last resort, you can use the VESA video drivers that are minimalist framebuffer devices.  This usually involves editing the grub configuration files and passing the video type to the kernel command line.  This is typically the "vga" variable.

   * Mario Roy has an excellent tutorial on enabling the Framebuffer on a CentOS system (which is a RedHat style Linux distribution).  This may be helpful on other distributions as well:

      [Mario Roy's Explation of enabling the Framebuffer on CentOS](https://github.com/marioroy/mce-examples/tree/master/framebuffer)

   * Raspberry PI Users!  Change the settings to use a 24/32 bit framebuffer.  The PI defaults to 16 bit color and this module is much faster using 24/32 bit color mode.  This module's 16 bit mode is a hack layered on top of the 24/32 bit routines, so more CPU time is involved in conversion, and will thus be slower in 16 bit mode.

![Divider](../pics/pink.jpg?raw=true "Divider")

## MAKE SURE YOUR USER ACCOUNT HAS ACCESS TO THE VIDEO DEVICE

   ```bash
   sudo usermod -a -G video username
   ```

   Change "*username*" with the username of your account

![Divider](../pics/pink.jpg?raw=true "Divider")

## DETERMINE YOUR DISTRIBUTION

   There are various distributions of operating systems this module should work on.  Those are POSIX or Unix like systems that map devices to the file system.  This includes, but is not limited to Unix, Linux, and BSD.

   The two I will concentrate on in this document are Debian and RedHat based Linux distributions.

   Debian distributions use "apt" utility to manage packages.  Debian distributions are typically:

   *  Debian
   *  Ubuntu
   *  Kubuntu
   *  Xubuntu
   *  Mint
   *  Raspian
   *  Zorin OS

   RedHat distributions use the "yum" or "dnf" utility to manage packages.  RedHat distributions are typically:

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

   ```bash
   installing/install-prerequisites-debian.sh
   ```

   For RedHat based systems:

   ```bash
   installing/install-prerequesites-redhat.sh
   ```

   I have also included a script to detect the type of distribution you have.  It's not 100% accurate, but usually works:

   ```bash
   detect.sh
   ```

   Pick the appropriate prerequisie script to run.

   It will install the absolute minimum packages on your system needed to use this module.

   Next it will ask you if you are using the packaged version of Perl, the one included in your distribution.  If you are, then you need to answer "yes" to the question and allow it to install the Perl prerequisites.

### INSTALLING LINUX ON VIRTUAL BOX WITH EFI

   If your distribution of Linux has EFI install capability, then I encourage you install that version and set up the virtual machine accordingly.

   Make sure NOTHING VirtualBox is running, not the GUI nor any virtual machine.  This is *important*.

   Open the "vbox" definition file in you virtual machine directory in your favorite text editor.  You will see it is an XML file.  Look for the ```<ExtraData>``` section (usually near the beginning).  It is likely there are already items called ```ExtraDataItem``` listed in there.  Insert the following "ExtraDataItem" at the end of that list, before ```</ExtraData>```, so it looks something like this:

   ```xml
   <ExtraData>
       <ExtraDataItem name="VBoxInternal2/EfiGraphicsResolution" value="3840x2160"/>
   </ExtraData>
   ```

   You can change "3840x2160" to any sane resolution you wish.

   Using the EFI install means no need to fiddle with Grub.  VirtualBox already has a framebuffer for EFI.  Just make sure that you install the extensions (and re-install everytime the Kernel is updated)

![Divider](../pics/pink.jpg?raw=true "Divider")

## INSTALLING

   Acquiring (use only one method):
  
   *  Use CPAN, run (inside CPAN):

      ```
      install Graphics::Framebuffer
      ```

   * From the GitHub repository

      ```bash
      git clone https://github.com/richcsst/Graphics-Framebuffer.git
      ```

      ```bash
             perl Makefile.PL
             make
             make test
      [sudo] make install
             make veryclean
      ```

   *Build.PL is not supported by Inline::C, and thus not by this module as well*.

### perl Makefile.PL (expected output)

![MAkefile.PL](../pics/Makefile.png?raw=true "Makefile.PL")

### make (expected output)

```
cp lib/Graphics/Framebuffer/Splash.pm blib/lib/Graphics/Framebuffer/Splash.pm
cp lib/Graphics/Framebuffer/Mouse.pm blib/lib/Graphics/Framebuffer/Mouse.pm
cp lib/Graphics/Framebuffer.pm blib/lib/Graphics/Framebuffer.pm
"/usr/bin/perl" -Mblib -MInline=NOISY,_INSTALL_ -MGraphics::Framebuffer::Splash -e"my %A = (modinlname => 'Graphics-Framebuffer-Splash.inl', module => 'Graphics::Framebuffer::Splash'); my %S = (API => \%A); Inline::satisfy_makefile_dep(\%S);" 7.03 blib/arch
"/usr/bin/perl" -Mblib -MInline=NOISY,_INSTALL_ -MGraphics::Framebuffer -e"my %A = (modinlname => 'Graphics-Framebuffer.inl', module => 'Graphics::Framebuffer'); my %S = (API => \%A); Inline::satisfy_makefile_dep(\%S);" 7.03 blib/arch
validate Stage
Starting Build Preprocess Stage
get_maps Stage
Finished Build Preprocess Stage

Starting Build Parse Stage
Finished Build Parse Stage

Starting Build Glue 1 Stage
Finished Build Glue 1 Stage

Starting Build Glue 2 Stage
Finished Build Glue 2 Stage

Starting Build Glue 3 Stage
Finished Build Glue 3 Stage

Starting Build Compile Stage
  Starting "perl Makefile.PL" Stage
Generating a Unix-style Makefile
Writing Makefile for Graphics::Framebuffer
Writing MYMETA.yml and MYMETA.json
  Finished "perl Makefile.PL" Stage

  Starting "make" Stage
make[1]: Entering directory '/imported/minty/source/github/Graphics-Framebuffer/_Inline/build/Graphics/Framebuffer'
Running Mkbootstrap for Framebuffer ()
chmod 644 "Framebuffer.bs"
"/usr/bin/perl" -MExtUtils::Command::MM -e 'cp_nonempty' -- Framebuffer.bs blib/arch/auto/Graphics/Framebuffer/Framebuffer.bs 644
"/usr/bin/perl" "/usr/share/perl/5.40/ExtUtils/xsubpp"  -typemap "/usr/share/perl/5.40/ExtUtils/typemap"   Framebuffer.xs > Framebuffer.xsc
mv Framebuffer.xsc Framebuffer.c
x86_64-linux-gnu-gcc -c  -iquote"/imported/minty/source/github/Graphics-Framebuffer" -D_REENTRANT -D_GNU_SOURCE -DDEBIAN -fwrapv -fno-strict-aliasing -pipe -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -g   -DVERSION=\"7.03\" -DXS_VERSION=\"7.03\" -fPIC "-I/usr/lib/x86_64-linux-gnu/perl/5.40/CORE"   Framebuffer.c
rm -f blib/arch/auto/Graphics/Framebuffer/Framebuffer.so
x86_64-linux-gnu-gcc  -shared -L/usr/local/lib -fstack-protector-strong  Framebuffer.o  -o blib/arch/auto/Graphics/Framebuffer/Framebuffer.so  \
      \
  
chmod 755 blib/arch/auto/Graphics/Framebuffer/Framebuffer.so
make[1]: Leaving directory '/imported/minty/source/github/Graphics-Framebuffer/_Inline/build/Graphics/Framebuffer'
  Finished "make" Stage

  Starting "make install" Stage
make[1]: Entering directory '/imported/minty/source/github/Graphics-Framebuffer/_Inline/build/Graphics/Framebuffer'
"/usr/bin/perl" -MExtUtils::Command::MM -e 'cp_nonempty' -- Framebuffer.bs blib/arch/auto/Graphics/Framebuffer/Framebuffer.bs 644
Files found in blib/arch: installing files in blib/lib into architecture dependent library tree
Installing /imported/minty/source/github/Graphics-Framebuffer/blib/arch/auto/Graphics/Framebuffer/Framebuffer.so
make[1]: Leaving directory '/imported/minty/source/github/Graphics-Framebuffer/_Inline/build/Graphics/Framebuffer'
  Finished "make install" Stage

  Starting Cleaning Up Stage
  Finished Cleaning Up Stage

Finished Build Compile Stage

"/usr/bin/perl" -Mblib -MInline=NOISY,_INSTALL_ -MGraphics::Framebuffer::Mouse -e"my %A = (modinlname => 'Graphics-Framebuffer-Mouse.inl', module => 'Graphics::Framebuffer::Mouse'); my %S = (API => \%A); Inline::satisfy_makefile_dep(\%S);" 7.03 blib/arch
Manifying 3 pod documents
```

### make test (expected output)

```
PERL_DL_NONLAZY=1 "/usr/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
```

![GFB Testing](../pics/GFB-Testing.png?raw=true "GFB Testing")

![GFB Perl Splash](../pics/PerlSplash.png?raw=true "GFB Perl Splash")

![GFB C Splash](../pics/CSplash.png?raw=true "GFB C Splash")

```
t/01-splash.t .. skipped: Tests cannot run within X-Windows/Wayland
Files=1, Tests=0,  1 wallclock secs ( 0.00 usr +  0.01 sys =  0.01 CPU)
Result: NOTESTS
```

### _\[sudo\]_ make install (expected output)

```
Manifying 3 pod documents
Files found in blib/arch: installing files in blib/lib into architecture dependent library tree
Appending installation info to /usr/local/lib/x86_64-linux-gnu/perl/5.40.1/perllocal.pod
```

### make veryclean (expected output)

```
rm -f \
  Framebuffer.bso Framebuffer.def \
  Framebuffer.exp Framebuffer.x \
   blib/arch/auto/Graphics/Framebuffer/extralibs.all \
  blib/arch/auto/Graphics/Framebuffer/extralibs.ld Makefile.aperl \
  *.a *.o \
  *perl.core MYMETA.json \
  MYMETA.yml blibdirs.ts \
  core core.*perl.*.? \
  core.[0-9] core.[0-9][0-9] \
  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
  core.[0-9][0-9][0-9][0-9][0-9] libFramebuffer.def \
  mon.out perl \
  perl perl.exe \
  perlmain.c pm_to_blib \
  pm_to_blib.ts so_locations \
  tmon.out 
rm -rf \
  *.inl *bak \
  *log *old \
  Graphics-Framebuffer* _Inline* \
  blib examples/_Inline* 
mv Makefile Makefile.old > /dev/null 2>&1
rm -f \
  Makefile Makefile.old 
rm -rf \
  Graphics-Framebuffer-7.03 
rm -f *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old
```

![Divider](../pics/pink.jpg?raw=true "Divider")

## INSTALLING WITH PERLBREW (and installing Perlbrew)

   * **NOTE:**  Installing a customized Perl is an advanced process.  Do not do this unless you know what you are doing.  The version of Perl installed by the package install is usually fine for most.

   If you do not want to use the package version of Perl, but would rather use a customized and more optimized version of Perl, then do the following:

   ```bash
   wget -O - https://install.perlbrew.pl | bash
   ```

   Append the following line to your " ~/.bash_profile " then log out and log in again:

   ```bash
   source ~/perl5/perlbrew/etc/bashrc
   ```

   Now to install Perlbrew (you can use higher or lower version numbers where applicable):

   ```bash
   perlbrew init
   perlbrew install-cpanm
   perlbrew install-patchperl
   perlbrew install -n perl-5.40 -Dusethreads
   perlbrew clean
   perlbrew switch perl-5.40
   cpanm -n Inline Inline::C Math::Bezier Math::Gradient
   cpanm -n File::Map Imager Term::ReadKey Test::Most File::Map
   cpanm -n MCE::Shared Sereal::Encoder Sereal::Decoder MCE::Hobo Sys::CPU
   cpanm -n Graphics::Framebuffer
   ```

   * **ALSO NOTE**  Systems with x86-64 CPUs (Intel and AMD) are unlikely to benefit much from Perlbrew, as most package installs for these are usually sufficiently optimized.
