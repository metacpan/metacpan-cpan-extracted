package IO::K8s::Api::Extensions::V1beta1::AllowedHostPath;
  use Moose;

  has 'pathPrefix' => (is => 'ro', isa => 'Str'  );
1;
