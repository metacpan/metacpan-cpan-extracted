package IO::K8s::Api::Core::V1::KeyToPath;
  use Moose;
  use IO::K8s;

  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'mode' => (is => 'ro', isa => 'Int'  );
  has 'path' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
