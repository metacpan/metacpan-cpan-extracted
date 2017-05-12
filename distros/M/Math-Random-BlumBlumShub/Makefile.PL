use ExtUtils::MakeMaker;

my %options =
(
  'NAME' => 'Math::Random::BlumBlumShub',
  'LIBS' => ['-lgmp'],
  'VERSION_FROM' => 'BlumBlumShub.pm',
  'PREREQ_PM' => {'Math::GMPz'  => 0,},
  'LICENSE'  => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-random-blumblumshub.git',
        web => 'https://github.com/sisyphus/math-random-blumblumshub',
      },
    },
  },
);

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
