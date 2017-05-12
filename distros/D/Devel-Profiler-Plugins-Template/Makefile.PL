use 5.006_001;

use strict;
use warnings FATAL => qw(all);

use ExtUtils::MakeMaker;
use File::Find qw(find);

my %directories;

find(sub { return unless m/\.t$/; $directories{$File::Find::name} = 1 }, 't');

my @tests = sort keys %directories;

WriteMakefile(
  NAME         => 'Devel::Profiler::Plugins::Template',
  VERSION_FROM => File::Spec->catfile(qw(lib Devel Profiler Plugins Template.pm)),
  PREREQ_PM    => { 'Devel::Profiler' => 0.05,
                    Template          => 2.13 },
  test         => { TESTS => join ' ', @tests },
);

sub MY::test {

  my $test = shift->MM::test(@_);

  if (eval { require Devel::Cover }) {
    $test .= <<EOF;
testcover ::
	-cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	-cover
EOF
  }

  return $test;
}
