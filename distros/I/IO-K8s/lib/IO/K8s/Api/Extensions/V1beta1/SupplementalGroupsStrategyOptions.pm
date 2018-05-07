package IO::K8s::Api::Extensions::V1beta1::SupplementalGroupsStrategyOptions;
  use Moose;

  has 'ranges' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::IDRange]'  );
  has 'rule' => (is => 'ro', isa => 'Str'  );
1;
