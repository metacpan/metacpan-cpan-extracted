package IO::K8s::Api::Extensions::V1beta1::IPBlock;
  use Moose;
  use IO::K8s;

  has 'cidr' => (is => 'ro', isa => 'Str'  );
  has 'except' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
