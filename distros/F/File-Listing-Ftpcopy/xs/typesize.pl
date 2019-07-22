use strict;
use Config;
use warnings;
use autodie;
use File::Spec;
use File::Temp qw( tempdir );

chdir 'xs';

mkdir '.tmp' unless -d '.tmp';
my $dir = tempdir( CLEANUP => 1, DIR => '.tmp' );

my @types = ("short", "int", "long ", "unsigned short", "unsigned int", 
"unsigned long", "long long", "unsigned long long");

my $counter = 0;

open my $header, '>', 'auto-typesize.h';

foreach my $type (@types)
{
  my $src = File::Spec->catfile($dir, "$counter.c");
  my $obj = File::Spec->catfile($dir, "$counter$Config{obj_ext}");
  my $bin = File::Spec->catfile($dir, "$counter.exe");
    
  $counter++;
  
  open my $out, '>', $src;
  print $out "int main() {\n";
  print $out "  $type t;\n";
  print $out "  return sizeof(t);\n";
  print $out "}\n";
  close $out;
  
  run("$Config{cc} $Config{ccflags} -c -o $obj $src");
  next if $?;
  
  run("$Config{ld} $Config{ldflags} -o $bin $obj");
  next if $?;
  
  run($bin, 'bogus'); # avoid calling the shell
                         # by passing bogus argument
  next if $? == -1 || $? & 127;
  my $size = $? >> 8;
  
  my $def_type = uc 'sizeof ' . $type;
  $def_type =~ s/ /_/g;
  print $header "#define $def_type $size /* systype-info */\n";
  #print sprintf("%02d %s\n", $size, $type);
}

close $header;

sub run
{
  #say "% @_";
  system @_;
}
