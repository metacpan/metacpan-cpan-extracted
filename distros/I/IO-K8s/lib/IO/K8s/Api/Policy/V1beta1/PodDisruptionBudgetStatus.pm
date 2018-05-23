package IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetStatus;
  use Moose;
  use IO::K8s;

  has 'currentHealthy' => (is => 'ro', isa => 'Int'  );
  has 'desiredHealthy' => (is => 'ro', isa => 'Int'  );
  has 'disruptedPods' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'disruptionsAllowed' => (is => 'ro', isa => 'Int'  );
  has 'expectedPods' => (is => 'ro', isa => 'Int'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
