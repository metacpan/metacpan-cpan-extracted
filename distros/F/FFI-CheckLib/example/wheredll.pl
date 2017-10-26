use strict;
use warnings;
use FFI::CheckLib;

my($name) = shift @ARGV;

unless(defined $name)
{
  print STDERR "usage: $0 name\n";
}

my(@path) = find_lib( lib => '*', verify => sub { $_[0] eq $name } );

if(@path)
{
  print "$_\n" for @path;
  exit 0;
}
else
{
  print STDERR "not found.\n";
  exit 2;
}
