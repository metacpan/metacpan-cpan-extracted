use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/IP/China.pm';
my $pod = 'lib/IP/China.pod';
my $repo = 'https://github.com/benkasminbullock/chinese-ip';

# The list of object files which are compiled with this library.

my $object = 'China.o block-china-data.o ip-tools.o';

WriteMakefile (
    NAME => 'IP::China',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    OBJECT => $object,
    # Speculated minimum version of Perl necessary, there are no
    # failed tests for the previous version of the module.
    MIN_PERL_VERSION => '5.006001',
);
