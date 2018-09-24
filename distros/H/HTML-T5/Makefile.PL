#!/usr/bin/perl

package main;

use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.52;
use ExtUtils::Liblist;
use Config;

if ( not eval { require LWP::Simple; 1; } ) {
    print <<'EOF';

NOTE: It seems that you don't have LWP::Simple installed.
      The webtidy program will not be able to retrieve web pages.

EOF
}

my @build;

eval {

    require Devel::CheckLib;
    Devel::CheckLib->import('assert_lib');

    my @dirs = qw(
      /usr/local
      /opt/local
    );

    my @libs = map "$_/lib",     @dirs;
    my @incs = map "$_/include", @dirs;
    my $name = $^O eq 'freebsd' ? 'tidy5' : 'tidy';

    assert_lib(
        lib     => $name,
        header  => 'tidy.h',
        libpath => [@libs],
        incpath => [@incs],
    );

    @build = (
        INC => join( ' ', ( map "-I$_", @incs ) ),
        LIBS => join ' ',
        ( map "-L$_", @libs ), "-l$name",
    );

};

unless (@build) {

    eval {
        require Alien::Base::Wrapper;
        Alien::Base::Wrapper->import(qw/ Alien::TidyHTML5 !export /);
        require Alien::TidyHTML5;
        Alien::TidyHTML5->import();
    };

    @build = (
        CONFIGURE_REQUIRES => {
            'Alien::Base::Wrapper' => '0',
            'Alien::TidyHTML5'     => '0',
        },
    );

    push @build, Alien::Base::Wrapper->mm_args unless $@;

}

my $parms = {
    CONFIGURE_REQUIRES => {
        'Devel::CheckLib'      => 0,
        'Alien::Base::Wrapper' => 0,
        'Alien::TidyHTML5'     => 0,
    },
    NAME                => 'HTML::T5',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'lib/HTML/T5.pm',
    ABSTRACT_FROM       => 'lib/HTML/T5.pm',
    PREREQ_PM           => {
        'Encode'          => 0,   # for tests
        'Exporter'        => 0,
        'Getopt::Long'    => 0,   # in webtidy
        'Test::More'      => '0.98', # For subtest()
        'Test::Builder'   => 0,
        'Test::Exception' => 0,
        'Carp'            => 0,
        'constant'        => 0,
    },

    MIN_PERL_VERSION    => 5.010001,
    LICENSE             => 'artistic_2',
    META_MERGE => {
        resources => {
            license     => 'http://www.opensource.org/licenses/artistic-license-2.0.php',
            homepage    => 'http://github.com/shlomif/html-tidy5',
            bugtracker  => 'http://github.com/shlomif/html-tidy5/issues',
            repository  => 'http://github.com/shlomif/html-tidy5',
        },
    },
    @build,
    EXE_FILES           => [qw(bin/web-t5)],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-T5-*' },
};

WriteMakefile( %{$parms} );

sub MY::postamble { ## no critic ( Subroutines::ProhibitQualifiedSubDeclarations )
return <<'MAKE_FRAG';
.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib --exclude=t/lib \
		--exclude=.svn --exclude='*~' \
		--languages=C,Perl --langmap=Perl:+.t \
		.

critic:
	perlcritic -1 \
		-profile perlcriticrc \
		.

MAKE_FRAG
}
