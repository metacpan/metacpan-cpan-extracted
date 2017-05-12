use ExtUtils::MakeMaker;
use File::Find;

use strict;
use warnings;

# work out whether it's windows or not, and whether it is under
# Cygwin.  If it is, instead of g++, look for g++.exe - we'll also add
# in another parameter for WriteMakefile, and note that the PATH
# separator is different under windows, though not under Cygwin

use constant CYGWIN => $^O =~ /cygwin/i ? 1 : 0;
use constant MSWIN  => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

# not clear how to portably identify what c++ compiler there is, so
# we'll see if g++ exists, and if not die, indicating that they need
# to hand edit the $CC variable.

my $CC            = 'g++';
my $WIN_CC        = $CC.'.exe';
my $found         = 0; # indicates whether we have found the C++ compiler
my $pathseparator = ':';

if (MSWIN || CYGWIN){

    $CC = $WIN_CC;
    
}

if (MSWIN){

    $pathseparator = ';';

}

my @directories = split($pathseparator, $ENV{"PATH"});

# they may have some garbage in their PATH, so only keep the real
# directories to search

my @realDirectories;

foreach my $directory (@directories){

    if (-e $directory && -d $directory){

	push (@realDirectories, $directory);

    }

}

find(\&wanted, @realDirectories); 

if (!$found){

    # we didn't find $CC

    die "\n\n********************************************************************

*** Error compiling C++ code ***

Not able to locate $CC.

You will have to edit native/Makefile.PL to indicate the name of the
C++ compiler on your system.

********************************************************************
\n\n";

}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %makeArgs      = (
		     'NAME'	       => 'GO::TermFinder::Native',
		     'LIBS'            => ['-lm -lstdc++'],
		     'CC'              => $CC,
		     'LD'              => '$(CC)',
		     'OBJECT'          => 'Distributions.o Native_wrap.o',

		     );

if (CYGWIN){

    # This is needed to make it work under Cygwin - not sure if this
    # is needed on Windows when not using Cygwin

    $makeArgs{LDDLFLAGS} = q[-shared];

}

WriteMakefile(%makeArgs);

sub wanted {

    $found = 1 if $_ eq $CC;

}
