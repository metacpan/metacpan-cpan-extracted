use Test2::V0 -no_srand => 1;
use FFI::TinyCC;
use Config;
use File::Temp qw( tempdir );
use File::chdir;

subtest obj => sub
{
  local $CWD = tempdir(CLEANUP => 1);
  
  my $obj = "foo$Config{obj_ext}";
  
  subtest 'create object' => sub {
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('obj') };
    is $@, '', 'tcc.set_output_type(obj)';
    
    eval { $tcc->compile_string(q{
      int
      foo()
      {
        return 55;
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "obj=" . "$CWD/$obj";
  
    eval { $tcc->output_file($obj) };
    is $@, '', 'tcc.output_file';
    
    ok -f $obj, "created output file";
  
  };
  
  subtest 'use object' => sub {
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($obj) };
    is $@, '', 'tcc.add_file';
  
    eval { $tcc->compile_string(q{
      extern int foo();
      int
      main(int argc, char *argv[])
      {
        return foo();
      }
    })};
    is $@, '', 'tcc.compile_string';
    
    is eval { $tcc->run }, 55, 'tcc.run';
    note $@ if $@;
  };
  
};

done_testing;
