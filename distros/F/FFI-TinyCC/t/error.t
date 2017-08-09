use Test2::V0 -no_srand => 1;
use FFI::TinyCC;

my $tcc = FFI::TinyCC->new;

eval { $tcc->compile_string(q{
int
main(int argc, char *argv[])
{
  return 4
}
});
};

my $error = $@;

isnt $error, '', 'bad code throws an exception';
isa_ok $error, 'FFI::TinyCC::Exception';
note "exception=$error";
isnt $error->errors->[0], '', 'exception has an error';
note "error=" . $error->errors->[0];

done_testing;
