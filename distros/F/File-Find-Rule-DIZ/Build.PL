use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'File::Find::Rule::DIZ',
    dist_author        => 'Brian Cassidy <bricas@cpan.org>',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        'File::Find::Rule' => 0,
        'Archive::Zip'     => 0
    },
    build_requires     => {
        'Test::More'  => 0
    },
);
$build->create_build_script;
