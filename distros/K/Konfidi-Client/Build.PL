use strict;
use warnings;
use Module::Build 0.26; # 'make testcover' support begins, which we want to encourage/force

my $builder = Module::Build->new(
    sign => 1,
    module_name         => 'Konfidi::Client',
    license             => 'apache',
    dist_author         => 'Dave Brondsema <dave@brondsema.net>',
    dist_version_from   => 'lib/Konfidi/Client.pm',
    build_requires => {
        'Module::Build' => 0.26,
        'Test::More' => 0,
        'Test::Exception' => 0,
        'HTTP::Daemon' => 0,
    },
    requires => {
        'LWP::UserAgent' => 0,
        'Error' => 0,
        'Carp' => 0,
        'Scalar::Util' => 0,
        'URI::Escape' => 0,
    },
    add_to_cleanup      => [ 'Konfidi-*' ],
);

$builder->create_build_script();
