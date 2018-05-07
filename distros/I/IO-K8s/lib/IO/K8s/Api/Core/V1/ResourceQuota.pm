package IO::K8s::Api::Core::V1::ResourceQuota;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceQuotaSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceQuotaStatus'  );
1;
