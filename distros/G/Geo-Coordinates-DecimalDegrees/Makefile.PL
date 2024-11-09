require 5.004;
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    'NAME'		=> 'Geo::Coordinates::DecimalDegrees',
    'LICENSE'           => 'perl',
    'PREREQ_PM'         => { 'Test::Number::Delta' => 0 },
    'VERSION_FROM'	=> 'DecimalDegrees.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DecimalDegrees.pm', # retrieve abstract from module
       AUTHOR     => 'Walt Mankowski <waltman@pobox.com>') : ()),
);
