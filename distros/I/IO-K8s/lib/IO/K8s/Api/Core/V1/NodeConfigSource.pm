package IO::K8s::Api::Core::V1::NodeConfigSource;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'configMapRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectReference'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
1;
