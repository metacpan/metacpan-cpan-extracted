package IO::K8s::Api::Apps::V1::DaemonSetUpdateStrategy;
  use Moose;

  has 'rollingUpdate' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1::RollingUpdateDaemonSet'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
