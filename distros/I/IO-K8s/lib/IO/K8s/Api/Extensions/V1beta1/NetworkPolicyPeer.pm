package IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPeer;
  use Moose;
  use IO::K8s;

  has 'ipBlock' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::IPBlock'  );
  has 'namespaceSelector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'podSelector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
