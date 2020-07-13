use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = %{
{
  'NAME' => 'Math::MPFR::Prec',
  'LIBS' => '-lmpfr -lgmp',
  'VERSION_FROM' => 'Prec.pm'
}
};

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
