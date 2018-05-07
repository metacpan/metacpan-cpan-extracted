package IO::K8s::Api::Authorization::V1::NonResourceAttributes;
  use Moose;

  has 'path' => (is => 'ro', isa => 'Str'  );
  has 'verb' => (is => 'ro', isa => 'Str'  );
1;
