use 5.010;
use strict;
use warnings;
use Module::Build;

BEGIN{ die "OS unsupported" if ($^O eq 'MSWin32'); }

my $builder = Module::Build->new(
    module_name         => 'Filter::Heredoc', 
    license             => 'perl',
    dist_author         => q{Bertil Kronlund <bkron at cpan.org>},
    dist_version_from   => 'lib/Filter/Heredoc.pm',
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
    },
    add_to_cleanup      => [ 'Filter-Heredoc-*' ],
    recursive_test_files => 1,
    meta_merge => {
        resources => {
                      repository => 'https://github.com/bkron/Filter-Heredoc'
        }
    },
);

$builder->create_build_script();
