use strict;
use warnings;
use FFI::CheckLib;

my($name) = shift @ARGV;

unless(defined $name)
{
  print STDERR "usage: $0 name\n";
}

my($path) = find_lib( lib => $name );

if($path)
{
  print "$path\n";
  exit 0;
}
else
{
  print STDERR "not found.\n";
  exit 2;
}
