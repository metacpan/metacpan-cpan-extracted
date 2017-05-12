#
# $Id: Makefile.PL,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
    (
     NAME              => 'MacOSX::File::Info',
     VERSION_FROM      => 'Info.pm',
     PREREQ_PM         => {}, # e.g., Module::Name => 1.1
     LIBS	=> qq(),
     LDDLFLAGS  => qq(-bundle -flat_namespace -undefined suppress -framework Carbon),
     INC	=> qq(-I../ -I/Developer/Headers/FlatCarbon),
     ($] <= 5.008001 ? (CC => 'gcc2') : ()),
    );
