package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceSpec;
  use Moose;
  use IO::K8s;

  has 'caBundle' => (is => 'ro', isa => 'Str'  );
  has 'group' => (is => 'ro', isa => 'Str'  );
  has 'groupPriorityMinimum' => (is => 'ro', isa => 'Int'  );
  has 'insecureSkipTLSVerify' => (is => 'ro', isa => 'Bool'  );
  has 'service' => (is => 'ro', isa => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::ServiceReference'  );
  has 'version' => (is => 'ro', isa => 'Str'  );
  has 'versionPriority' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
