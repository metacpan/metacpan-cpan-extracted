use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Inline::Ruby::dRuby::Client',
    license             => 'perl',
    dist_author         => 'Yuichi Tateno <hotchpotch@gmail.com>',
    dist_version_from   => 'lib/Inline/Ruby/dRuby/Client.pm',
    requires => {
        'Test::More' => 0,
        'Inline::Ruby' => 0,
    },
    add_to_cleanup      => [ 'Inline-Ruby-dRuby-Client-*' ],
);

$builder->create_build_script();
