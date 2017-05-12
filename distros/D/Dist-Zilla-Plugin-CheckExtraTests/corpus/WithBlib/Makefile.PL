
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

{
    my $contents = do {
        open my $fh, '<', 'lib/Foo.pm' || die "Couldn't open lib/Foo.pm: $!";
        local $/;
        <$fh>;
    };
    $contents =~ s/123/456/;
    open my $fh, '>', 'lib/Foo.pm' || die "Couldn't open lib/Foo.pm: $!";
    print $fh $contents;
}


my %WriteMakefileArgs = (
  "ABSTRACT" => "Test Library",
  "AUTHOR" => "foobar",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Foo",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Foo",
  "PREREQ_PM" => {},
  "VERSION" => "1.23",
  "test" => {
    "TESTS" => ""
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



