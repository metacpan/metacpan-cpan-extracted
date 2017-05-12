# $Id: Makefile.PL,v 1.2 2001/04/02 01:12:52 karl Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::QuickBase',
    'VERSION_FROM'	=> 'QuickBase.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP::UserAgent => 1.64, Crypt::SSLeay => 0.14}, # e.g., Module::Name => 1.1
);
