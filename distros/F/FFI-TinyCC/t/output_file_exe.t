use strict;
use warnings;
use Test::More;
use FFI::TinyCC;
use Config;
use File::Temp qw( tempdir );
use File::chdir;
use FFI::Platypus;
use Path::Class qw( file dir );

plan skip_all => 'may be unsupported';
plan skip_all => "unsupported on $^O" if $^O =~ /bsd$/i || $^O eq 'darwin';
plan tests => 1;

subtest exe => sub
{
  plan tests => 5;
  local $CWD = tempdir( CLEANUP => 1 );

  my $tcc = FFI::TinyCC->new;

  eval { $tcc->set_output_type('exe') };
  is $@, '', 'tcc.set_output_type(exe)';

  eval { $tcc->compile_string(q{
    int
    main(int argc, char *argv[])
    {
      return 42;
    }
  })};
  
  is $@, '', 'tcc.compile_string';
  
  my $exe = "foo$Config{exe_ext}";
  
  note "exe=" . file($CWD, $exe);
  
  eval { $tcc->output_file($exe) };
  is $@, '', 'tcc.output_file';
  
  ok -f $exe, "created output file";
  
  system file($CWD, $exe), 'list', 'form';
  my $ret = $?;
  is $ret >> 8, 42, 'return value 42';
  unless($ret >> 8 == 42)
  {
    if($ret == -1)
    {
      diag "failed to execute: $!";
    }
    elsif($ret & 127)
    {
      diag "child died with siganl " . ($ret&127)
    }
    else
    {
      diag "child exited with value = " . ($ret>>8);
    }
  }

};

