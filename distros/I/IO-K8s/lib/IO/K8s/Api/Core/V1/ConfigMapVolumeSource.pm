package IO::K8s::Api::Core::V1::ConfigMapVolumeSource;
  use Moose;
  use IO::K8s;

  has 'defaultMode' => (is => 'ro', isa => 'Int'  );
  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::KeyToPath]'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'optional' => (is => 'ro', isa => 'Bool'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
