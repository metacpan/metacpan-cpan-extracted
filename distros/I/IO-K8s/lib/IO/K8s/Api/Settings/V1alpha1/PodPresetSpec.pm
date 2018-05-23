package IO::K8s::Api::Settings::V1alpha1::PodPresetSpec;
  use Moose;
  use IO::K8s;

  has 'env' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EnvVar]'  );
  has 'envFrom' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EnvFromSource]'  );
  has 'selector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'volumeMounts' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::VolumeMount]'  );
  has 'volumes' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::Volume]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
