package IO::K8s::Api::Networking::V1::NetworkPolicyPeer;
  use Moose;

  has 'ipBlock' => (is => 'ro', isa => 'IO::K8s::Api::Networking::V1::IPBlock'  );
  has 'namespaceSelector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'podSelector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
1;
