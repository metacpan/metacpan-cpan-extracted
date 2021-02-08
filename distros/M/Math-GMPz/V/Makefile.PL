# The aim is that this module will not call any library functions - hence no -lgmp link

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %options = %{
{
  'NAME' => 'Math::GMPz::V',
  'INC' => $INC,
  'VERSION_FROM' => 'V.pm'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
