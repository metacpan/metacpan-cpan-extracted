# This -*- cperl -*- program writes a Makefile

use lib '.';

use inc::Module::Install;

all_from('lib/Devel/Todo/Find.pm');

install_script('Programs/todofind');

requires('File::Find');
# These are needed by the todofind utility:
requires('Getopt::Long');
# These are needed during `make test`:
test_requires('Test::More');
recommends('Test::Pod');
recommends('Test::Pod::Coverage');

use Env;
if ($ENV{MTHURN_PERL_DEV})
  {
  warn "DDD This is author's development environment\n";
  use_ptar();
  } # if

WriteAll;

if (0 && $ENV{MTHURN_PERL_DEV})
  {
  my $sFnameMakefile = q{Makefile};
  eval "use File::Slurp";
  my $s = read_file($sFnameMakefile);
  if ($s !~ s/(DIRFILESEP\s*=\s*).+$/$1\//m)
    {
    warn " EEE did not find DIRFILESEP in Makefile\n";
    } # if
  if ($s !~ s/(pm_to_blib\()\{\{\@ARGV}}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find pm_to_blib@ARGV in Makefile\n";
    } # if
  if ($s !~ s/(from_to\s+=>\s+)\{\{\@ARGV}}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find from_to@ARGV in Makefile\n";
    } # if
  write_file($sFnameMakefile, $s);
  } # if

__END__

