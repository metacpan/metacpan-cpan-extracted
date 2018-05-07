package IO::K8s::Api::Core::V1::SecretReference;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );
1;
