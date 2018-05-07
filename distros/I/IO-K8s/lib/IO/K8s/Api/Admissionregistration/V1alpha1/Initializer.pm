package IO::K8s::Api::Admissionregistration::V1alpha1::Initializer;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'rules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Admissionregistration::V1alpha1::Rule]'  );
1;
