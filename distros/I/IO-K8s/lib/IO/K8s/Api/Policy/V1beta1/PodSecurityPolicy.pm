package IO::K8s::Api::Policy::V1beta1::PodSecurityPolicy;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::PodSecurityPolicySpec'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
