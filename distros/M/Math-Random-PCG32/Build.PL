#!perl

use strict;
use warnings;
use Config;
use Module::Build;

# for irand64 and probably also to feed 64-bit seed values into ->new
if ( !$Config{use64bitint} ) {
    print "need perl compiled with use64bitint=define\n";
    exit(0);
}

my $builder = Module::Build->new(
    module_name        => 'Math::Random::PCG32',
    license            => 'apache',
    dist_author        => 'Jeremy Mates <jeremy.mates@gmail.com>',
    dist_version_from  => 'lib/Math/Random/PCG32.pm',
    dist_abstract      => 'minimal random permuted congruential generator',
    include_dirs       => [qw(. src)],
    c_source           => 'src',
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    requires      => { 'perl' => '5.014000', },
    test_requires => {
        'Test2::V0'             => '0.000060',
    },
    sign           => 1,
    create_readme  => 0,
    create_license => 0,
    dynamic_config => 0,
    add_to_cleanup => ['Math-Random-PCG32-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources => { repository => 'https://thrig.me/src/Math-Random-PCG32.git' }
    },
);

$builder->create_build_script();
