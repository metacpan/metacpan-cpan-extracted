package IO::K8s::Api::Core::V1::LimitRangeSpec;
  use Moose;

  has 'limits' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::LimitRangeItem]'  );
1;
