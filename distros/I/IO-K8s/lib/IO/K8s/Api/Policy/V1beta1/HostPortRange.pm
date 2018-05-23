package IO::K8s::Api::Policy::V1beta1::HostPortRange;
  use Moose;
  use IO::K8s;

  has 'max' => (is => 'ro', isa => 'Int'  );
  has 'min' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
