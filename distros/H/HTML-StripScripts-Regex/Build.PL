use 5.006001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'HTML::StripScripts::Regex',
    dist_author => 'Nick Cleaton <nick@cleaton.net>',
    all_from    => 'lib/HTML/StripScripts/Regex.pm',
    license     => 'perl',
    requires => {
        'perl'               => 5.006001,
        'HTML::StripScripts' => 1.00,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => [ 'HTML::StripScripts::Regex-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
