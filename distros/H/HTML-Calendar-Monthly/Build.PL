use strict;
use warnings;
use Module::Build;
use File::Spec;

my $builder = Module::Build->new(
    module_name         => 'HTML::Calendar::Monthly',
    license             => 'perl',
    dist_author         => 'Johan Vromans <jv@cpan.org>',
    dist_version_from   => 'lib/HTML/Calendar/Monthly.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Date::Simple' => 0,
    },
    script_files    => [ map { File::Spec->catfile("script", $_) }
			 qw(hcgen) ],
    add_to_cleanup      => [ 'HTML-Calendar-Monthly-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
