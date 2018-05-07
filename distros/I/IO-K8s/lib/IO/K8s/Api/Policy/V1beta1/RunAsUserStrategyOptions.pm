package IO::K8s::Api::Policy::V1beta1::RunAsUserStrategyOptions;
  use Moose;

  has 'ranges' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Policy::V1beta1::IDRange]'  );
  has 'rule' => (is => 'ro', isa => 'Str'  );
1;
