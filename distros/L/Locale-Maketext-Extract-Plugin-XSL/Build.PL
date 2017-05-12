use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Locale::Maketext::Extract::Plugin::XSL',
    license             => 'perl',
    dist_author         => 'Michael Kroell <pepl@cpan.org>',
    dist_version_from   => 'lib/Locale/Maketext/Extract/Plugin/XSL.pm',
    build_requires => {
        'Test::More'  => 0,
    },
    requires => {
        'Locale::Maketext::Lexicon' => 0.70,
        'XML::LibXML' => 1.61,
        'Regexp::Common' => 0,
    },
    add_to_cleanup      => [ 'Locale-Maketext-Extract-Plugin-XSL-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    sign                => 1,
);

$builder->create_build_script();
