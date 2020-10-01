#!perl -w

use 5.006002;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'File::Listing',
    VERSION_FROM => 'lib/File/Listing.pm',
    ABSTRACT_FROM => 'lib/File/Listing.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.006002,
    PREREQ_PM => {
	'HTTP::Date'  => '6.00',
	'Exporter'    => '0',
	'Time::Local' => '0',
	'base'        => '0',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web  => 'https://github.com/PerlAlien/File-Listing/issues',
            },
            homepage => 'https://metacpan.org/pod/File::Listing',
            repository => {
                type => 'git',
                url  => 'https://github.com/PerlAlien/File-Listing.git',
                web  => 'https://github.com/PerlAlien/File-Listing',
            },
        },
    },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
        CONFIGURE_REQUIRES => 6.52,
        TEST_REQUIRES => 6.64,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
