
use utf8;
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Math::Sidef',
    license            => 'artistic_2',
    dist_author        => q<Daniel Șuteu <trizen@cpan.org>>,
    dist_version_from  => 'lib/Math/Sidef.pm',
    release_status     => 'stable',

    dynamic_config    => 0,
    extra_manify_args => { utf8 => 1 },

    configure_requires => {
                           'Module::Build' => 0,
                          },
    build_requires => {
                       'Test::More' => 0,
                      },

    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/Math-Sidef/issues",
                                 homepage   => "https://github.com/trizen/Math-Sidef",
                                 repository => "https://github.com/trizen/Math-Sidef",
                                },
                  },

    requires => {
                 'perl'         => '5.16.0',
                 'Sidef'        => '3.97',
                 'Math::AnyNum' => '0.36',
                 'Exporter'     => '0',
                },
    add_to_cleanup     => ['Math-Sidef-*'],
    create_makefile_pl => 'traditional',
                                );

$builder->create_build_script();
