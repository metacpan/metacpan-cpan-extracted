package IO::K8s::Api::Core::V1::HostAlias;
  use Moose;

  has 'hostnames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'ip' => (is => 'ro', isa => 'Str'  );
1;
