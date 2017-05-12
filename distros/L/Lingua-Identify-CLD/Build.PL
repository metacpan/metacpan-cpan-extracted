use 5.008;
use strict;
use warnings;

use lib 'inc';
use Config;

use MyBuilder;

my $builder = MyBuilder->new
  (
   module_name         => 'Lingua::Identify::CLD',
   license             => 'bsd',
   dist_author         => q{Alberto Simões <ambs@cpan.org>},
   dist_version_from   => 'lib/Lingua/Identify/CLD.pm',
   build_requires      => {
                           'Config::AutoConf'     => '0.17',
                           'ExtUtils::CBuilder'   => '0.27',
                           'ExtUtils::ParseXS'    => 0,
                           'ExtUtils::LibBuilder' => '0.04',
                           'Test::More'           => 0,
                          },
   configure_requires  => {
                           'Config::AutoConf'     => '0.16',
                           'Module::Build'        => '0.38',
                           'ExtUtils::LibBuilder' => '0.04',
                          },
   requires            => {
                           'XSLoader' => '0.10',
                           'perl' => 5.008,
                          },
   add_to_cleanup      => [
                           '*.o',
                           'cld-src/*.dylib',
                           'cld-src/*.so',
                           'cld-src/*.dll',
                           'cld-src/*.o',
                           'cld-src/*/*.o',
                           'cld-src/*/*/*.o',
                           'cld-src/*/*/*/*.o',
                           'Lingua-Identify-CLD-*'
                          ],
  );


$builder->create_build_script;
