use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/File/Versions.pm';
my $pod = 'lib/File/Versions.pod';
my $repo = 'https://github.com/benkasminbullock/File-Versions';

WriteMakefile (
    NAME => 'File::Versions',
    LICENSE => 'perl',
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    VERSION_FROM => $pm,
    PREREQ_PM => {
        'List::Util' => 0,
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.006001',
);
