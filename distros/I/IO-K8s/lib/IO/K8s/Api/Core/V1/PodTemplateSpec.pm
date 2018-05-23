package IO::K8s::Api::Core::V1::PodTemplateSpec;
  use Moose;
  use IO::K8s;

  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodSpec'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
