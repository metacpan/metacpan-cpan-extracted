use Test2::V0 -no_srand => 1;
use FFI::TinyCC;

subtest 'no arguments' => sub {
  my $tcc = FFI::TinyCC->new;

  eval { $tcc->compile_string(q{int main(int argc, char *argv[]) { return 22; }}) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

subtest 'arguments' => sub {
  my $tcc = FFI::TinyCC->new;
  
  eval { $tcc->compile_string(q{
    int
    main(int argc, char *argv[])
    {
      if(argc != 2)
        return 2;
      if(strcmp(argv[0], "foo"))
        return 3;
      if(strcmp(argv[1], "bar"))
        return 4;
      return 0;
    }
  }) };
  is $@, '', 'tcc.compile_string';
  
  is $tcc->run('foo', 'bar'), 0, 'tcc.run';
};

done_testing;
