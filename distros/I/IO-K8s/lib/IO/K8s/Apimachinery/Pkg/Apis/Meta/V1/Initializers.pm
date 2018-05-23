package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializers;
  use Moose;
  use IO::K8s;

  has 'pending' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializer]'  );
  has 'result' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Status'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
