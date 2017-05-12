#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.003_000;
use ExtUtils::MakeMaker;

BEGIN { use English; }

push( @ExtUtils::MakeMaker::Overridable, qw(pm_to_blib) )
    if ( $OSNAME eq 'MSWin32' );

WriteMakefile(
    NAME             => 'MathPerl',
    ABSTRACT         => 'Mathematics Perl, The Optimized Math Library Suite',
    AUTHOR           => 'Will Braswell <wbraswell@cpan.org>',
    VERSION_FROM     => 'lib/MathPerl.pm',
    LICENSE          => 'perl_5',
    EXE_FILES        => [ 'script/mathperl', 'script/demo/fractal.pl', 'script/demo/pi_digits.pl' ],
    MIN_PERL_VERSION => '5.10.0',  # NEED ANSWER, CORRELATION #rp00: is RPerl truly incompatible with Perl v5.8 and earlier?
    PREREQ_PM        => {
        'ExtUtils::MakeMaker' => 7.04,        # for compatibility with Inline::C >= v0.75
        'CPAN::Meta'          => 2.150005,    # RPerl system developers only, used for generating CPAN metadata from this file during dist build
        'Test::Exception'     => 0.32,
        'Test::CPAN::Changes' => 0.400002,
        'Test::Number::Delta' => 1.06,        # for compatibility with Perls compiled using -Duselongdouble
        'RPerl'               => 1.6,
        'Time::HiRes'         => 1.9726,
        'SDL'                 => 2.546
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
            url     => 'https://metacpan.org/pod/CPAN::Meta::Spec'
        },
        no_index       => { namespace => ['MathPerl::Test'] },    # DEV NOTE: disable indexing of all test package namespaces
        release_status => 'stable',
        keywords    => [qw(mathperl math rperl perl5 optimizing compiler optimize compile)],
        description => 'MathPerl is the high-performance math suite for the Perl 5 programming language, optimized using the RPerl compiler.',
        resources   => {
            license => ['http://dev.perl.org/licenses/'],
            homepage   => 'http://www.rperl.org',
            bugtracker => { web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=MathPerl' },
            repository => {
                type => 'git',
                url  => 'git://github.com/wbraswell/mathperl.git',
                web  => 'https://github.com/wbraswell/mathperl'
            }
        }
    },

    # NEED UPDATE, CORRELATION #mp00: list of _Inline directories to delete/exclude in Makefile.PL, .gitignore, and MANIFEST.SKIP
    # NEED UPDATE, CORRELATION #mp01: list of CPAN files & directories to delete/exclude in Makefile.PL, .gitignore, and MANIFEST.SKIP
    clean => {
        FILES =>
            'pod2htmd.tmp Makefile.old MANIFEST.bak _Inline lib/_Inline script/_Inline script/development/_Inline script/development/unused/_Inline t/_Inline lib/MathPerl/_Inline'
    }
);

package MY;
BEGIN { use English; }

sub pm_to_blib {
    my $self = shift;
    my $blib = $self->SUPER::pm_to_blib(@_);

    # un-read-only blib/lib for tests to pass, files are modified at runtime there
    if ( $OSNAME eq 'MSWin32' ) {
        my ( $lastline, $start ) = qq{\t\$(NOECHO) \$(TOUCH) pm_to_blib\n};
        ( $start = index( $blib, $lastline ) ) == -1
            && die "Can't find replacement string for pm_to_blib target";
        substr( $blib, $start, 0, "\t" . 'attrib -R /S  blib/lib/*' . "\n" );
    }
    return $blib;
}

# disable PERL_DL_NONLAZY=1 to avoid C++ compile errors for GMP library (and possibly others)
sub test_via_harness {
    my $self    = shift;
    my $command = $self->MM::test_via_harness(@_);
    $command =~ s/\bPERL_DL_NONLAZY=1\s+//gxms;
    return $command;
}

sub test_via_script {
    my $self    = shift;
    my $command = $self->MM::test_via_script(@_);
    $command =~ s/\bPERL_DL_NONLAZY=1\s+//gxms;
    return $command;
}
