package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrStringArray;
  use Moose;
  use IO::K8s;

  has 'Property' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'Schema' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
