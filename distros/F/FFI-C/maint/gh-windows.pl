use strict;
use warnings;
use File::chdir;

sub run
{
  my @cmd = @_;
  print "+@cmd\n";
  system @cmd;
  exit 2 if $?;
}

run( qw( git clone https://github.com/Perl5-FFI/FFI-Platypus.git \FFI-Platypus ) );

{
  local $CWD = "/FFI-Platypus";
  run( "dzil authordeps --missing | cpanm -n" );
  run( qw( dzil install ) );
  run( "bogus command" );
}
