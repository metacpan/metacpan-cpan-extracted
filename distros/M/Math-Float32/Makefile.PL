use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

eval{ require 5.032;};

if($@) {
  warn "\n Aborting build of Math::Float32 because:\n$@\n";
  exit 0;
}


my %options = (
  NAME         => 'Math::Float32',
  AUTHOR       => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT     => "Perl interface to C's  float ('brain float') arithmetic",
  LICENSE      => 'perl',
  VERSION_FROM => 'Float32.pm',
  LIBS         =>  ['-lmpfr -lgmp -lquadmath'],
  clean        => { FILES => '*.exe *.txt' },
  META_MERGE   => {
    'meta-spec'  => { version => 2 },
    resources    => {
      repository   => {
        type         => 'git',
        url          => 'https://github.com/sisyphus/math-flt.git',
        web          => 'https://github.com/sisyphus/math-flt',
      },
    },
  },
);

my $prereq =  { 'Test::More' => '0.88',
                'Test::Warn' => '0.36',
                'Exporter'   => '5.58',
              };

$options{PREREQ_PM} = $prereq;

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
