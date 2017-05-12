#!perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mac::Apps::Anarchie',
    'VERSION_FROM' => 'lib/Mac/Apps/Anarchie.pm', # finds $VERSION
);
