# Run "perl Makefile.PL" to create "Makefile", then run "make" to
# build, "make test" to test, and "make install" to install the
# software.

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Directory/Diff.pm';
my $pod = 'lib/Directory/Diff.pod';
my $github = 'github.com/benkasminbullock/Directory-Diff';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Directory::Diff',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'File::Compare' => 0,
        'File::Copy' => 0,
        'Cwd' => 0,
        'File::Path' => 0,
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        resources => {
            repository => {
                type => 'git',
                url => "git://$github.git",
                web => $repo,
            },
            bugtracker => {
                web => "$repo/issues",
            },
#           homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
);
