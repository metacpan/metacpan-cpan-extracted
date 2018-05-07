package IO::K8s::Api::Core::V1::VolumeNodeAffinity;
  use Moose;

  has 'required' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeSelector'  );
1;
