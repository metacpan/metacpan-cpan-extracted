package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ServerAddressByClientCIDR;
  use Moose;

  has 'clientCIDR' => (is => 'ro', isa => 'Str'  );
  has 'serverAddress' => (is => 'ro', isa => 'Str'  );
1;
