use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'                  => 'File::OSS::Scan',
    'AUTHOR'                => 'Harry Wang',
    'VERSION_FROM'          => 'lib/File/OSS/Scan.pm',
    'ABSTRACT_FROM'         => 'lib/File/OSS/Scan.pm',
    'LICENSE'               => 'artistic_1',
    'PL_FILES'              => {},
    'MIN_PERL_VERSION'      => 5.006,
    'CONFIGURE_REQUIRES'    => {
                            'ExtUtils::MakeMaker' => 0,
                            },
    'BUILD_REQUIRES'        => {
                            'Test::More' => 0,
                            },
    'PREREQ_PM'             => {
                           'Test::More' => 0,
                           'File::Copy' => 0,
                           'File::Basename' => 0,
                           'Cache::FileCache' => 0,
                           'JSON' => 0,
                            },
    'dist'                  => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'gz' },
    'clean'                 => { 'FILES' => 'File-OSS-Scan-*' },
);
