use Test2::V0 -no_srand => 1;
use FFI::TinyCC;

subtest 'basic' => sub {
  my $tcc = FFI::TinyCC->new;

  eval { $tcc->compile_string(q{ int main(int argc, char *argv[]) { return 22; } }) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

done_testing;
