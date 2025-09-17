use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Package maintainers: if for whatever reason you cannot/don't want to build
# ishmael's XS components, you can pass NO_XS to `perl Makefile.PL` as a
# non-zero value to disable the use of XS code. ishmael will use pure-Perl
# versions of the XS components instead, which will have worse performance than
# their XS counterparts.

sub extract_argv_var {

    my $var = shift;

    my $idx;
    my $val;

    for my $i (0 .. $#ARGV) {
        if ($ARGV[$i] =~ /^\Q$var\E=(.*)$/) {
            $idx = $i;
            $val = $1;
            last;
        }
    }

    if (not defined $idx) {
        return undef;
    }

    # So that MakeMaker doesn't complain about the custom parameter.
    splice @ARGV, $idx, 1;

    return $val;

}

my $NO_XS = !! extract_argv_var('NO_XS');

my %WriteMakefileArgs = (
    NAME             => 'EBook::Ishmael',
    AUTHOR           => q{Samuel Young <samyoung12788@gmail.com>},
    VERSION_FROM     => 'lib/EBook/Ishmael.pm',
    ABSTRACT_FROM    => 'lib/EBook/Ishmael.pm',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'File::Path' => '0',
        'File::Temp' => '0.10',
        'File::Spec' => '0',
    },
    PREREQ_PM => {
        'Archive::Zip' => '0',
        'Compress::Zlib' => '0',
        'Cwd' => '0',
        'Encode' => '0',
        'File::Basename' => '0',
        'File::Path' => '0',
        'File::Spec' => '0',
        'File::Temp' => '0.10',
        'File::Which' => '0',
        'JSON::PP' => '0',
        'List::Util' => '0',
        'MIME::Base64' => '0',
        'XML::LibXML' => '1.70',
        'XSLoader' => '0',
    },
    EXE_FILES => [
        'bin/ishmael',
        'bin/queequeg',
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                url => 'https://codeberg.org/1-1sam/ishmael.git',
                web => 'https://codeberg.org/1-1sam/ishmael',
                type => 'git',
            },
            bugtracker => {
                web => 'https://codeberg.org/1-1sam/ishmael/issues',
            },
        },
	},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'EBook-Ishmael-*' },
);

if ($NO_XS) {
    @WriteMakefileArgs{ qw(XS C) } = (
        {},
        []
    );
}

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };
delete $WriteMakefileArgs{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

WriteMakefile(%WriteMakefileArgs);
