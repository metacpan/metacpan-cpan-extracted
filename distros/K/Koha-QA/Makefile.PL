use strict;
use warnings;
use Module::CPANfile;
use ExtUtils::MakeMaker;
use File::ShareDir::Install qw(install_share);

install_share 'share';

my $spec = Module::CPANfile->load('cpanfile')->prereq_specs;

WriteMakefile(
    NAME             => 'Koha::QA',
    VERSION_FROM     => 'lib/Koha/QA.pm',
    ABSTRACT_FROM    => 'lib/Koha/QA.pm',
    AUTHOR           => 'Jonathan Druart <jonathan.druart@bugs.koha-community.org>',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.16.0',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/joubu/koha-qa.git',
                web  => 'https://gitlab.com/joubu/koha-qa',
            },
            bugtracker => {
                web => 'https://gitlab.com/joubu/koha-qa/-/issues',
            },
        },
    },

    PREREQ_PM => {
        %{ $spec->{runtime}{requires} // {} },
    },

    TEST_REQUIRES => {
        %{ $spec->{test}{requires} // {} },
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '6.52',
        'File::ShareDir::Install' => 0,
        %{ $spec->{configure}{requires} // {} },
    },

    test => {
        TESTS => 't/*.t t/**/*.t',
    },

    clean => {
        FILES => 'share/node_modules',
    },
);

package MY;

sub postamble {
    my $self = shift;

    my @ret = File::ShareDir::Install::postamble($self);

    push @ret, <<'MAKEFILE';

# js-deps is opt-in: it is NOT wired into pure_all/config, so plain
# `make`/`make test`/`make install` (and CPAN Testers/cpanm installs)
# never reach out to the npm registry. Run `make js-deps` explicitly
# before `make` to enable the Tidy::JS/Tidy::TT prettier-backed checks;
# without it, those checkers report 'prettier_not_installed' at runtime
# instead of failing the build.
js-deps: pm_to_blib
	cd share && yarn install --frozen-lockfile
	$(NOECHO) $(MKPATH) $(INST_LIB)/auto/share/dist/$(DISTNAME)
	$(NOECHO) $(RM_RF) $(INST_LIB)/auto/share/dist/$(DISTNAME)/node_modules
	$(NOECHO) $(CP) -r share/node_modules $(INST_LIB)/auto/share/dist/$(DISTNAME)/node_modules

MAKEFILE

    return join "\n", @ret;
}
