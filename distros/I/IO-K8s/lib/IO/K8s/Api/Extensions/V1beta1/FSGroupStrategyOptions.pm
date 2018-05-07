package IO::K8s::Api::Extensions::V1beta1::FSGroupStrategyOptions;
  use Moose;

  has 'ranges' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::IDRange]'  );
  has 'rule' => (is => 'ro', isa => 'Str'  );
1;
