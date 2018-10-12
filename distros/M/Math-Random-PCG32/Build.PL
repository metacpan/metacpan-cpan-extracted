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
    dist_author        => 'Jeremy Mates <jmates@cpan.org>',
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
        # http://www.cpantesters.org/cpan/report/67976f18-c32b-11e8-a869-046817727b86
        'Algorithm::Diff' => 0,
        'Test::Most'      => 0,
        'Test::More'      => '0.88',     # done_testing
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
        resources => { repository => 'https://github.com/thrig/Math-Random-PCG32' }
    },
);

$builder->create_build_script();
