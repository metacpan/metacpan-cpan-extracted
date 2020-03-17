use ExtUtils::MakeMaker;
use Config;

$defines = '';

# Detect 'DoubleDouble' build
if($Config{nvtype} eq 'long double') {
  $nv = (2 ** 200) + (2 ** -200);
  $defines .= ' -DNV_IS_DOUBLEDOUBLE' if $nv != 2 ** 200;
}

my %options = %{
{
  NAME => 'List::Uniqnum',
  LICENSE  => 'perl',
  VERSION_FROM => 'Uniqnum.pm',
  DEFINE   => $defines,
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }