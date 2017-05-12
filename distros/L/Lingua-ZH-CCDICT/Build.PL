use strict;
use warnings;

require 5.00601;

use Module::Build;

my $build = Module::Build->new
    ( module_name        => 'Lingua::ZH::CCDICT',
      requires           => { 'File::Spec'       => 0,
                              'Params::Validate' => '0.24',
                              'Sub::Name'        => 0,
                            },
      recommends         => { 'BerkeleyDB' => '0.19',
                              'Storable'   => 0,
                            },
      build_requires     => { 'File::Temp' => 0,
                              'Test::More' => '0.46'
                            },
      license            => 'perl',
      sign               => 1,
      create_readme      => 1,
      create_makefile_pl => 'traditional',
    );

$build->create_build_script();
