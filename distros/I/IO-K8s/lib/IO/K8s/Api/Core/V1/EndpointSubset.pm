package IO::K8s::Api::Core::V1::EndpointSubset;
  use Moose;
  use IO::K8s;

  has 'addresses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EndpointAddress]'  );
  has 'notReadyAddresses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EndpointAddress]'  );
  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EndpointPort]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
