package IO::K8s::Api::Core::V1::SessionAffinityConfig;
  use Moose;

  has 'clientIP' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ClientIPConfig'  );
1;
