use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'IPC::Open3::Utils',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/IPC/Open3/Utils.pm',
    requires          => {
        'Test::More' => 0,
        'IO::Select' => 0,
        'IPC::Open3' => 0,
        'IO::Handle' => 0,
    },
    add_to_cleanup => ['IPC-Open3-Utils-*'],
    meta_add       => {
        'meta-spec'    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            repository => {
                url  => 'https://github.com/drmuey/p5-IPC-Open3-Utils.git',
                web  => 'https://github.com/drmuey/p5-IPC-Open3-Utils',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/drmuey/p5-IPC-Open3-Utils/issues',
            },
        },
    },
);

$builder->create_build_script();
