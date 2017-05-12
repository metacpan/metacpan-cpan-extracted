use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Kwiki::PPerl',
    license             => 'perl',
    dist_author         => 'Chris Dent <cdent@burningchrome.com>',
    dist_version_from   => 'lib/Kwiki/PPerl.pm',
    requires => {
        'Test::More' => 0,
        'PPerl'      => 0,
    },
    add_to_cleanup      => [ 'Kwiki-PPerl-*' ],
);

$builder->create_build_script();
