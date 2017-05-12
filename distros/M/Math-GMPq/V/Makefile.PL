use ExtUtils::MakeMaker;
my %options = %{
{
  'NAME' => 'Math::GMPq::V',
  'INC' => $INC,
  'VERSION_FROM' => 'V.pm'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
