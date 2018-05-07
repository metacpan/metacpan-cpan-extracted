package IO::K8s::Api::Apps::V1beta1::RollingUpdateStatefulSetStrategy;
  use Moose;

  has 'partition' => (is => 'ro', isa => 'Int'  );
1;
