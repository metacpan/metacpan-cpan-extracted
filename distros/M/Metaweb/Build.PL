use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Metaweb',
    license             => 'perl',
    dist_author         => 'Kirrily Robert <skud@cpan.og>',
    dist_version_from   => 'lib/Metaweb.pm',
    requires => {
        'JSON::XS' => 0,
        'URI::Escape' => 0,
        'Class::Accessor' => 0,
        'LWP::UserAgent' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Metaweb-*' ],
);

$builder->create_build_script();
