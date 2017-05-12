#!perl -w
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::Sort',
    'VERSION_FROM' => 'Sort.pm', # finds $VERSION
);
