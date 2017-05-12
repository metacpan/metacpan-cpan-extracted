use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::Prompt',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    dist_version_from   => 'lib/IO/Prompt.pm',
    requires => {
        'Test::More' => 0,
        'IO::Handle'    => 0,
        'Term::ReadKey' => 0,
        'Want'  => 0,
    },
    add_to_cleanup      => [ 'IO-Prompt-*' ],
);

$builder->create_build_script();
