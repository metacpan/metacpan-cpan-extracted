use strict;
use warnings;

use Module::Build;

my $builder =
    Module::Build->new
        ( module_name        => 'Kwiki::Theme::PerlMongers',
          license            => 'perl',
          requires           => { 'Test::More' => 0 },
          create_makefile_pl => 'passthrough',
          create_readme      => 1,
          sign               => 1,
        );

$builder->create_build_script();
