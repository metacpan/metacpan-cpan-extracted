# This Makefile.PL for Mac-SystemDirectory was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.49.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

$^O eq 'darwin' or die "OS unsupported\n";
use lib 'inc';
use ExtUtils::HasCompiler 0.014 'can_compile_loadable_object';
die "Requires a compiler\n" if not can_compile_loadable_object(quiet => 1);
use Config;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Locate Mac OS X Standard System Directories",
  "AUTHOR" => "Christian Hansen <chansen\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Mac-SystemDirectory",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Mac::SystemDirectory",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "XSLoader" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.14",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

%WriteMakefileArgs = (
    %WriteMakefileArgs,
    LDDLFLAGS => $Config{lddlflags} . ' -lobjc -framework CoreFoundation -framework Foundation',
    DEFINE => '-DHAS_BOOL',
);

my %FallbackPrereqs = (
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
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

# fix compilation issues on Darwin: see RT#73539
{
  package MY;
  sub xs_c {
    my $s = shift->SUPER::xs_c(@_);
    $s .= "\n\t\$(MV) \$*.c \$*.m";
    return $s;
  }
  sub c_o {
    my $s = shift->SUPER::c_o(@_);
    $s =~ s/\*\.c/\*.m/g;
    return $s;
  }
  sub xs_o {
    my $s = shift->SUPER::xs_o(@_);
    $s =~ s/\*\.c/\*.m/g;
    return $s;
  }
  sub special_targets {
    my $s = shift->SUPER::special_targets(@_);
    $s =~ s/\.xs \.c/.xs .m .c/;
    return $s;
  }
}
