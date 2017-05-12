use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Google::Data::JSON',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/Google/Data/JSON.pm',
    requires => {
        'version'              => 0,
        'XML::Atom'            => 0,
        'XML::Simple'          => 0,
        'JSON::Any'            => 0,
        'List::MoreUtils'      => 0,
        'File::Slurp'          => 0,
        'Perl6::Export::Attrs' => 0,
        'UNIVERSAL::require'   => 0,
    },
    build_requires => {
        'Test::More'           => 0,
        'Test::NoWarnings'     => 0,
#        'Test::Perl::Critic'   => 0,
#        'Test::Pod'            => 1.14,
#        'Test::Pod::Coverage'  => 1.04,
    },
    add_to_cleanup      => [ 'Google-Data-JSON-*' ],
);

$builder->create_build_script();
