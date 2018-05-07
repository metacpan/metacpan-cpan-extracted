package IO::K8s::Api::Core::V1::ResourceRequirements;
  use Moose;

  has 'limits' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'requests' => (is => 'ro', isa => 'HashRef[Str]'  );
1;
