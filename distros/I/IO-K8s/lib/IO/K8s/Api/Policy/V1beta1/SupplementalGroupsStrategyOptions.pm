package IO::K8s::Api::Policy::V1beta1::SupplementalGroupsStrategyOptions;
  use Moose;
  use IO::K8s;

  has 'ranges' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Policy::V1beta1::IDRange]'  );
  has 'rule' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
