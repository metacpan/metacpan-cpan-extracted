package IO::K8s::Api::Apps::V1beta2::RollingUpdateDaemonSet;
  use Moose;

  has 'maxUnavailable' => (is => 'ro', isa => 'Str'  );
1;
