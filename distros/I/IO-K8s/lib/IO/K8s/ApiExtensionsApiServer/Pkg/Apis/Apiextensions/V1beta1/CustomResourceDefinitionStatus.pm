package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionStatus;
  use Moose;

  has 'acceptedNames' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionCondition]'  );
1;
