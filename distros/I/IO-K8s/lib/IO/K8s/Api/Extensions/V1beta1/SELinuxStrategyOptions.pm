package IO::K8s::Api::Extensions::V1beta1::SELinuxStrategyOptions;
  use Moose;

  has 'rule' => (is => 'ro', isa => 'Str'  );
  has 'seLinuxOptions' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SELinuxOptions'  );
1;
