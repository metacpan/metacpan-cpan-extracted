package IO::K8s::Api::Batch::V1beta1::CronJobSpec;
  use Moose;

  has 'concurrencyPolicy' => (is => 'ro', isa => 'Str'  );
  has 'failedJobsHistoryLimit' => (is => 'ro', isa => 'Int'  );
  has 'jobTemplate' => (is => 'ro', isa => 'IO::K8s::Api::Batch::V1beta1::JobTemplateSpec'  );
  has 'schedule' => (is => 'ro', isa => 'Str'  );
  has 'startingDeadlineSeconds' => (is => 'ro', isa => 'Int'  );
  has 'successfulJobsHistoryLimit' => (is => 'ro', isa => 'Int'  );
  has 'suspend' => (is => 'ro', isa => 'Bool'  );
1;
