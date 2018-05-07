package IO::K8s::Api::Core::V1::Capabilities;
  use Moose;

  has 'add' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'drop' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
