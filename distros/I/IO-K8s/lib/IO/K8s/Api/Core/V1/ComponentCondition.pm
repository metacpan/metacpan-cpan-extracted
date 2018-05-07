package IO::K8s::Api::Core::V1::ComponentCondition;
  use Moose;

  has 'error' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
