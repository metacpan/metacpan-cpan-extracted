package IO::K8s::Api::Extensions::V1beta1::AllowedFlexVolume;
  use Moose;

  has 'driver' => (is => 'ro', isa => 'Str'  );
1;
