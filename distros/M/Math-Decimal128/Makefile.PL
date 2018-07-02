use ExtUtils::MakeMaker;

use Config;
use 5.008;

$defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

# If you have the strtod128() function, either set $strtod128 to 1 or provide
# STRTOD128=1 as a command line argument to the Makefile.PL. (You might then
# also have to add the appropriate header to the #includes in Decimal64.xs.)
$strtod64 = 0;
for(@ARGV) {
  $strtod128 = 1 if $_ eq 'STRTOD128=1';
}
$defines .= " -DSTRTOD128_AVAILABLE" if $strtod128;

if($Config{byteorder} =~ /^1234/) {$defines .= " -DWE_HAVE_LENDIAN"}
else{$defines .= " -DWE_HAVE_BENDIAN"}

$defines .= " -DNV_IS_DOUBLE"
  if $Config{nvtype} eq 'double';

my %options = %{
{
  NAME => 'Math::Decimal128',
  DEFINE => $defines,
  LIBS => [
    '-lm'
  ],
  INC => '',
  LICENSE  => 'perl',
  VERSION_FROM => 'Decimal128.pm',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-decimal128.git',
        web => 'https://github.com/sisyphus/math-decimal128',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
