package mymm;

use strict;
use warnings;
use File::Which qw( which );
use File::ShareDir::Dist::Install qw( install_config_set );

sub myWriteMakefile
{
  my %args = @_;

  my $exe = {};
  foreach my $name (qw( nm objdump readelf ))
  {
    $exe->{$name} = which($name);
    unless(defined $exe->{$name})
    {
      my $try = $ENV{"FFI_EXTRACTSYMBOLS_" . uc $name};
      $exe->{$name} = $try if defined $try && -e $try;
    }
  }

  install_config_set 'FFI-ExtractSymbols', exe => $exe;

  if($^O =~ /^(cygwin|MSWin32)$/)
  {
    install_config_set 'FFI-ExtractSymbols', 'ms_windows' => 1;
  }
  else
  {
    unless(defined $exe->{nm})
    {
      print STDERR "nm is required on this platform.\n";
      exit;
    }
    if($^O eq 'openbsd')
    {
      install_config_set 'FFI-ExtractSymbols', 'openbsd_nm' => 1;
    }
    else
    {
      # we assume that everyone else is going to support
      # nm -g -P foo.so
      # although I have no way of testing AIX, HP-UX
      install_config_set 'FFI-ExtractSymbols', 'posix_nm' => 1;
    }
  }

  ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;
