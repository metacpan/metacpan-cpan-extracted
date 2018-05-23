package IO::K8s::Api::Extensions::V1beta1::SELinuxStrategyOptions;
  use Moose;
  use IO::K8s;

  has 'rule' => (is => 'ro', isa => 'Str'  );
  has 'seLinuxOptions' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SELinuxOptions'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
