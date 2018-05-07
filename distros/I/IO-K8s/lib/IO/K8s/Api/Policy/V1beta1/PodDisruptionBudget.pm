package IO::K8s::Api::Policy::V1beta1::PodDisruptionBudget;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetStatus'  );
1;
