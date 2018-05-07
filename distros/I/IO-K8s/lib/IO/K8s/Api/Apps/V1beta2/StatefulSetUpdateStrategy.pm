package IO::K8s::Api::Apps::V1beta2::StatefulSetUpdateStrategy;
  use Moose;

  has 'rollingUpdate' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1beta2::RollingUpdateStatefulSetStrategy'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
