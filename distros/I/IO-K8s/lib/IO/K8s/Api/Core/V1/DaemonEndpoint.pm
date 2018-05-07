package IO::K8s::Api::Core::V1::DaemonEndpoint;
  use Moose;

  has 'Port' => (is => 'ro', isa => 'Int'  );
1;
