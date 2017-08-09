use Test2::V0 -no_srand => 1;
use FindBin;
use FFI::TinyCC;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Tiny qw( path );
use Config;

subtest 'c source code' => sub {
  my $tcc = FFI::TinyCC->new;
  
  my $file = path($FindBin::Bin, 'c', 'return22.c');
  note "file = $file";
  
  eval { $tcc->add_file($file) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

done_testing;
