package IO::K8s::Api::Batch::V2alpha1::CronJobSpec;
  use Moose;
  use IO::K8s;

  has 'concurrencyPolicy' => (is => 'ro', isa => 'Str'  );
  has 'failedJobsHistoryLimit' => (is => 'ro', isa => 'Int'  );
  has 'jobTemplate' => (is => 'ro', isa => 'IO::K8s::Api::Batch::V2alpha1::JobTemplateSpec'  );
  has 'schedule' => (is => 'ro', isa => 'Str'  );
  has 'startingDeadlineSeconds' => (is => 'ro', isa => 'Int'  );
  has 'successfulJobsHistoryLimit' => (is => 'ro', isa => 'Int'  );
  has 'suspend' => (is => 'ro', isa => 'Bool'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
