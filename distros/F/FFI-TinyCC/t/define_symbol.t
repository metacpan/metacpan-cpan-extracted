use strict;
use warnings;
use Test::More tests => 2;
use FFI::TinyCC;

subtest 'define with value' => sub {

  my $tcc = FFI::TinyCC->new;
  
  eval { $tcc->define_symbol(FOO => 22) };
  is $@, '', 'tcc.define_symbol';
  
  eval { $tcc->compile_string(q{
    int main(int argc, char *argv[]) { return FOO; }
  })};
  is $@, '', 'tcc.compile_string';
  
  is $tcc->run, 22, 'tcc.run';

};


subtest 'define without value' => sub {

  my $tcc = FFI::TinyCC->new;
  
  eval { $tcc->define_symbol('FOO') };
  is $@, '', 'tcc.define_symbol';
  
  eval { $tcc->compile_string(q{
    int main(int argc, char *argv[]) {
#ifdef FOO
      return 22; 
#endif
    }
  })};
  is $@, '', 'tcc.compile_string';
  
  is $tcc->run, 22, 'tcc.run';

};
