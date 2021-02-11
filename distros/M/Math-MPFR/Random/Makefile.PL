use strict;
use warnings;
use ExtUtils::MakeMaker;

our $LIBS;

my %options = %{
{
  'TYPEMAPS' => [],
  'NAME' => 'Math::MPFR::Random',
  'LIBS' => $LIBS,
  'INC' => $INC,
  'VERSION_FROM' => 'Random.pm',
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
