package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Status;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'code' => (is => 'ro', isa => 'Int'  );
  has 'details' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::StatusDetails'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
1;
