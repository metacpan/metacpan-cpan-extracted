package IO::K8s::Api::Core::V1::PersistentVolumeClaimSpec;
  use Moose;

  has 'accessModes' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resources' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceRequirements'  );
  has 'selector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'storageClassName' => (is => 'ro', isa => 'Str'  );
  has 'volumeMode' => (is => 'ro', isa => 'Str'  );
  has 'volumeName' => (is => 'ro', isa => 'Str'  );
1;
