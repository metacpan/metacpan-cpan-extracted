package IO::K8s::Api::Core::V1::PodDNSConfigOption;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'value' => (is => 'ro', isa => 'Str'  );
1;
