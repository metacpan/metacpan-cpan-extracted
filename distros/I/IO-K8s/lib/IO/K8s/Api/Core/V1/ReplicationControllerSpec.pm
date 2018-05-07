package IO::K8s::Api::Core::V1::ReplicationControllerSpec;
  use Moose;

  has 'minReadySeconds' => (is => 'ro', isa => 'Int'  );
  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'template' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodTemplateSpec'  );
1;
