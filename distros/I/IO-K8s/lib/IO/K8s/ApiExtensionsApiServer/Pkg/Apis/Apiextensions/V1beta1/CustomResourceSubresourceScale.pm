package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresourceScale;
  use Moose;

  has 'labelSelectorPath' => (is => 'ro', isa => 'Str'  );
  has 'specReplicasPath' => (is => 'ro', isa => 'Str'  );
  has 'statusReplicasPath' => (is => 'ro', isa => 'Str'  );
1;
