package IO::K8s::Api::Admissionregistration::V1alpha1::InitializerConfiguration;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'initializers' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Admissionregistration::V1alpha1::Initializer]'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
