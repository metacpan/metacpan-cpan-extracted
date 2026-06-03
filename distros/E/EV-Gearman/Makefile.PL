use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Copy qw(copy);
use EV::MakeMaker '$installsitearch';

die "OS unsupported\n" if $^O eq "MSWin32";

unless (-f 'src/ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('src/ppport.h');
}

copy('src/EV__Gearman.xs', 'Gearman.xs')
    or die "Cannot copy src/EV__Gearman.xs -> Gearman.xs: $!\n";

my @inc = ('-Isrc', "-I$installsitearch/EV", "-I$installsitearch");

WriteMakefile(
    NAME             => 'EV::Gearman',
    VERSION_FROM     => 'lib/EV/Gearman.pm',
    ABSTRACT_FROM    => 'lib/EV/Gearman.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012000',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'EV::MakeMaker'       => 0,
    },
    PREREQ_PM => {
        'EV'       => '4.11',
        'XSLoader' => '0.02',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },

    INC    => join(' ', @inc),
    DEFINE => '',
    LIBS   => [''],

    clean => { FILES => 'Gearman.xs Gearman.c' },

    test => { TESTS => (-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt'
                        ? 't/*.t xt/*.t' : 't/*.t' },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-gearman.git',
                web  => 'https://github.com/vividsnow/perl5-ev-gearman',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-gearman/issues',
            },
        },
        no_index => {
            directory => [qw(t xt src eg bench tools)],
        },
    },
);

# Add `make readme` target and regenerate README before `make dist`.
# Also keep Gearman.xs in sync with the source under src/ — without
# this, `make` after editing src/EV__Gearman.xs would build from the
# stale top-level Gearman.xs that perl Makefile.PL last copied.
sub MY::postamble {
    return <<'POSTAMBLE';
.PHONY: readme

readme: README.md

README.md: lib/EV/Gearman.pm tools/gen-readme.pl
	$(PERL) tools/gen-readme.pl

Gearman.xs: src/EV__Gearman.xs
	$(CP) src/EV__Gearman.xs Gearman.xs

dist : readme
POSTAMBLE
}
