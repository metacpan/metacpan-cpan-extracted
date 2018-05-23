package IO::K8s::Api::Extensions::V1beta1::DeploymentSpec;
  use Moose;
  use IO::K8s;

  has 'minReadySeconds' => (is => 'ro', isa => 'Int'  );
  has 'paused' => (is => 'ro', isa => 'Bool'  );
  has 'progressDeadlineSeconds' => (is => 'ro', isa => 'Int'  );
  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'revisionHistoryLimit' => (is => 'ro', isa => 'Int'  );
  has 'rollbackTo' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::RollbackConfig'  );
  has 'selector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'strategy' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::DeploymentStrategy'  );
  has 'template' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodTemplateSpec'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
