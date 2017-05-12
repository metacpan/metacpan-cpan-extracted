use strict;
use warnings;
use FindBin;
use Test::More tests => 3;
use FFI::TinyCC;
use Path::Class qw( file dir );

my $tcc = FFI::TinyCC->new;

my $inc = file($FindBin::Bin, 'c');

note "inc=$inc";

eval { $tcc->add_include_path($inc) };
is $@, '', 'tcc.add_include_path';

eval { $tcc->compile_string(q{
#include "foo.h"
int 
main(int argc, char *argv[])
{
  return VALUE_22;
}
})};
is $@, '', 'tcc.compile_string';

is eval { $tcc->run }, 22, 'tcc.run';

