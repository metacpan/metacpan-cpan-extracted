use strict;
use warnings;
use Test::More;
use FFI::TinyCC;
use FFI::Platypus;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Class qw( file dir );
use Config;

plan skip_all => "unsupported on $^O" if $^O =~ /^(darwin|MSWin32|gnukfreebsd)$/;
plan skip_all => "unsupported on $^O $Config{archname}" if $^O eq 'linux' && $Config{archname} =~ /^arm/;
plan tests => 1;

subtest 'dll' => sub {

  # TODO: on windows can we create a .a that points to
  # the dll and use that to indirectly add the dll?
  plan skip_all => 'unsupported on windows' if $^O eq 'MSWin32';
  plan tests => 2;
  
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $dll = file( $CWD, "bar." . FFI::TinyCC::_dlext() );

  subtest 'create' => sub {
    plan tests => 3;
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('dll') };
    is $@, '', 'tcc.set_output_type(dll)';
    
    eval { $tcc->compile_string(q{
      const char *
      roger()
      {
        return "rabbit";
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "dll=$dll";
    eval { $tcc->output_file($dll) };
    is $@, '', 'tcc.output_file';
  };
  
  subtest 'use' => sub {
  
    plan tests => 3;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($dll) };
    is $@, '', 'tcc.add_file';
    
    eval { $tcc->compile_string(q{
      extern const char *roger();
      const char *wrapper()
      {
        return roger();
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    my $ffi = FFI::Platypus->new;
    my $f = $ffi->function($tcc->get_symbol('wrapper') => [] => 'string');
    is $f->call, "rabbit", 'ffi.call';

  };
  
};
