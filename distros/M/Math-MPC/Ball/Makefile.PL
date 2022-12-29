use strict;
use warnings;
use ExtUtils::MakeMaker;

our $LIBS;
our $DEFS;

my $libopts = '-lmpc -lmpfr -lgmp';
$libopts    = '-lquadmath -lmpc -lmpfr -lgmp'
  if ($^O eq 'cygwin' && $Config::Config{nvtype} eq '__float128');

my %options = %{
{
  'TYPEMAPS' => ['../typemap'],
  'NAME'     => 'Math::MPC::Ball',
  'LIBS'     => [
                 $libopts
                ],
  'INC'      => $INC,
  'DEFINE'   => $DEFS,
  'VERSION_FROM' => 'Ball.pm',
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
# sub MY::makefile { '' }
