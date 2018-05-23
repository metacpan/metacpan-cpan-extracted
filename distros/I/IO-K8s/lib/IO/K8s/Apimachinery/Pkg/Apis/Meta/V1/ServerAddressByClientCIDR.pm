package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ServerAddressByClientCIDR;
  use Moose;
  use IO::K8s;

  has 'clientCIDR' => (is => 'ro', isa => 'Str'  );
  has 'serverAddress' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
