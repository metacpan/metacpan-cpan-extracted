use ExtUtils::MakeMaker;
use Config;

$defines = '';

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