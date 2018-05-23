package IO::K8s::Api::Apps::V1beta1::ScaleStatus;
  use Moose;
  use IO::K8s;

  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'targetSelector' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
