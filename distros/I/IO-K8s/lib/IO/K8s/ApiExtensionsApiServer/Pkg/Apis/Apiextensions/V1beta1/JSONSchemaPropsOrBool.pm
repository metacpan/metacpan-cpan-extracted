package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool;
  use Moose;

  has 'Allows' => (is => 'ro', isa => 'Bool'  );
  has 'Schema' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps'  );
1;
