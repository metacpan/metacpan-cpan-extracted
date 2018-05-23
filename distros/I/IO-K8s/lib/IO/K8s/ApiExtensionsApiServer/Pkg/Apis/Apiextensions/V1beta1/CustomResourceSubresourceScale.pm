package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresourceScale;
  use Moose;
  use IO::K8s;

  has 'labelSelectorPath' => (is => 'ro', isa => 'Str'  );
  has 'specReplicasPath' => (is => 'ro', isa => 'Str'  );
  has 'statusReplicasPath' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
