use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'EOL',
    license             => 'perl',
    script_files        => [ 'bin/eol' ],                             
    dist_author         => 'Todd Wylie <perldev@monkeybytes.org>',
    dist_version_from   => 'lib/EOL.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'EOL-*' ],
);

$builder->create_build_script();
