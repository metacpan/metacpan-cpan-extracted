package IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetStatus;
  use Moose;

  has 'currentHealthy' => (is => 'ro', isa => 'Int'  );
  has 'desiredHealthy' => (is => 'ro', isa => 'Int'  );
  has 'disruptedPods' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'disruptionsAllowed' => (is => 'ro', isa => 'Int'  );
  has 'expectedPods' => (is => 'ro', isa => 'Int'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );
1;
