use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    auto_configure_requires => 1,
    module_name             => 'Digest::Oplop',
    license                 => 'perl',
    create_license          => 1,
    create_readne           => 1,
    build_requires          => { 
        'Module::Build' => 0, 
    },
    requires                => {
        'Digest::MD5'  => 0,
        'Encode'       => 0,
        'IO::Prompt'   => 0,
        'Getopt::Long' => 0,
        'Pod::Usage'   => 0,
    },
    configure_requires => { 'Module::Build' => 0 },
    meta_merge => { 
        resources => { 
                repository => 'http://github.com/mdom/Digest-Oplop/',
        },
    },
);
$build->create_build_script;
