package IO::K8s::Api::Apps::V1beta2::RollingUpdateStatefulSetStrategy;
  use Moose;

  has 'partition' => (is => 'ro', isa => 'Int'  );
1;
