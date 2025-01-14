use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  NAME => "My::Module",
##{ $plugin->get_default(qw(ABSTRACT AUTHOR LICENSE VERSION)) ##}
##{ $plugin->get_prereqs(1) ##}
);

# BEGIN code inserted by Dist::Zilla::Plugin::AlienBuild
# Old code was here...
die;
# END code inserted by Dist::Zilla::Plugin::AlienBuild

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
} # end unless ExtUtils::MakeMaker is 6.63_03 or newer

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
} # end unless ExtUtils::MakeMaker is 6.56 or newer

WriteMakefile(%WriteMakefileArgs);

