package IO::K8s::Api::Core::V1::ConfigMap;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'binaryData' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'data' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
