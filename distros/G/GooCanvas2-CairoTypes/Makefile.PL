# This Makefile.PL for GooCanvas2-CairoTypes was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.48.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use ExtUtils::MakeMaker;

use ExtUtils::Depends;
use ExtUtils::PkgConfig;
my $depends = ExtUtils::Depends->new('GooCanvas2::CairoTypes', 'Glib', 'Cairo');
sub add_dep {
	my $name = shift;
	my %obj = ExtUtils::PkgConfig->find($name);
	$depends->set_inc($obj{cflags});
	$depends->set_libs($obj{libs});
}
add_dep('goocanvas-2.0');

my %WriteMakefileArgs = (
  "ABSTRACT" => "Bridge between GooCanvas2 and Cairo types",
  "AUTHOR" => "Alexey Sokolov <sokolov\@google.com>",
  "BUILD_REQUIRES" => {
    "Cairo" => 0,
    "Glib" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::Depends" => 0,
    "ExtUtils::MakeMaker" => 0,
    "ExtUtils::PkgConfig" => 0
  },
  "DISTNAME" => "GooCanvas2-CairoTypes",
  "LICENSE" => "perl",
  "NAME" => "GooCanvas2::CairoTypes",
  "PREREQ_PM" => {
    "Gtk3" => 0,
    "XSLoader" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    XSMULTI => 1,
    $depends->get_makefile_vars,
);

my %FallbackPrereqs = (
  "Cairo" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Glib" => 0,
  "Gtk3" => 0,
  "Test::More" => 0,
  "XSLoader" => 0,
  "strict" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
