use strict;
use warnings;
use FindBin;
use Test::More tests => 2;
use FFI::TinyCC;
use File::chdir;
use File::Temp qw( tempdir );
use Archive::Ar 2.02;
use Config;
use Path::Class qw( file dir );

my $srcdir = dir($FindBin::Bin, 'c');
my $libdir = dir(tempdir( CLEANUP => 1 ), 'lib');
mkdir $libdir;
my $opt = "-I$srcdir";

note "libdir=$libdir";

subtest 'create lib' => sub {

  plan tests => 4;

  local $CWD = tempdir( CLEANUP => 1 );
  
  my $ar = Archive::Ar->new;
  my $count = 1;

  foreach my $name (qw( one two three ))
  {
    subtest "compile $name" => sub {
      plan tests => 5;
    
      my $tcc = FFI::TinyCC->new;
      
      eval { $tcc->set_options($opt) };
      is $@, '', "tcc.set_options($opt)";

      my $cfile = file($srcdir, "$name.c");
      
      eval { $tcc->set_output_type('obj') };
      is $@, '', 'tcc.set_output_type(obj)';
      
      eval { $tcc->add_file($cfile) };
      is $@, '', "tcc.add_file($cfile)";
    
      my $obj = "$name$Config{obj_ext}";
      eval { $tcc->output_file($obj) };
      is $@, '', "tcc.output_file($obj)";
    
      my $r = $ar->add_files("$obj");
      is $r, $count++, "ar.add_files($obj)";
    
    };
  }
  
  subtest "create libonetwothree.a" => sub {
    plan tests => 1;
    my $filename = file($libdir, 'libonetwothree.a');
    my $r = $ar->write("$filename");
    isnt $r, undef, "ar.write($filename)";
  };
};

subtest 'use lib' => sub {

  plan tests => 5;

  my $tcc = FFI::TinyCC->new;
  
  eval { $tcc->set_options($opt) };
  is $@, '', "tcc.set_options($opt)";

  eval { $tcc->add_library_path($libdir) };
  is $@, '', "tcc.add_library_path($libdir)";

  my $main = file($srcdir, 'main.c');
  eval { $tcc->add_file($main) };
  is $@, '', "tcc.add_file($main)";

  eval { $tcc->add_library('onetwothree') };
  is $@, '', 'tcc.add_library(onetwothree)';

  is eval { $tcc->run }, 6, 'tcc.run';
  note $@ if $@;

};
