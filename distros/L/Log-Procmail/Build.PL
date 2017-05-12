use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Log::Procmail',
    license             => 'perl',
    dist_author         => 'Philippe "BooK" Bruhat <book@cpan.org>',
    dist_version_from   => 'lib/Log/Procmail.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Log-Procmail-*' ],
    script_files        => [ 'scripts/mailstat.pl' ],
    meta_merge => {
        resources => {
            repository => 'http://github.com/book/Log-Procmail',
        },
    },
);

$builder->create_build_script();
