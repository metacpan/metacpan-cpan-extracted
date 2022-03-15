use strict;
use warnings;
use ExtUtils::MakeMaker;

our $LIBS;
our $DEFS;

my %options = %{
{
  'TYPEMAPS' => [],
  'NAME'     => 'Math::MPFI::Constant',
  'LIBS'     => $LIBS,
  'INC'      => $INC,
  'DEFINE'   => $DEFS,
  'VERSION_FROM' => 'Constant.pm',
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
