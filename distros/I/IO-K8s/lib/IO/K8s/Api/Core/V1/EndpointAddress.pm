package IO::K8s::Api::Core::V1::EndpointAddress;
  use Moose;

  has 'hostname' => (is => 'ro', isa => 'Str'  );
  has 'ip' => (is => 'ro', isa => 'Str'  );
  has 'nodeName' => (is => 'ro', isa => 'Str'  );
  has 'targetRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectReference'  );
1;
