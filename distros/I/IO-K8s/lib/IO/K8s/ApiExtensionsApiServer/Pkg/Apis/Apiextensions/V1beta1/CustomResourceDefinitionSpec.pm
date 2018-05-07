package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionSpec;
  use Moose;

  has 'group' => (is => 'ro', isa => 'Str'  );
  has 'names' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames'  );
  has 'scope' => (is => 'ro', isa => 'Str'  );
  has 'subresources' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresources'  );
  has 'validation' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceValidation'  );
  has 'version' => (is => 'ro', isa => 'Str'  );
1;
