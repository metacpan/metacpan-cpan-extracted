package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::WatchEvent;
  use Moose;
  use IO::K8s;

  has 'object' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Runtime::RawExtension'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
