use ExtUtils::MakeMaker;
my %options = %{
{
  'TYPEMAPS' => [
    'CPP.map'
  ],
  'NAME' => 'Math::Geometry::Planar::GPC::Inherit',
  'CC' => 'g++',
  'LIBS' => [
    '-lstdc++'
  ],
  'INC' => '',
  'VERSION' => '0.11'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
