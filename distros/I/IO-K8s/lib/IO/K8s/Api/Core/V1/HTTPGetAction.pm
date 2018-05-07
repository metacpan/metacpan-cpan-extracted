package IO::K8s::Api::Core::V1::HTTPGetAction;
  use Moose;

  has 'host' => (is => 'ro', isa => 'Str'  );
  has 'httpHeaders' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::HTTPHeader]'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'port' => (is => 'ro', isa => 'Str'  );
  has 'scheme' => (is => 'ro', isa => 'Str'  );
1;
