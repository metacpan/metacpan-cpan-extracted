#!perl
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mac::Apps::PBar',
    'VERSION_FROM' => 'lib/Mac/Apps/PBar.pm', # finds $VERSION
);
