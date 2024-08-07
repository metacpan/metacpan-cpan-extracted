# Generated by git-ship. See 'git-ship --man' for help or https://github.com/jhthorsen/app-git-ship
use utf8;
use ExtUtils::MakeMaker;
my %WriteMakefileArgs = (
  NAME           => 'LinkEmbedder',
  AUTHOR         => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE        => 'artistic_2',
  ABSTRACT_FROM  => 'lib/LinkEmbedder.pm',
  VERSION_FROM   => 'lib/LinkEmbedder.pm',
  EXE_FILES      => [qw()],
  OBJECT         => '',
  BUILD_REQUIRES => {}
,
  TEST_REQUIRES  => {
  'Test::More' => '1.00'
}
,
  PREREQ_PM      => {
  'Mojolicious' => '9.11'
}
,
  META_MERGE     => {
    'dynamic_config' => 0,
    'meta-spec'      => {version => 2},
    'resources'      => {
      bugtracker => {web => 'https://github.com/jhthorsen/linkembedder/issues'},
      homepage   => 'https://github.com/jhthorsen/linkembedder',
      repository => {
        type => 'git',
        url  => 'https://github.com/jhthorsen/linkembedder.git',
        web  => 'https://github.com/jhthorsen/linkembedder',
      },
    },
    'x_contributors' => [
  'Jan Henning Thorsen'
]
,
  },
  test => {TESTS => (-e 'META.yml' ? 't/*.t' : 't/*.t xt/*.t')},
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.63_03') }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

WriteMakefile(%WriteMakefileArgs);
