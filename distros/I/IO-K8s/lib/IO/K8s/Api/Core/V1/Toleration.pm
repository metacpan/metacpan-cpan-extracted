package IO::K8s::Api::Core::V1::Toleration;
  use Moose;
  use IO::K8s;

  has 'effect' => (is => 'ro', isa => 'Str'  );
  has 'key' => (is => 'ro', isa => 'Str'  );
  has 'operator' => (is => 'ro', isa => 'Str'  );
  has 'tolerationSeconds' => (is => 'ro', isa => 'Int'  );
  has 'value' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
