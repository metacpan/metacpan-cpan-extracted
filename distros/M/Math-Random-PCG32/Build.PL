use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Math::Random::PCG32',
    license            => 'apache',
    dist_author        => 'Jeremy Mates <jmates@cpan.org>',
    dist_version_from  => 'lib/Math/Random/PCG32.pm',
    dist_abstract      => 'minimal PCG random number generator',
    include_dirs       => [qw(. src)],
    c_source           => 'src',
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    requires       => { 'perl'       => '5.014000', },
    test_requires  => { 'Test::Most' => 0, },
    sign           => 1,
    create_readme  => 0,
    create_license => 0,
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
        'meta-spec'       => { version => 2 },
        homepageresources => {
            url  => 'git://github.com/thrig/Math-Random-PCG32.git',
            web  => 'https://github.com/thrig/Math-Random-PCG32',
            type => 'git',
        }
    },
);

$builder->create_build_script();
