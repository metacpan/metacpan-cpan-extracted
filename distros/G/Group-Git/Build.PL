use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Group::Git',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Group/Git.pm',
    requires          => {
        'perl'                 => '5.008',
        'Config::Any'          => 0,
        'File::chdir'          => 0,
        'Getopt::Alt'          => '0.5.0',
        'IO::Prompt'           => 0,
        'JSON'                 => 0,
        'List::MoreUtils'      => 0,
        'Module::Pluggable'    => 0,
        'Moo'                  => 1,
        'Moo::Role'            => 1,
        'Net::GitHub'          => '0.57',
        'Path::Tiny'           => 0,
        'Type::Utils'          => 1,
        'Types::Standard'      => 1,
        'Term::ANSIColor'      => 0,
        'version'              => 0,
        'WWW::Mechanize'       => 0,
        'YAML::Syck'           => 0,
        'namespace::autoclean' => 0,
        'version'              => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'Group-Git-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Group-Git.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Group::Git',
        },
    },
);

$builder->create_build_script();
