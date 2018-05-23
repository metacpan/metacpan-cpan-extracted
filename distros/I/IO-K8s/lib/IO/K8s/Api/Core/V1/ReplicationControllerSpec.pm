package IO::K8s::Api::Core::V1::ReplicationControllerSpec;
  use Moose;
  use IO::K8s;

  has 'minReadySeconds' => (is => 'ro', isa => 'Int'  );
  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'template' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodTemplateSpec'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
