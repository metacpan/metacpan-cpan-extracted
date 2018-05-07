package IO::K8s::Api::Core::V1::EventSource;
  use Moose;

  has 'component' => (is => 'ro', isa => 'Str'  );
  has 'host' => (is => 'ro', isa => 'Str'  );
1;
