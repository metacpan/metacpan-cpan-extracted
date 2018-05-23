package IO::K8s::Api::Core::V1::ClientIPConfig;
  use Moose;
  use IO::K8s;

  has 'timeoutSeconds' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
