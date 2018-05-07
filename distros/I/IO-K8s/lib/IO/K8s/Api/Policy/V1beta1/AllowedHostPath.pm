package IO::K8s::Api::Policy::V1beta1::AllowedHostPath;
  use Moose;

  has 'pathPrefix' => (is => 'ro', isa => 'Str'  );
1;
