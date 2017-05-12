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
);

$builder->create_build_script();
