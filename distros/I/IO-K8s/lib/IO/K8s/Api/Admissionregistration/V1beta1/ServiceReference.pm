package IO::K8s::Api::Admissionregistration::V1beta1::ServiceReference;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'namespace' => (is => 'ro', isa => 'Str'  );
  has 'path' => (is => 'ro', isa => 'Str'  );
1;
