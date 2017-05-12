
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.48;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Cross-language event-driven ORM",
  "AUTHOR" => "Tom Molesworth <cpan\@entitymodel.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.48",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "EntityModel",
  "EXE_FILES" => [
    "bin/entitymodel"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "EntityModel",
  "PREREQ_PM" => {
    "CPS" => 0,
    "DateTime" => 0,
    "EntityModel::Class" => "0.012",
    "File::ShareDir" => "1.00",
    "Future" => "0.12",
    "IO::Async" => "0.50",
    "IO::Socket::IP" => 0,
    "JSON::XS" => "2.00",
    "List::MoreUtils" => 0,
    "Mixin::Event::Dispatch" => "1.000",
    "Module::Load" => 0,
    "POSIX::strptime" => 0,
    "Parser::MGC" => "0.10",
    "Template" => "2.24",
    "Tie::Cache::LRU" => 0,
    "Tie::Hash::LRU" => 0,
    "Try::Tiny" => 0,
    "XML::XPath" => "1.00",
    "curry" => "1.000"
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Test::CheckDeps" => "0.006",
    "Test::Class" => 0,
    "Test::Fatal" => "0.010",
    "Test::More" => "0.98",
    "Test::Refcount" => "0.07",
    "Test::Script" => "1.05",
    "blib" => 0
  },
  "VERSION" => "0.102",
  "test" => {
    "TESTS" => "t/*.t t/support/*.t"
  }
);


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
}

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


