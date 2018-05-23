package IO::K8s::Api::Core::V1::ResourceRequirements;
  use Moose;
  use IO::K8s;

  has 'limits' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'requests' => (is => 'ro', isa => 'HashRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
