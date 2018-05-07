package IO::K8s::Api::Core::V1::ServicePort;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'nodePort' => (is => 'ro', isa => 'Int'  );
  has 'port' => (is => 'ro', isa => 'Int'  );
  has 'protocol' => (is => 'ro', isa => 'Str'  );
  has 'targetPort' => (is => 'ro', isa => 'Str'  );
1;
