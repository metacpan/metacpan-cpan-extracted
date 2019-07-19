use Test2::V0 -no_srand => 1;
use FFI::TinyCC;
use Config;
use File::Temp qw( tempdir );
use File::chdir;
use FFI::Platypus;

skip_all "unsupported on $^O" if $^O =~ /^(darwin|gnukfreebsd)$/;
skip_all "unsupported on $^O $Config{archname}" if $^O eq 'linux' && $Config{archname} =~ /^arm/;

mkdir "$CWD/.tmp"
  unless -d "$CWD/.tmp";

subtest dll => sub {

  local $CWD = tempdir( CLEANUP => 1, DIR => "$CWD/.tmp" );

  my $tcc = FFI::TinyCC->new;
  
  my $dll = "$CWD/bar." . FFI::TinyCC::_dlext();
  
  eval { $tcc->set_output_type('dll') };
  is $@, '', 'tcc.set_output_type(dll)';
  
  $tcc->set_options('-D__WIN32__') if $^O eq 'MSWin32';
  
  eval { $tcc->compile_string(q{
    int
    bar()
#if __WIN32__
    __attribute__((dllexport))
#endif
    {
      return 47;
    }
  })};
  is $@, '', 'tcc.compile_string';

  note "dll=$dll";
  
  eval { $tcc->output_file($dll) };
  is $@, '', 'tcc.output_file';
  
  my $ffi = FFI::Platypus->new;
  $ffi->lib($dll);
  my $f = $ffi->function(bar => [] => 'int');
  
  is $f->call(), 47, 'f.call';

};

done_testing;
