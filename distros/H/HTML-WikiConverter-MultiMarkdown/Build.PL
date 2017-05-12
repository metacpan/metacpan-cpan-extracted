use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new
    ( module_name        => 'HTML::WikiConverter::MultiMarkdown',
      license            => 'perl',
      requires           => { 'HTML::WikiConverter::Markdown' => '0',
                            },
      build_requires     => { 'Test::Differences' => '0',
                              'Test::More'        => '0',
                            },
      create_readme      => 1,
      sign               => 1,
      create_makefile_pl => 'traditional',
    );

$builder->create_build_script();
