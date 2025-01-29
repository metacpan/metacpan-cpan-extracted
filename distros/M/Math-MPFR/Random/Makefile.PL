use strict;
use warnings;
use ExtUtils::MakeMaker;

our $LIBS;
our $DEFS;

$DEFS .= " -DWIN32_FMT_BUG_IGNORE" if $ENV{WIN32_FMT_BUG_IGNORE};

my %options = %{
  {
  'TYPEMAPS' => [],
  'NAME'     => 'Math::MPFR::Random',
  'LIBS'     => $LIBS,
  'INC'      => $INC,
  'DEFINE'   => $DEFS,
  'VERSION_FROM' => 'Random.pm',
  'clean'        => { FILES => '*.exe' },
  }
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
