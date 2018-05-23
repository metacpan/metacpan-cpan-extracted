package IO::K8s::Api::Core::V1::EventSeries;
  use Moose;
  use IO::K8s;

  has 'count' => (is => 'ro', isa => 'Int'  );
  has 'lastObservedTime' => (is => 'ro', isa => 'Str'  );
  has 'state' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
