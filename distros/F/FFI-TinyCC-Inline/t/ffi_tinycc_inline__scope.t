use Test2::V0 -no_srand => 1;
use FFI::TinyCC::Inline qw( tcc_inline );

subtest inline => sub {
  use FFI::TinyCC::Inline options => "-DFOO=1";
  
  eval { tcc_inline q{ int foo11() { return FOO; } } };
  is $@, '', 'tcc_inline';

  subtest "one step" => sub {
    use FFI::TinyCC::Inline options => "-DFOO=2";
  
    eval { tcc_inline q{ int foo2() { return FOO; } } };
    is $@, '', 'tcc_inline';

  };

  eval { tcc_inline q{ int foo12() { return FOO; } } };
  is $@, '', 'tcc_inline';

  subtest "two step" => sub {
    use FFI::TinyCC::Inline options => "-DFOO=3";
  
    eval { tcc_inline q{ int foo3() { return FOO; } } };
    is $@, '', 'tcc_inline';

  };

  eval { tcc_inline q{ int foo13() { return FOO; } } };
  is $@, '', 'tcc_inline';
};

eval { tcc_inline q{ int fooXX() { return FOO; } } };
isnt $@, '', 'no FOO';
note $@ if $@;

subtest call => sub {
  is foo11(), 1, 'foo11';
  is foo12(), 1, 'foo12';
  is foo13(), 1, 'foo13';
  is foo2(),  2, 'foo2';
  is foo3(),  3, 'foo3';
};

done_testing;
