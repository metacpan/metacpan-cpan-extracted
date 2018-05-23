package IO::K8s::Api::Core::V1::Lifecycle;
  use Moose;
  use IO::K8s;

  has 'postStart' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Handler'  );
  has 'preStop' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Handler'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
