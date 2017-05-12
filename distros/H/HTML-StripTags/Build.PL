use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::StripTags',
    license             => 'perl',
    dist_author         => 'Hinnerk Altenburg <hinnerk@cpan.org>',
    dist_version_from   => 'lib/HTML/StripTags.pm',
    dist_abstract       => 'Strip HTML or XML tags from a string with Perl like PHP\'s strip_tags() does',
    build_requires => {
        'Carp'            => 0,
        'Switch'          => 0,
        'Exporter'        => 0,
    },
    configure_requires => {
        'Module::Build'   => 0.36,
    },
    add_to_cleanup      => [ 'HTML-StripTags-*' ],
    create_makefile_pl  => 'traditional',
    # sign                => 1,
    create_license      => 1,
    create_readme       => 1,
    homepage    => 'http://www.hinnerk-altenburg.de/perl-strip_tags/',
    meta_add => {
        resources => {
            homepage    => 'http://www.hinnerk-altenburg.de/perl-strip_tags/',
            bugtracker  => 'http://github.com/hinnerk-a/perl-strip_tags/issues',
            repository  => 'http://github.com/hinnerk-a/perl-strip_tags',
        }
    }
);

$builder->create_build_script();
