package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceSpec;
  use Moose;

  has 'caBundle' => (is => 'ro', isa => 'Str'  );
  has 'group' => (is => 'ro', isa => 'Str'  );
  has 'groupPriorityMinimum' => (is => 'ro', isa => 'Int'  );
  has 'insecureSkipTLSVerify' => (is => 'ro', isa => 'Bool'  );
  has 'service' => (is => 'ro', isa => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::ServiceReference'  );
  has 'version' => (is => 'ro', isa => 'Str'  );
  has 'versionPriority' => (is => 'ro', isa => 'Int'  );
1;
