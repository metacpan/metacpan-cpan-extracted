package IO::K8s::Api::Core::V1::ExecAction;
  use Moose;

  has 'command' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
