use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'HTML::FormHandler::Render::Hash',
    license            => 'perl',
    dist_author        => 'Michael Nachbaur <mike@nachbaur.com>',
    dist_version_from  => 'lib/HTML/FormHandler/Render/Hash.pm',
    add_to_cleanup     => [ 'HTML-FormHandler-Render-Hash-*' ],
    create_makefile_pl => 'traditional',
    build_requires     => {
        'HTML::FormHandler' => 0,
        'Test::More'        => 0,
        'Test::Differences' => 0,
    },
);

$builder->create_build_script();
