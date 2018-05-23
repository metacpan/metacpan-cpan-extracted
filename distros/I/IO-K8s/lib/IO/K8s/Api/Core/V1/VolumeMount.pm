package IO::K8s::Api::Core::V1::VolumeMount;
  use Moose;
  use IO::K8s;

  has 'mountPath' => (is => 'ro', isa => 'Str'  );
  has 'mountPropagation' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'readOnly' => (is => 'ro', isa => 'Bool'  );
  has 'subPath' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
