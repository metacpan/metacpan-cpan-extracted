use Test2::V0 -no_srand => 1;
use FindBin;
use FFI::TinyCC;

my $inc = "$FindBin::Bin/c";

my $options = "-I$inc -L$inc -DFOO=22";

my $tcc = FFI::TinyCC->new;

eval { $tcc->set_options($options) };
is $@, '', 'tcc.set_options';

eval { $tcc->compile_string(q{

#include "foo.h"

int
main(int argc, char *argv[])
{
  return FOO;
}

})};

is $@, '', 'tcc.compile_string';

is $tcc->run, 22, 'tcc.run';

done_testing;
