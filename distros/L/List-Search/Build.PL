use 5.006;
use strict;
use warnings;

use Module::Build 0.4004;

my $builder = Module::Build->new(
    module_name       => 'List::Search',
    license           => 'perl_5',
    dist_author       => 'Edmund von der Burg <evdb@ecclestoad.co.uk>',
    dist_version_from => 'lib/List/Search.pm',

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'perl'     => '5.006',
        'Exporter' => 0,
    },

    build_requires => {
        'Test::More' => '0.61',
    },

    meta_merge => {
        # This yet-to-be-documented key instructs meta_merge
        # to not downgrade our META.json from v2 to v1.4...
        # It may be documented soon though!
        # https://github.com/Perl-Toolchain-Gang/Module-Build/issues/97
        #    Confusing documentation in meta_merge and meta_add. #97
        # https://github.com/Perl-Toolchain-Gang/Module-Build/pull/98
        #    Module::Build::API: mention meta-spec meta key #98
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://foss.rapidcow.org/CPAN/List-Search/',
            bugtracker => {
                web  => 'https://codeberg.org/rapidcow/p5-List-Search/issues',
                mailto => 'bug-list-search@rt.cpan.org',
            },
            repository => {
                type => 'git',
                url  => 'https://codeberg.org/rapidcow/p5-List-Search.git',
                web  => 'https://codeberg.org/rapidcow/p5-List-Search',
            },
        },
    },

    # Perl Toolchain Summit this year (2026) just deprecated
    # Module::Signature (SIGNATURE).  What untimely timing! D:
    #
    # That said, I'd still sign distributions I release with
    # a SIGNATURE (as long as PAUSE doesn't groan at me with
    # a scary deprecation warning...)  I'm not sure how I feel
    # about Google/Microsoft/GitHub as the sole OIDC providers
    # personally, but I like keeping a hash to myself locally
    # without contacting the outside world much, so... :)
    sign => 1,
);

$builder->create_build_script();
