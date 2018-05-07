package IO::K8s::Api::Core::V1::EndpointSubset;
  use Moose;

  has 'addresses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EndpointAddress]'  );
  has 'notReadyAddresses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EndpointAddress]'  );
  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EndpointPort]'  );
1;
