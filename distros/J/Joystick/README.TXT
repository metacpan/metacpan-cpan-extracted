Win32API::Joystick
$VERSION = 1.01, 22 June 2000

Hey!
Win32API::Joystick only works if you're running windows (duh!). I plan to make a Device::Joystick in the near future which will work for Unix-like OSs.

The module will allow you to get x,y,z and button status of joystick devices via Windows API calls.  In the next release I will include the methods to get extended joystick information,
which includes POV status and joysticks with more than 3 axes.

This release is for Win32 ports of Perl only, and does not require compilation.  (See install)

These modules use Aldo Calpini's Win32::API module extensively. It is
available at:

    http://www.divinf.it/dada/perl/Win32API-0_011.zip


To install:

perl Makefile.pl
perl install.pl
perl test.pl

The makefile.pl does not actually write a makefile ... it creates install.pl that copies the modules to the correct site directories/destination directories.  To install you must have the Win32 module installed.  Makefile.pl will also create test.pl and install.pl.


If this method doesn't work for you, just copy Joystick.pm to site/lib/Win32API/Joystick.pm


You can find this module and updates at CPAN in author directory BDLILLEY.
If you have any comments, questions, or additions please contact me at
blilley@hpu.edu

Thanks!  -Ben