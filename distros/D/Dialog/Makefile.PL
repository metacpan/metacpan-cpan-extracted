# $Id: Makefile.PL,v 1.1 2000/06/06 07:05:36 mike_s Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Dialog',
    'VERSION_FROM' => 'Dialog.pm', # finds $VERSION
    'LIBS'	=> ['-lncurses -ldialog'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
