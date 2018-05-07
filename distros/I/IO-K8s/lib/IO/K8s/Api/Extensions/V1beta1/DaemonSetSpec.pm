package IO::K8s::Api::Extensions::V1beta1::DaemonSetSpec;
  use Moose;

  has 'minReadySeconds' => (is => 'ro', isa => 'Int'  );
  has 'revisionHistoryLimit' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'template' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodTemplateSpec'  );
  has 'templateGeneration' => (is => 'ro', isa => 'Int'  );
  has 'updateStrategy' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::DaemonSetUpdateStrategy'  );
1;
