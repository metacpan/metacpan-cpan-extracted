
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share module => "Dist::Zilla::MintingProfile::Author::Caelum", "profiles";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Basic Minting Profile for \@AVAR",
  "AUTHOR" => "Rafael Kitover <rkitover\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Dist-Zilla-MintingProfile-Author-Caelum",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dist::Zilla::MintingProfile::Author::Caelum",
  "PREREQ_PM" => {
    "Dist::Zilla::Plugin::Git::Init" => 0,
    "Dist::Zilla::Plugin::Git::PushInitial" => 0,
    "Dist::Zilla::Plugin::GitHub::Create" => "0.30",
    "Dist::Zilla::PluginBundle::AVAR" => "0.28",
    "Dist::Zilla::Role::MintingProfile::ShareDir" => 0,
    "Moose" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.08",
  "test" => {
    "TESTS" => "t/*.t"
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


