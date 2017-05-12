use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'HTML::Prototype',
    requires           => {
      'Class::Accessor::Fast' => 0,
	  'HTML::Tree' => 0
    },
    reccomends => {
    },
    create_readme => 1,
    sign          => 0,
);
$build->create_build_script;
