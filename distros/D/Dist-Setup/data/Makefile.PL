## no critic (Policy)

use [% min_perl_version %];
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;
[% IF data_dir %]use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
install_share '[% data_dir %]';
[% END %]
WriteMakefile(
    NAME             => '[% name %]',
    DISTNAME         => '[% dist_name %]',
    AUTHOR           => q{[% author.name %] <[% author.email %]>},
    VERSION_FROM     => '[% base_package %]',
[% IF abstract %]    ABSTRACT         => q{[% abstract %]},
[% END %]    LICENSE          => 'mit',
[% IF exe_files %]    EXE_FILES        => [[% FOREACH f IN exe_files %]'[% f %]',[% END %]],
[% END %]    MIN_PERL_VERSION => '[% min_perl_version %]',
    MAN3PODS         => {},
    # Directories in which we look for Makefile.PL. In general could be omitted but is needed in case there
    # is a file named Makefile.PL in a sub-directory. Should be customized if such a file needs to be
    # processed by ExtUtils.
    DIR              => [],
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        directory => [ 'local', 'vendor', 't' ],
[% IF no_index.namespaces %]        namespace => [[% FOREACH n IN no_index.namespaces %]'[% n %]',[% END %]],
[% END %][% IF no_index.packages %]        package => [[% FOREACH p IN no_index.packages %]'[% p %]',[% END %]],
[% END %]      },
[% IF keywords %]      keywords => [[% FOREACH k IN keywords %]'[% k %]',[% END %]],
[% END %]      resources => {
[% IF homepage %]        homepage => q{[% homepage %]},
[% END %][% IF github %]        repository => {
          type => 'git',
          url => 'git@github.com:[% github.username %]/[% github.repository_name %].git',
          web => 'https://github.com/[% github.username %]/[% github.repository_name %]',
        },
        bugtracker => {
          web => 'https://github.com/[% github.username %]/[% github.repository_name %]/issues',
        },
[% END %]      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean => { FILES => '[% dist_name %]-*' },
);

# These platforms (usually) have GNU Make by default so the syntax that we use
# for our custom targets below will work (especially to export environment
# variables).
# On other platforms, we disable the custom parts of our Makefile generation, as
# the generated Makefile would otherwise not parse correctly.
sub supported_platform {
  return $^O =~ m/^(?:linux|cygwin|MSWin32)$/;
}

sub MY::postamble {
  my ($self) = @_;

  my @postamble;
  push @postamble, ::postamble() if *::postamble{CODE};

  push @postamble, <<"MAKE_FRAGMENT" if supported_platform();
ALL_PM := \$(shell find lib -name "*.pm")
ALL_EXE :=[% IF exe_files %][% FOREACH f IN exe_files %] [% f %][% END %][% END %]

.PHONY: distupload cover critic rawcritic tidy spelling alltest clean clean_coverdb pod2html exe

distupload: distcheck disttest
\t\$(MAKE) tardist
\tcpan-upload --directory Dist-Setup \$(DISTVNAME).tar\$(SUFFIX)

cover:
\tcover -test

critic: export EXTENDED_TESTING = 1
critic: all
\tperl -Ilib t/001-perlcritic.t 2>&1 | less

rawcritic:
\tperlcritic lib [% IF exe_files %]script[% END %]

tidy:
\tperltidy -b -bext='/' \$(ALL_PM) \$(ALL_EXE)

spelling: export EXTENDED_TESTING = 1
spelling:
\t\$(PERLRUN) t/001-spelling.t --interactive

[% IF test_harness_options %]test: export HARNESS_OPTIONS = [% test_harness_options %]

[% END %]alltest: export EXTENDED_TESTING = 1
alltest: test

clean:: clean_coverdb clean_build clean_pod2html

clean_coverdb:
\trm -fr cover_db

clean_build:
\trm -fr build

clean_pod2html:
\trm -fr pod2html

PM_HTML := \$(patsubst %.pm, pod2html/%.html, \$(ALL_PM))
EXE_HTML := \$(patsubst %, pod2html/%.html, \$(ALL_EXE))
pod2html: \$(PM_HTML) \$(EXE_HTML)

\$(PM_HTML): pod2html/%.html: %.pm
\tmkdir -p \$(shell dirname \$@)
\tpod2html --infile \$< --outfile \$@

\$(EXE_HTML): pod2html/%.html: %
\tmkdir -p \$(shell dirname \$@)
\tpod2html --infile \$< --outfile \$@

EXE_EXE := \$(patsubst %, build/%\$(EXE_EXT), \$(ALL_EXE))

exe: export PAR_VERBATIM=1
exe: build \$(EXE_EXE)

build:
\tmkdir -p build

\$(EXE_EXE): build/%\$(EXE_EXT): %
\tpp -o \$@ -cd build/pp.cache -I lib -F "PodStrip=.*\\b[% dist_package %]\\b(*COMMIT)(*FAIL)|.*" \$<

MAKE_FRAGMENT

[% IF data_dir %]  push @postamble, File::ShareDir::Install::postamble($self);

[% END %]  return join "\n", @postamble;
}

# You can add below this template a `postamble` sub that returns more content to
# add to the generated Makefile.
