package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializers;
  use Moose;

  has 'pending' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializer]'  );
  has 'result' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Status'  );
1;
