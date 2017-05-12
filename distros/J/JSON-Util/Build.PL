use strict;
use warnings;
use Module::Build;

use 5.010;

my $builder = Module::Build->new(
    module_name         => 'JSON::Util',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/JSON/Util.pm',
    configure_requires  => { 'Module::Build' => 0.38 },
    requires => {
        'Scalar::Util'  => 0,
        'IO::Any'       => 0,
        'Carp'          => 0,
        'JSON::MaybeXS' => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'File::Temp'        => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup      => [ 'JSON-Util-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/jozef/JSON-Util',
        },
    },
);

$builder->create_build_script();
