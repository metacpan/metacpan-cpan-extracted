# This Makefile.PL for IPC-XPA was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use ExtUtils::MakeMaker;

use Alien::Base::Wrapper qw( Alien::XPA !export );

my %WriteMakefileArgs = (
  "ABSTRACT" => "Interface to the XPA messaging system",
  "AUTHOR" => "Diab Jerius <djerius\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "Alien::XPA" => 0,
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "IPC-XPA",
  "LICENSE" => "gpl",
  "NAME" => "IPC::XPA",
  "PREREQ_PM" => {
    "Alien::Base::Wrapper" => 0,
    "Alien::XPA" => 0,
    "Carp" => 0,
    "DynaLoader" => 0,
    "namespace::clean" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Action::Retry" => 0,
    "Alien::XPA" => 0,
    "Capture::Tiny" => 0,
    "Child" => 0,
    "Env" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Which" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test2::V0" => 0,
    "Test::More" => 0,
    "subs" => 0
  },
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    Alien::Base::Wrapper->mm_args2( OBJECT => 'util.o XPA.o' ),
);

my %FallbackPrereqs = (
  "Action::Retry" => 0,
  "Alien::Base::Wrapper" => 0,
  "Alien::XPA" => 0,
  "Capture::Tiny" => 0,
  "Carp" => 0,
  "Child" => 0,
  "DynaLoader" => 0,
  "Env" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Which" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Test2::V0" => 0,
  "Test::More" => 0,
  "namespace::clean" => 0,
  "parent" => 0,
  "strict" => 0,
  "subs" => 0,
  "warnings" => 0
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.040
if ($^O eq 'MSWin32') {
test_requires( 'Win32::Process' )
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.040
sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $FallbackPrereqs{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub test_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(TEST_REQUIRES => $module, $version_or_range);
}
