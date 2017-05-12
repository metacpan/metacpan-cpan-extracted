#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Graphics::HotMap',
    license     => 'gpl3',
    dist_author => 'Mathieu Alorent <cpan@kumy.net>',
    dist_abstract => 'Generate thermographic images.',
    requires    => {
        'Data::Dumper'   => 0,
        'Image::Magick'  => 0,
        'Math::Gradient' => 0,
        'PDL'            => 0,
        'PDL::NiceSlice' => 0,
        'PDL::IO::Pic'   => 0,
        'File::Temp'     => 0,
    },
    build_requires => {
        'Module::Build'     => 0,
    },
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources       => {
            repository  => {
                type    => "git",
                url     => "git://github.com/kumy/Graphics-HotMap.git",
                web     => "https://github.com/kumy/Graphics-HotMap",
            }
        },
    },
);

$builder->create_build_script();

