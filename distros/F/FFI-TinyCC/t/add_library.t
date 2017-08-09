use Test2::V0 -no_srand => 1;
use FindBin;
use FFI::TinyCC;
use File::chdir;
use File::Temp qw( tempdir );
use Archive::Ar 2.02;
use Config;
use Path::Tiny qw( path );

my $srcdir = path("$FindBin::Bin/c");
my $libdir = path(tempdir( CLEANUP => 1 ), 'lib');
mkdir $libdir;
my $opt = "-I$srcdir -L$libdir";

note "libdir=$libdir";

subtest 'create lib' => sub {

  local $CWD = tempdir( CLEANUP => 1 );
  
  my $ar = Archive::Ar->new;
  my $count = 1;

  foreach my $name (qw( one two three ))
  {
    subtest "compile $name" => sub {
      my $tcc = FFI::TinyCC->new;
      
      eval { $tcc->set_options($opt) };
      is $@, '', "tcc.set_options($opt)";

      my $cfile = path($srcdir, "$name.c");
      
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
    my $filename = path($libdir, 'libonetwothree.a');
    my $r = $ar->write("$filename");
    isnt $r, undef, "ar.write($filename)";
  };
};

subtest 'use lib' => sub {

  my $tcc = FFI::TinyCC->new;
  
  eval { $tcc->set_options($opt) };
  is $@, '', "tcc.set_options($opt)";

  my $main = path($srcdir, 'main.c');
  eval { $tcc->add_file($main) };
  is $@, '', "tcc.add_file($main)";

  eval { $tcc->add_library('onetwothree') };
  is $@, '', 'tcc.add_library(onetwothree)';

  is eval { $tcc->run }, 6, 'tcc.run';
  note $@ if $@;

};

done_testing;
