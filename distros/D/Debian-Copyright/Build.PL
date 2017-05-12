use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Debian::Copyright',
    license             => 'gpl',
    dist_author         => q{Nicholas Bamber <nicholas@periapt.co.uk>},
    dist_version_from   => 'lib/Debian/Copyright.pm',
    build_requires => {
        'Test::More' => 0,
        'Perl6::Slurp' => 0,
        'Test::LongString' => 0,
        'Test::Exception' => 0,
        'Test::Deep' => 0,
        'Test::NoWarnings' => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    requires => {
        'perl' => 5.006,
        'Parse::DebControl' => 0,
        'Tie::IxHash' => 0,
        'Array::Unique' => 0,
        'Class::Accessor'=> 0,
        perl=>'5.10.1',
    },
    add_to_cleanup      => [ 'Debian-Copyright-*' ],
    create_makefile_pl => 'traditional',
    create_readme => 1,
    meta_merge => {
        resources => {
            repository =>
'http://github.com/periapt/Debian-Copyright/tree',
        },
    },
);

$builder->create_build_script();
