package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrArray;
  use Moose;

  has 'JSONSchemas' => (is => 'ro', isa => 'ArrayRef[IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps]'  );
  has 'Schema' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps'  );
1;
