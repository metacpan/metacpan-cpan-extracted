
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Bundle of plugins needed for building a rakudo distribution',
  'AUTHOR' => 'Jonathan Scott Duff <duff@pobox.com>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-PluginBundle-Rakudo',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::PluginBundle::Rakudo',
  'PREREQ_PM' => {
    'Dist::Zilla::Plugin::AutoVersion' => '0',
    'Dist::Zilla::Plugin::GatherDir' => '0',
    'Dist::Zilla::Plugin::GitObtain' => '0',
    'Dist::Zilla::Plugin::License' => '0',
    'Dist::Zilla::Plugin::Manifest' => '0',
    'Dist::Zilla::Plugin::PruneCruft' => '0',
    'Dist::Zilla::Plugin::PruneFiles' => '0',
    'Dist::Zilla::Plugin::SvnObtain' => '0',
    'Dist::Zilla::Plugin::TemplateFiles' => '0',
    'Dist::Zilla::PluginBundle::Git' => '0'
  },
  'VERSION' => '0.01',
  'test' => {
    'TESTS' => ''
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



