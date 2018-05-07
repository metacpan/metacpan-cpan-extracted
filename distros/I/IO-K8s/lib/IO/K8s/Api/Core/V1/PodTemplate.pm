package IO::K8s::Api::Core::V1::PodTemplate;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'template' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::PodTemplateSpec'  );
1;
