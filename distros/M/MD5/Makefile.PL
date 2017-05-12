require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'MD5',
    'VERSION_FROM' => 'MD5.pm',
    'PREREQ_PM'    => { 'Digest::MD5' => 2.00, },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
