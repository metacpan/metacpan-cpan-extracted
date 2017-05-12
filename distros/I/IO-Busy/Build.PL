use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::Busy',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/IO/Busy.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Perl6::Export::Attrs' => 0,
    },
    add_to_cleanup      => [ 'IO-Busy-*' ],
);

$builder->create_build_script();
