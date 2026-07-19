package GraphQL::Houtou::Runtime::ExecState;

use 5.014;
use strict;
use warnings;
use GraphQL::Houtou ();

use GraphQL::Houtou::Runtime::InputCoercion ();

sub new {
  my ($class, %args) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::exec_state_new_xs(
    $class,
    $args{runtime_schema},
    $args{program},
    $args{cursor},
    $args{writer},
    $args{context},
    ($args{variables} || {}),
    $args{root_value},
    ($args{empty_args} || {}),
  );
}

sub build_for_program {
  my ($class, $runtime_schema, $program, %opts) = @_;
  my $native_program = _require_native_program($program);
  my $root_block_index = _root_block_index($native_program);
  return $class->new(
    runtime_schema => $runtime_schema,
    program => $native_program,
    cursor => GraphQL::Houtou::XS::VM::cursor_new_xs(
      'GraphQL::Houtou::Runtime::Cursor',
      undef,
      $native_program,
      $root_block_index,
      0,
      0,
      undef,
      undef,
    ),
    writer => GraphQL::Houtou::XS::VM::writer_new_xs('GraphQL::Houtou::Runtime::Writer'),
    context => $opts{context},
    variables => GraphQL::Houtou::Runtime::InputCoercion::prepare_variables(
      $runtime_schema,
      $native_program,
      $opts{variables} || {},
    ),
    root_value => $opts{root_value},
  );
}

sub run_program {
  my ($class, $runtime_schema, $program, %opts) = @_;
  my $native_program = _require_native_program($program);
  my $state = $class->build_for_program(
    $runtime_schema,
    $native_program,
    %opts,
  );
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::exec_state_run_program_async_xs($state, $opts{root_value});
}

sub _require_native_program {
  my ($program) = @_;
  return $program
    if ref($program) && eval { $program->isa('GraphQL::Houtou::Runtime::NativeProgram') };
  die "Active runtime paths expect a GraphQL::Houtou::Runtime::NativeProgram.\n";
}

sub _root_block_index {
  my ($program) = @_;
  my $native_program = _require_native_program($program);
  GraphQL::Houtou::_bootstrap_xs();
  my $index = GraphQL::Houtou::XS::VM::native_program_root_block_index_xs($native_program);
  return defined $index ? $index : -1;
}

1;
