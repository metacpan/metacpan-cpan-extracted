package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinition;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionStatus'  );
1;
