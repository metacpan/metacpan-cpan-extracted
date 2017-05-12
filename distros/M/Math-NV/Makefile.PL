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

# Removed Data::Float dependency in 0.08
# Data::Float is handy for testing, but won't work with powerpc 'long double' builds.
# Don't add Data::Float::DoubleDouble as a prereq for 'doubledouble' builds as that module
# already lists Math::NV as one of its prereqs.
#my $prereq = $Config::Config{longdblkind} == 5 || $Config::Config{longdblkind} == 6 ||
#             ($Config::Config{nvsize} > 8 && $x > $nv)
#                    ? {}
#                    : {'Data::Float' => '0.012'};

my %options = %{
{
  'NAME' => 'Math::NV',
  'VERSION_FROM' => 'NV.pm',
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
