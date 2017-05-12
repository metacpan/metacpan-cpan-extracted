
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'JROCKWAY does not like boilerplate',
  'AUTHOR' => 'Jonathan Rockway <jrockway@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0',
    'ok' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dist-Zilla-PluginBundle-JROCKWAY',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Dist::Zilla::PluginBundle::JROCKWAY',
  'PREREQ_PM' => {
    'DateTime' => '0',
    'Dist::Zilla::Plugin::AutoPrereqs' => '0',
    'Dist::Zilla::Plugin::AutoVersion' => '0',
    'Dist::Zilla::Plugin::ConfirmRelease' => '0',
    'Dist::Zilla::Plugin::ExecDir' => '0',
    'Dist::Zilla::Plugin::ExtraTests' => '0',
    'Dist::Zilla::Plugin::GatherDir' => '0',
    'Dist::Zilla::Plugin::License' => '0',
    'Dist::Zilla::Plugin::MakeMaker' => '0',
    'Dist::Zilla::Plugin::Manifest' => '0',
    'Dist::Zilla::Plugin::ManifestSkip' => '0',
    'Dist::Zilla::Plugin::MetaConfig' => '0',
    'Dist::Zilla::Plugin::MetaJSON' => '0',
    'Dist::Zilla::Plugin::MetaYAML' => '0',
    'Dist::Zilla::Plugin::PkgVersion' => '0',
    'Dist::Zilla::Plugin::PodSyntaxTests' => '0',
    'Dist::Zilla::Plugin::PodWeaver' => '0',
    'Dist::Zilla::Plugin::PruneCruft' => '0',
    'Dist::Zilla::Plugin::Readme' => '0',
    'Dist::Zilla::Plugin::Repository' => '0',
    'Dist::Zilla::Plugin::ShareDir' => '0',
    'Dist::Zilla::Plugin::TestRelease' => '0',
    'Dist::Zilla::Plugin::UploadToCPAN' => '0',
    'Dist::Zilla::PluginBundle::Git' => '0',
    'Dist::Zilla::Role::Plugin' => '0',
    'Dist::Zilla::Role::PluginBundle::Easy' => '0',
    'Moose' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '1.102911',
  'test' => {
    'TESTS' => 't/*.t'
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



