#! perl

BEGIN { require 5.008006}

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Mail::TempAddress',
    license     => 'perl',
    requires    =>
    {
        'Class::Roles'   => '0.30',
        'Mail::Action'   => '0.45',
        'Email::Address' => '',
        'YAML'           => '0.35',
        'perl'           => '5.8.6',
    },
    build_requires =>
    {
        'Test::Exception'  => '',
        'Test::MockObject' => '0.11',
        'Test::Simple'     => '0.47',
    },
    dist_version_from => 'lib/Mail/TempAddress.pm',
);

$build->create_build_script();
