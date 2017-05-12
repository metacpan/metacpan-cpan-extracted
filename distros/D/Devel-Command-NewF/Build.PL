use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::Command::NewF',
    license             => 'perl',
    dist_author         => 'Joe McMahon <mcmahon@cpan.org>',
    dist_version_from   => 'lib/Devel/Command/NewF.pm',
    requires => {
        'Test::More' => 0,
    # Add your required modules here.
    },
    add_to_cleanup      => [ 'Devel-Command-NewF-*' ],
);

$builder->create_build_script();
