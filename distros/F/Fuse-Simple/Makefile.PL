#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Fuse::Simple',
    ABSTRACT      => 'Simple way to write FUSE filesystems in Perl',
    AUTHOR        => '"Nosey" Nick Waterman <perl@noseynick.org>',
    VERSION_FROM  => 'lib/Fuse/Simple.pm', # finds \$VERSION
    PL_FILES      => {},
    PREREQ_PM     => {
	'Test::More' => 0,
	'strict'     => 0,
	'warnings'   => 0,
	'Carp'       => 0,
	'Fuse'       => 0,
	'Errno'      => 0,
	'Fcntl'      => 0,
	'Switch'     => 0,
	'Exporter'   => 0,
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Fuse-Simple-* *~ */*~ */*/*~' },
);
