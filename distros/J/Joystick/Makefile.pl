####    use ExtUtils::MakeMaker;
####    # See lib/ExtUtils/MakeMaker.pm for details of how to influence
####    # the contents of the Makefile that is written.
####    WriteMakefile(
####        'NAME'	=> 'Joystick',
####        'VERSION_FROM' => 'Joystick.pm', # finds $VERSION
####    );

my $version = "1.01";

print <<MESS;

Win32API::Joystick
VERSION $version

No 'Makefile' will be created!
Install with: perl install.pl
Test with: perl test.pl
MESS

print "\n\n";

##========
$dfile = "test.pl";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

print DEFAULT <<TEST;
use Win32API::Joystick;
use strict;

my (\$numDevs, \$joyObj, \$x, \$y, \$z, \$buttons, \$attributes);

#find number of possible devices
   \$numDevs = Joystick::joyGetNumDevs;

#number of possible system joysticks
   print "Number of possible joystick devices: \$numDevs\\n\\n";

#display information about each possible joystick
   for (0 .. \$numDevs){
      \$joyObj = Joystick->new(\$_);
      
      if (\$joyObj){
         print "Joystick \$_ information: \\n";
         for \$attributes(qw(XMIN XCENT XMAX YMIN YCENT YMAX ZMIN ZCENT ZMAX NUMBUTTONS             NUMAXES))  {
               print "\\\$joyObj->{\$attributes} = \$joyObj->{\$attributes} \\n";
         }
      (\$x, \$y, \$z, \$buttons)  = \$joyObj->joyGetPos;

      print "\\nPosition information: x = \$x, y = \$y, z = \$z, buttons = \$buttons \\n";
  
      print "\\n\\n";

      }else{
         print "Joystick \$_ is not connected or not functioning.\\n";
      }
}
  
TEST

close DEFAULT;
##========


$dfile = "install.pl";
unlink $dfile;
print "Creating new $dfile\n";
open (DEFAULT, "> $dfile") or die "Can't create $dfile: $!\n";

if ( $] < 5.004 ) { print DEFAULT <<INST3;
# Created by Makefile.PL
# VERSION $version

#   ActiveState Build 3xx Install script for Joystick::WinJoy
#   Adapted from Win32::API version 0.011 Install Program
#   by Aldo Calpini <dada\@divinf.it>

BEGIN { die "wrong version" unless (\$] =~ /^5\.003/); }

use Win32::Registry;
use File::Copy;

sub CheckDir {
    my(\$dir) = \@_;
    if(! -d \$dir) {
        print "Creating directory \$dir...\\n";
        mkdir(\$dir, 0) or die "ERROR: (\$!)\\n";
    }
}    

\$MODULE  = "Win32API::Joystick";

print "\\n   \$MODULE version $version Install Program for Build 3xx\\n";
print   "   Adapted from Win32::API Install Program\n";
print   "   by Aldo Calpini <dada\\\@divinf.it>\n\n";

\$KEY = "SOFTWARE\\\\ActiveWare\\\\Perl5";

\$HKEY_LOCAL_MACHINE->Open(\$KEY, \$hkey)
  or die "ERROR: Can't open Perl registry key: \$KEY\\n";

\$hkey->GetValues(\$values);
\$hkey->Close();

\$PRIVLIB = \$values->{'PRIVLIB'}->[2];

die "ERROR: Can't get PRIVLIB registry value!\\n" unless \$PRIVLIB;

CheckDir("\$PRIVLIB\\\\Win32API");

if (copy "lib\\\\Win32API\\\\Joystick.pm","\$PRIVLIB\\\\Win32API\\\\Joystick.pm") {
    print "Copied Win32API::Joystick.pm to \$PRIVLIB\\\\Win32API...\\n";
}
else {
    die "Could not copy Win32API::Joystick.pm to \$PRIVLIB\\\\Win32API...\\n";
}


print "Installation done\\n";
INST3

}
else { print DEFAULT <<INST4;
# Created by Makefile.PL
# VERSION $version

BEGIN { require 5.004; }

use Config qw(\%Config);
use strict;
use ExtUtils::Install qw( install );

my \$FULLEXT = "Win32API/Joystick";
my \$INST_LIB = "./lib";
my \$HTML_LIB = "./html";

my \$html_dest = "";	# edit real html base here if autodetect fails

if (exists \$Config{installhtmldir} ) {
    \$html_dest = "\$Config{installhtmldir}";
}
elsif (exists \$Config{installprivlib} ) {
    \$html_dest = "\$Config{installprivlib}";
    \$html_dest =~ s%\\\\lib%\\\\html%;
}

if ( length (\$html_dest) ) {
    \$html_dest .= '\\lib\\site';
}
else {
    die "Can't find html base directory. Edit install.pl manually.\\n";
}

install({
	   read => "\$Config{sitearchexp}/auto/\$FULLEXT/.packlist",
	   write => "\$Config{installsitearch}/auto/\$FULLEXT/.packlist",
	   \$INST_LIB => "\$Config{installsitelib}",
	   \$HTML_LIB => "\$html_dest"
	  },1,0,0);

__END__
INST4

}
close DEFAULT;
