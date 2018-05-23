package IO::K8s::Api::Admissionregistration::V1alpha1::Initializer;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'rules' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Admissionregistration::V1alpha1::Rule]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
