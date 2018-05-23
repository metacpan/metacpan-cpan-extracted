package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrArray;
  use Moose;
  use IO::K8s;

  has 'JSONSchemas' => (is => 'ro', isa => 'ArrayRef[IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps]'  );
  has 'Schema' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
