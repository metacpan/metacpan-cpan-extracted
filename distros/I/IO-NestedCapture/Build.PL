use 5.008;
use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name        => 'IO::NestedCapture',
	license            => 'perl',
    create_makefile_pl => 'passthrough',
);

$build->create_build_script;
