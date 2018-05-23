package IO::K8s::Api::Apps::V1beta1::StatefulSetUpdateStrategy;
  use Moose;
  use IO::K8s;

  has 'rollingUpdate' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1beta1::RollingUpdateStatefulSetStrategy'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
