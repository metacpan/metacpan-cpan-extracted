use strict;
use warnings;
use FindBin;
use Test::More tests => 1;
use FFI::TinyCC;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Class qw( file dir );
use Config;

subtest 'c source code' => sub {
  plan tests => 2;

  my $tcc = FFI::TinyCC->new;
  
  my $file = file($FindBin::Bin, 'c', 'return22.c');
  note "file = $file";
  
  eval { $tcc->add_file($file) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

