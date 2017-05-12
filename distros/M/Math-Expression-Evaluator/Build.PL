use strict;
use warnings;
use Module::Build;
require 5.006001;

my $build = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Math::Expression::Evaluator',
    dist_author        => 'Moritz Lenz',
    dist_abstract      => undef,
    dist_version_from  => 'lib/Math/Expression/Evaluator.pm',
    requires => {
        'perl'               => '5.006001',
        'Carp'               => 0,
        'Math::Trig'         => 0,
        'Data::Dumper'       => 0,
    },
    recommends         => {},
    sign               => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
