package IO::K8s::Api::Batch::V1beta1::JobTemplateSpec;
  use Moose;
  use IO::K8s;

  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Batch::V1::JobSpec'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
