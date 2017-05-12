use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Feed::Source::Page2RSS',
    license             => 'perl',
    dist_author         => 'Emmanuel Di Pretoro <<manu@bjornoya.net>>',
    dist_version_from   => 'lib/Feed/Source/Page2RSS.pm',
    build_requires => {
        'Test::More' => 0,
        'URI' => 0,
    },
    add_to_cleanup      => [ 'Feed-Source-Page2RSS-*' ],
);

$builder->create_build_script();
