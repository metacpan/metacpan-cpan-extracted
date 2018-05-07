package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResourceList;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'groupVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResource]'  );
1;
