#! perl

BEGIN { require 5.008006 }

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Mail::Action',
    license     => 'perl',
    requires    =>
    {
        'Class::Roles'           => '0.30',
        'Email::Address'         => '1.889',
        'Email::MIME'            => '',
        'Email::MIME::Modifier'  => '',
        'Email::Simple'          => '',
        'Mail::Mailer'           => '',
        'Pod::Simple'            => '',
        'YAML'                   => '0.35',
        'perl'                   => '5.8.6',
    },
    build_requires =>
    {
        'IO::File'               => '',
        'Test::Exception'        => '',
        'Test::MockObject'       => '1.09',
        'Test::Simple'           => '0.47',
        'Test::Class'            => '',
    },
    dist_version_from => 'lib/Mail/Action.pm',
    dist_author       => 'chromatic <chromatic@wgz.org>',
);

$builder->create_build_script();
