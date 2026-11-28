use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

# libsfparse is bundled in src/ and compiled into this extension. It is two
# files with no dependencies beyond the C standard library, so there is no
# system library to find and no Alien:: module needed.

WriteMakefile(
    NAME             => 'HTTP::libsfparse',
    VERSION_FROM     => 'lib/HTTP/libsfparse.pm',
    ABSTRACT_FROM    => 'lib/HTTP/libsfparse.pm',
    AUTHOR           => 'Robert Rothenberg <perl@rhizomnic.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.020',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    PREREQ_PM => {
        'Exporter' => '5.57',
        'Hash::Ordered' => '0.009',
        'Math::Int64'   => '0',
        'Ref::Util'     => '0.200',
        'Sub::Util'     => '1.40',
        'XSLoader' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0'    => '0',
        'Digest::MD5'  => 0,
        'MIME::Base64' => 0,
        'JSON'         => '0',
        'B'            => 0,
    },

    XS     => { 'libsfparse.xs' => 'libsfparse.c' },
    OBJECT => 'libsfparse$(OBJ_EXT) src/sfparse$(OBJ_EXT) perl_math_int64$(OBJ_EXT)',
    INC    => '-I. -Isrc',

    clean => { FILES => 'src/sfparse$(OBJ_EXT) HTTP-libsfparse-*' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources   => {
            repository => {
                type => 'git',
                web  => 'https://github.com/robrwo/perl-HTTP-StructuredField',
            },
        },
        x_contributors => ['Paul Johnson <paul@pjcj.net>'],
    },
);

# MakeMaker only compiles the .c files it finds in the distribution root, so
# the bundled library in src/ needs a rule of its own. Writing it out instead
# of relying on an implicit suffix rule keeps it working with makes that do
# not apply suffix rules to targets in subdirectories.

sub MY::postamble {
    return <<'MAKE_FRAG';
src/sfparse$(OBJ_EXT) : src/sfparse.c src/sfparse.h perl_math_int64.c perl_math_int64.h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -o $@ src/sfparse.c
MAKE_FRAG
}
