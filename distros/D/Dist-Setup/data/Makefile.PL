## no critic (Policy)

use [% min_perl_version %];
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;
[% IF data_dir %]use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
install_share '[% data_dir %]';[% END %]

WriteMakefile(
    NAME             => '[% name %]',
    DISTNAME         => '[% dist_name %]',
    AUTHOR           => q{[% author.name %] <[% author.email %]>},
    VERSION_FROM     => '[% base_package %]',
    [% IF abstract %]ABSTRACT         => q{[% abstract %]},[% END %]
    LICENSE          => 'mit',
    [% IF exe_files %]EXE_FILES        => [[% FOREACH f IN exe_files %]'[% f %]',[% END %]],[% END %]
    MIN_PERL_VERSION => '[% min_perl_version %]',
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
        directory => [ 'local', 'vendor' ],
      },
      [% IF github %]resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:[% github.username %]/[% github.repository_name %].git',
          web => 'https://github.com/[% github.username %]/[% github.repository_name %]',
        },
        bugtracker => {
          web => 'https://github.com/[% github.username %]/[% github.repository_name %]/issues',
        },
      },[% END %]
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean => { FILES => '[% dist_name %]-*' },
);

sub MY::postamble {
  my ($self) = @_;

  my @postamble;
  push @postamble, ::postamble() if *::postamble{CODE};

  push @postamble, <<"MAKE_FRAGMENT";
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
\tperltidy -b -bext='/' \$(shell find lib -name "*.pm")[% IF exe_files %][% FOREACH f IN exe_files %] [% f %][% END %][% END %]

spelling: export EXTENDED_TESTING = 1
spelling:
\t\$(PERLRUN) t/001-spelling.t --interactive

alltest: export EXTENDED_TESTING = 1
alltest: test
MAKE_FRAGMENT

[% IF data_dir %]  push @postamble, File::ShareDir::Install::postamble($self);

[% END %]  return join "\n", @postamble;
}

# You can add below this template a `postamble` sub that returns more content to
# add to the generated Makefile.
