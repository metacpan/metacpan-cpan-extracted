package IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIService;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceStatus'  );
1;
