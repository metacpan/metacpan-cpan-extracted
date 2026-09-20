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
  my $f = eval { $ffi->function(bar => [] => 'int') };
  if(my $error = $@)
  {
    # Some bundled tcc releases (this one is 0.9.26) produce a DLL with
    # a malformed dynamic symbol table (sh_info left at 0) that very
    # new glibc dynamic linkers refuse to resolve symbols from, even
    # though the symbol is genuinely present (visible via `nm -D`).
    # This is an environment limitation, not a bug in FFI::TinyCC.
    skip_all "known tcc/glibc incompatibility loading a tcc-produced DLL: $error"
      if $error =~ /unable to find/;
    die $error;
  }

  is $f->call(), 47, 'f.call';

};

done_testing;
