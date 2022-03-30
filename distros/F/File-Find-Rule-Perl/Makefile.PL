use strict;
use warnings;

use ExtUtils::MakeMaker;

my $developer = -f '.gitignore';

my %WriteMakefileArgs = (
  NAME => 'File::Find::Rule::Perl',
  AUTHOR => 'Adam Kennedy <adamk@cpan.org>',
  LICENSE => 'perl_5',
  ABSTRACT_FROM => 'lib/File/Find/Rule/Perl.pm',
  VERSION_FROM => 'lib/File/Find/Rule/Perl.pm',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    resources => {
      homepage => 'https://github.com/karenetheridge/File-Find-Rule-Perl',
      repository => {
        url => 'https://github.com/karenetheridge/File-Find-Rule-Perl.git',
        web => 'https://github.com/karenetheridge/File-Find-Rule-Perl',
        type => 'git',
      },
      bugtracker => {
        mailto => 'bug-File-Find-Rule-Perl@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Find-Rule-Perl',
      },
    },
    x_authority => 'cpan:ADAMK',
    x_contributors => [ # manually added, from git shortlog -e -s -n
      'Adam Kennedy <adam@ali.as>',
      'Alexandr Ciornii <alexchorny@gmail.com>',
      'Ash Berlin <ash_github@firemirror.com>',
      'Jonathan Yu <jawnsy@cpan.org>',
      'Karen Etheridge <ether@cpan.org>',
      'Tatsuhiko Miyagawa <miyagawa@bulknews.net>',
    ],
  },

  META_ADD => {
    'meta-spec' => { version => 2 },
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker' => '0',
        },
      },
      runtime => {
        requires => {
          'File::Find::Rule' => '0.20',
          'File::Spec' => '0.82',
          'Params::Util' => '0.38',
          'Parse::CPAN::Meta' => '1.38',
          'perl' => '5.006',
        },
      },
      test => {
        requires => {
          'Test::More' => '0',
        },
      },
    },
  },
  test => { TESTS => 't/*.t' . ( $developer ? ' xt/*/*.t' : '' ) },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
ExtUtils::MakeMaker->VERSION(6.98) if $developer;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
  if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if not $developer;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);
