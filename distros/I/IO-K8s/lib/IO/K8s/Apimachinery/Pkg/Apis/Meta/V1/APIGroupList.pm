package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'groups' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroup]'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
1;
