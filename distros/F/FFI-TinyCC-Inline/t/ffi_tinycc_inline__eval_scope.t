use Test2::V0 -no_srand => 1;
use FFI::TinyCC::Inline qw( tcc_eval );

my $prog = q{
  int main() { return FOO; }
};

subtest eval => sub {
  use FFI::TinyCC::Inline options => "-DFOO=1";
  
  is tcc_eval($prog), 1, 'FOO=1';

  subtest "one step" => sub {
    use FFI::TinyCC::Inline options => "-DFOO=2";
  
    is tcc_eval($prog), 2, 'FOO=2';

  };

  is tcc_eval($prog), 1, 'FOO=1';

  subtest "two step" => sub {
    use FFI::TinyCC::Inline options => "-DFOO=3";
  
    is tcc_eval($prog), 3, 'FOO=3';

  };

  is tcc_eval($prog), 1, 'FOO=1';
};

eval { tcc_eval($prog) };
isnt $@, '', 'no FOO';
note $@ if $@;

done_testing;
