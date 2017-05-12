use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Device/Router/RTX.pm';
my $pod = 'lib/Device/Router/RTX.pod';
my $repo = 'https://github.com/benkasminbullock/Device-Router-RTX';

WriteMakefile (
    NAME => 'Device::Router::RTX',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'Net::Telnet' => 0,
        'Net::TFTP' => 0,
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008001',
);
