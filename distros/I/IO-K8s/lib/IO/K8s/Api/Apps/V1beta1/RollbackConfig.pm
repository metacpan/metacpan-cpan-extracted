package IO::K8s::Api::Apps::V1beta1::RollbackConfig;
  use Moose;
  use IO::K8s;

  has 'revision' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
