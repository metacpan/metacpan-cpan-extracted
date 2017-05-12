use strict;
use warnings;
use Module::Build;
use 5.006;

my $builder = Module::Build->new(
    module_name       => 'HTML::TokeParser::Simple',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/HTML/TokeParser/Simple.pm',
    requires          => {
        'HTML::Parser'     => 3.25,
        'HTML::TokeParser' => 2.24,
        'Test::More'       => 0,
        'Sub::Override'    => 0,
        'perl'             => 5.006,    # for 'our' declarations
    },
    add_to_cleanup     => ['HTML-TokeParser-Simple-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources =>
          { repository => 'https://github.com/Ovid/html-tokeparser-simple', },
    },
);

$builder->create_build_script();
