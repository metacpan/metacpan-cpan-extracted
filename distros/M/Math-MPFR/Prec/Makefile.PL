use ExtUtils::MakeMaker;
my %options = %{
{
  'NAME' => 'Math::MPFR::Prec',
  'LIBS' => $LIBS,
  'INC' => $INC,
  'VERSION_FROM' => 'Prec.pm'
}
};

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
