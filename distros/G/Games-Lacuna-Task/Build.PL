#!/usr/bin/env perl

use Module::Build;
use utf8;

my $build = Module::Build->new(
    module_name         => 'Games::Lacuna::Task',
    license             => 'perl',
    dist_author         => 'Maroš Kollár <maros@cpan.org>',
    all_from            => 'lib/Games/Lacuna/Task.pm',
    dist_abstract       => 'Automation framework for the Lacuna Expanse MMPOG',
    configure_requires  => { 
        'Module::Build'                 => 0.38,
    },
    
    requires            => {
        'perl'                          => '5.10.1',

        'Moose'                         => '2.0000',
        'Class::Load'                   => 0,

        'Module::Pluggable'             => 0,

        'Games::Lacuna::Client'         => '0.003',

        'DBI'                           => 0,
        'DBD::SQLite'                   => 0,

        'Path::Class'                   => 0,
        'MooseX::Getopt'                => 0,
        'MooseX::Types::Path::Class'    => 0,
        'MooseX::Role::Parameterized'   => 0,

        'YAML::Any'                     => 0,
        'LWP'                           => 0,
        'Text::CSV'                     => 0,
        'JSON'                          => '2.00',
        
        'Term::ANSIColor'               => 0,
        'IO::Interactive'               => 0,

        'Digest::MD5'                   => 0,
        'Unicode::Normalize'            => 0,
        'Try::Tiny'                     => 0,
        'Term::ReadKey'                 => 0,

        'Email::Stuff'                  => 0,
        'Text::Table'                   => 0,
    },
    
    build_requires          => {
        'Test::More'                    => 0,
    },
    
    meta_merge              => {
        resources                       => {
            bugtracker =>  'https://github.com/maros/Games-Lacuna-Task/issues',
            repository =>  'git://github.com/maros/Games-Lacuna-Task.git',
        }
    },
);
$build->create_build_script;
