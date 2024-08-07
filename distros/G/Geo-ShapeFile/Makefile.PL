use strict;
use warnings;

use ExtUtils::MakeMaker;

my @win32_longpath
  = $^O eq 'MSWin32'
  ? ('Win32::LongPath' => 0)
  : ();

WriteMakefile(
    'NAME'          => 'Geo::ShapeFile',
    'VERSION_FROM'  => 'lib/Geo/ShapeFile.pm', # finds $VERSION
    'PREREQ_PM'	    => {
        'Carp'       => 0,
        'IO::File'   => 0,
        'Math::Trig' => 1.04,
        'List::Util' => 0,
        'Scalar::Util' => 0,
        'parent'     => 0,
        'Tree::R'    => 0,
        'POSIX'      => 0,
        'autovivification' => 0,
        @win32_longpath,
    },
    BUILD_REQUIRES => {
        'rlib'       => 0,
    },
    TEST_REQUIRES => {
        'rlib'       => 0,
        'Test::Exception' => 0,
        'Test::More' => 0.96,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/Geo-ShapeFile.git',
                web  => 'https://github.com/shawnlaffan/Geo-ShapeFile',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/Geo-ShapeFile/issues/',
            },
        },
    },
    ABSTRACT_FROM => 'lib/Geo/ShapeFile.pm',
    AUTHOR        => 'Shawn Laffan <shawnlaffan@gmail.com>',
    LICENSE       => 'perl_5',
);
