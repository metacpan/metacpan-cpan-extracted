package IO::K8s::Api::Core::V1::SecretEnvSource;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );
1;
