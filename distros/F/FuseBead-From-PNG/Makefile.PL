#!/usr/bin/env perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'FuseBead::From::PNG',
    VERSION_FROM     => 'lib/FuseBead/From/PNG.pm', # finds \$VERSION
    AUTHOR           => 'Travis Chase (gaudeon@cpan.org)',
    ABSTRACT         => 'Convert PNGs into plans to build a fuse bead replica. ',
    MIN_PERL_VERSION => '5.14.0',
    LICENSE          => 'mit',
    PREREQ_PM        => {
                        'Test::Simple'       => 0.44,
                        'File::Temp'         => 0.23,
                        'Image::PNG::Libpng' => 0.39,
                        'Data::Debug'        => 0.03,
                        'JSON'               => 2.90,
                    },
    META_MERGE       => {
        resources => {
            repository => 'https://github.com/gaudeon/FuseBead-From-Png',
        },
    },
);
