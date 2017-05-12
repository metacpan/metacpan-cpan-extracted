use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Math::CPWLF',
    license             => 'perl',
    dist_author         => q{Dan Boorstein <dan@boorstein.net>},
    dist_version_from   => 'lib/Math/CPWLF.pm',
    build_requires => {
        'Test::More' => 0,
        'Want'       => 0,
        'List::Util' => 0,
    },
    add_to_cleanup      => [ 'Math-CPWLF-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge          =>
       {
       resources =>
          {
          repository  => 'http://github.com/danboo/perl-math-cpwlf/',
          }
       },
);

$builder->create_build_script();
