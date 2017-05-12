
use utf8;
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
     module_name        => 'Math::AnyNum',
     license            => 'artistic_2',
     dist_author        => q{Daniel Șuteu <trizenx@gmail.com>},
     dist_version_from  => 'lib/Math/AnyNum.pm',
     release_status     => 'stable',
     dist_abstract      => 'Arbitrary size precision for integers, rationals, floating-points and complex numbers.',
     configure_requires => {
                            'Module::Build' => 0,
                           },
     build_requires => {
                        'Test::More' => 0,
                       },

    meta_merge => {
                   resources => {
                                 bugtracker => "https://github.com/trizen/Math-AnyNum/issues",
                                 homepage   => "https://github.com/trizen/Math-AnyNum",
                                 repository => "https://github.com/trizen/Math-AnyNum",
                                },
                  },

     requires => {
                  'perl'                => '5.14.0',
                  'POSIX'               => 0,
                  'Carp'                => 0,
                  'Math::GMPq'          => 0.45,
                  'Math::GMPz'          => 0.39,
                  'Math::MPC'           => 1.07,
                  'Math::MPFR'          => 3.29,
                  'Class::Multimethods' => 1.70,
                 },
     add_to_cleanup     => ['Math-AnyNum-*'],
     create_makefile_pl => 'traditional',
);

$builder->create_build_script();
