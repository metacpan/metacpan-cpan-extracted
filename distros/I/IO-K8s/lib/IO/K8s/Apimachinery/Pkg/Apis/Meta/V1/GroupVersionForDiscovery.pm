package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::GroupVersionForDiscovery;
  use Moose;

  has 'groupVersion' => (is => 'ro', isa => 'Str'  );
  has 'version' => (is => 'ro', isa => 'Str'  );
1;
