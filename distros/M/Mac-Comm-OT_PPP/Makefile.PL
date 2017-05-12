#!perl
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mac::Comm::OT_PPP',
    'VERSION_FROM' => 'lib/Mac/Comm/OT_PPP.pm', # finds $VERSION
);
