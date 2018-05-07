package IO::K8s::Api::Core::V1::Probe;
  use Moose;

  has 'exec' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ExecAction'  );
  has 'failureThreshold' => (is => 'ro', isa => 'Int'  );
  has 'httpGet' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::HTTPGetAction'  );
  has 'initialDelaySeconds' => (is => 'ro', isa => 'Int'  );
  has 'periodSeconds' => (is => 'ro', isa => 'Int'  );
  has 'successThreshold' => (is => 'ro', isa => 'Int'  );
  has 'tcpSocket' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::TCPSocketAction'  );
  has 'timeoutSeconds' => (is => 'ro', isa => 'Int'  );
1;
