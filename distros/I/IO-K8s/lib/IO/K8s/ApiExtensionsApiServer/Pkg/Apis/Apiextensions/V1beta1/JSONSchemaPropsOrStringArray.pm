package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrStringArray;
  use Moose;

  has 'Property' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'Schema' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps'  );
1;
