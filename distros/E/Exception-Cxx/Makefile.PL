#!./perl -w

use 5.005_57;
use strict;
use ExtUtils::MakeMaker;

# Also see the ./hints directory!

#$Verbose = 1;
WriteMakefile
    (
     NAME         => 'Exception::Cxx',
     VERSION_FROM => './Cxx.pm',
     'OBJECT'	=> join(' ', qw[Cxx.o]),
    );
