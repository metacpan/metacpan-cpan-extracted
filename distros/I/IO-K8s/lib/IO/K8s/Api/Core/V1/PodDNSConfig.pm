package IO::K8s::Api::Core::V1::PodDNSConfig;
  use Moose;

  has 'nameservers' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'options' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::PodDNSConfigOption]'  );
  has 'searches' => (is => 'ro', isa => 'ArrayRef[Str]'  );
1;
