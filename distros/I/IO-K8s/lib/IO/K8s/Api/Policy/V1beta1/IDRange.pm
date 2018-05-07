package IO::K8s::Api::Policy::V1beta1::IDRange;
  use Moose;

  has 'max' => (is => 'ro', isa => 'Int'  );
  has 'min' => (is => 'ro', isa => 'Int'  );
1;
