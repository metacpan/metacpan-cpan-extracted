use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::Template::Pluggable',
    license             => 'perl',
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
    dist_version_from   => 'lib/HTML/Template/Pluggable.pm',
    requires => {
        'Test::More'       => 0,
         # Required because about every test uses it.
        'Test::MockObject' => 1,
        'HTML::Template'   => 2.7,
        'Regexp::Common'   => 0, 
        'Scalar::Util'     => 0,
        'Class::Trigger'   => 0,
        'CGI'              => 3.06,
    },
    add_to_cleanup      => [ 'HTML-Template-Pluggable-*' ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);

$builder->create_build_script();
