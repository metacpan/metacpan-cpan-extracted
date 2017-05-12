use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::Interactive::Tiny',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/IO/Interactive/Tiny.pm',
    requires => {
        'Test::More' => 0, # for testing, I know I know: Test::XT
    },
    add_to_cleanup      => [ 'IO-Interactive-Tiny-*' ],
);

$builder->create_build_script();
