package IO::K8s::Api::Admissionregistration::V1alpha1::Rule;
  use Moose;
  use IO::K8s;

  has 'apiGroups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'apiVersions' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
