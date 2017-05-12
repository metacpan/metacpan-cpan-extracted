use strict;
use warnings;
use if $] < 5.010, 'Test::More', skip_all => 'eval requires Perl 5.10 or better';
use Test::More tests => 2;
use FFI::TinyCC::Inline qw( tcc_eval );

my $prog = q{
  int main() { return FOO; }
};

subtest eval => sub {
  plan tests => 5;

  use FFI::TinyCC::Inline options => "-DFOO=1";
  
  is tcc_eval($prog), 1, 'FOO=1';

  subtest "one step" => sub {
    plan tests => 1;
    use FFI::TinyCC::Inline options => "-DFOO=2";
  
    is tcc_eval($prog), 2, 'FOO=2';

  };

  is tcc_eval($prog), 1, 'FOO=1';

  subtest "two step" => sub {
    plan tests => 1;
    use FFI::TinyCC::Inline options => "-DFOO=3";
  
    is tcc_eval($prog), 3, 'FOO=3';

  };

  is tcc_eval($prog), 1, 'FOO=1';
};

eval { tcc_eval($prog) };
isnt $@, '', 'no FOO';
note $@ if $@;
