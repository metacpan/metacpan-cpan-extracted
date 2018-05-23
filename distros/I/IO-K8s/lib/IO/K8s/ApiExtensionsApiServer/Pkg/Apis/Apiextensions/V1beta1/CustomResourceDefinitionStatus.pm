package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionStatus;
  use Moose;
  use IO::K8s;

  has 'acceptedNames' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionCondition]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
