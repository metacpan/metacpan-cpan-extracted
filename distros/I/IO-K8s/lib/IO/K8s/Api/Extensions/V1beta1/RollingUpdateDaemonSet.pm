package IO::K8s::Api::Extensions::V1beta1::RollingUpdateDaemonSet;
  use Moose;

  has 'maxUnavailable' => (is => 'ro', isa => 'Str'  );
1;
