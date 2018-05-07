package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::StatusCause;
  use Moose;

  has 'field' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
1;
