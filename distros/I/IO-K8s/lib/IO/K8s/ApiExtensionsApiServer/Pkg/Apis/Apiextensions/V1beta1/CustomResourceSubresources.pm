package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresources;
  use Moose;

  has 'scale' => (is => 'ro', isa => 'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresourceScale'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
1;
