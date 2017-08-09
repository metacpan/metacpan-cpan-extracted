use Test2::V0 -no_srand => 1;
use FFI::TinyCC;
use FFI::Platypus;
use File::Temp qw( tempdir );
use File::chdir;
use Config;

subtest 'obj' => sub {

  local $CWD = tempdir( CLEANUP => 1 );
  
  my $obj = "$CWD/foo$Config{obj_ext}";
  
  subtest 'create' => sub {
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('obj') };
    is $@, '', 'tcc.set_output_type(obj)';
    
    eval { $tcc->compile_string(q{
      const char *
      roger()
      {
        return "rabbit";
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "obj=$obj";
    eval { $tcc->output_file($obj) };
    is $@, '', 'tcc.output_file';
  };
  
  subtest 'use' => sub {
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($obj) };
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

done_testing;
