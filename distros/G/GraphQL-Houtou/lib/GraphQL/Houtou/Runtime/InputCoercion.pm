package GraphQL::Houtou::Runtime::InputCoercion;

use 5.014;
use strict;
use warnings;

use GraphQL::Houtou ();

sub prepare_variables {
  my ($runtime_schema, $program, $provided) = @_;
  die "Active runtime paths expect a GraphQL::Houtou::Runtime::NativeProgram.\n"
    if !ref($program) || !eval { $program->isa('GraphQL::Houtou::Runtime::NativeProgram') };
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::native_program_prepare_variables_xs(
    $runtime_schema,
    $program,
    ($provided || {}),
  );
}

1;
