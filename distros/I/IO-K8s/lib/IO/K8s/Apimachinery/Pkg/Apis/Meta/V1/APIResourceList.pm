package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResourceList;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'groupVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResource]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
