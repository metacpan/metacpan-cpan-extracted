#!/usr/bin/perl

package main;

use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.52;
use Alien::Base::Wrapper 2.02;

my @build = (
    alien_requires => {
        'Alien::TidyHTML5' => '0.3.0',
    },
);

my $parms = {
    CONFIGURE_REQUIRES => {
        'Alien::Base::Wrapper' => '2.02',
    },
    NAME          => 'HTML::T5',
    AUTHOR        => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM  => 'lib/HTML/T5.pm',
    ABSTRACT_FROM => 'lib/HTML/T5.pm',
    PREREQ_PM     => {
        'Encode'          => 0,         # for tests
        'Exporter'        => 0,
        'Getopt::Long'    => 0,         # in webtidy
        'Test::More'      => '0.98',    # For subtest()
        'Test::Builder'   => 0,
        'Test::Exception' => 0,
        'Carp'            => 0,
        'constant'        => 0,
    },

    MIN_PERL_VERSION => 5.010001,
    LICENSE          => 'artistic_2',
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            license =>
                'http://www.opensource.org/licenses/artistic-license-2.0.php',
            homepage   => 'http://github.com/shlomif/html-tidy5',
            bugtracker => 'http://github.com/shlomif/html-tidy5/issues',
            repository => 'http://github.com/shlomif/html-tidy5',
        },
        x_contributors => [
            'Andy Lester <andy@petdance.com>',
            'Jonathan Rockway <jrockway@cpan.org>',
            'Robert Bachmann <rbach@cpan.org>',
            'Robert Rothenberg <rrwo@cpan.org>',
            'Rufus Cable <cpan@threebytesfull.com>',
        ],
    },
    EXE_FILES => [qw(bin/web-t5)],
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'HTML-T5-*' },
};

my %foo =
    Alien::Base::Wrapper->new('Alien::TidyHTML5=0.3.0')->mm_args2(%$parms);
$foo{CONFIGURE_REQUIRES}{'Alien::Base::Wrapper'} = '2.02';
WriteMakefile(%foo);

sub MY::postamble
{    ## no critic ( Subroutines::ProhibitQualifiedSubDeclarations )
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
