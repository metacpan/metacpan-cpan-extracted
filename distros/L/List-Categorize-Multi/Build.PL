use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'List::Categorize::Multi',
    license             => 'Artistic_2_0',
    dist_author         => q{Laurent Dami <dami@cpan.org>},
    dist_version_from   => 'lib/List/Categorize/Multi.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::Deep' => 0,
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
    },
    add_to_cleanup     => [ 'List-Categorize-Multi-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/List-Categorize-Multi',
       }
     },
);

$builder->create_build_script();
