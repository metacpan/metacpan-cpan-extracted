package IO::K8s::Api::Core::V1::Handler;
  use Moose;
  use IO::K8s;

  has 'exec' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ExecAction'  );
  has 'httpGet' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::HTTPGetAction'  );
  has 'tcpSocket' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::TCPSocketAction'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
