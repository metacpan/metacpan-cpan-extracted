package IO::K8s::Api::Core::V1::Lifecycle;
  use Moose;

  has 'postStart' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Handler'  );
  has 'preStop' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Handler'  );
1;
