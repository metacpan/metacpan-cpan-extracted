use ExtUtils::MakeMaker;
use 5.010;

my $defines = $Config::Config{nvtype} eq 'long double'
                ? '-DNV_IS_LONG_DOUBLE'
                : $Config::Config{nvtype} eq '__float128' ? '-DNV_IS_FLOAT128'
                                                          : '-DNV_IS_DOUBLE';

print "Defining $defines\n";

# For testing for DoubleDouble nvtype:
my $nv = 1.0;
my $x = $nv + (2 ** -1000);


my %options = %{
{
  'NAME' => 'Math::NV',
  'VERSION_FROM' => 'NV.pm',
  'PREREQ_PM' => {
                'Math::MPFR'          => '4.07',

               },
  'LIBS' => [
    '-lm'
  ],
  'INC' => '',
  'DEFINE' => $defines,
  'LICENSE'  => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-nv.git',
        web => 'https://github.com/sisyphus/math-nv',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
