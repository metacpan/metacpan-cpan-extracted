use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Error::Exception',
    license             => 'perl',
    dist_author         => 'Stephen Vance <steve@vance.com>',
    dist_version_from   => 'lib/Error/Exception.pm',
    requires            => {
        'Error'             => 0,
        'Exception::Class'  => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Module::Locate'    => 0,
        'Test::Unit'        => 0,
    },
    add_to_cleanup      => [ 'Error-Exception-*' ],
);

$builder->create_build_script();
