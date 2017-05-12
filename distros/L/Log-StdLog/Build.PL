use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Log::StdLog',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/Log/StdLog.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'IO::File'   => 0,
        'Fcntl'      => 0,
    },
    add_to_cleanup      => [ 'Log-StdLog-*' ],
);

$builder->create_build_script();
