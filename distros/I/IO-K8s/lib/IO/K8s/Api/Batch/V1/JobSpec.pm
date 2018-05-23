package IO::K8s::Api::Batch::V1::JobSpec;
  use Moose;
  use IO::K8s;

  has 'activeDeadlineSeconds' => (is => 'ro', isa => 'Int'  );
  has 'backoffLimit' => (is => 'ro', isa => 'Int'  );
  has 'completions' => (is => 'ro', isa => 'Int'  );
  has 'manualSelector' => (is => 'ro', isa => 'Bool'  );
  has 'parallelism' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'template' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodTemplateSpec'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
