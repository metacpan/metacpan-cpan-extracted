package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::ExternalDocumentation;
  use Moose;
  use IO::K8s;

  has 'description' => (is => 'ro', isa => 'Str'  );
  has 'url' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
