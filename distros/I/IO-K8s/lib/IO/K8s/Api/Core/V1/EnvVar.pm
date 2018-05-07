package IO::K8s::Api::Core::V1::EnvVar;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'value' => (is => 'ro', isa => 'Str'  );
  has 'valueFrom' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::EnvVarSource'  );
1;
