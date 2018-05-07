package IO::K8s::Api::Core::V1::ContainerStatus;
  use Moose;

  has 'containerID' => (is => 'ro', isa => 'Str'  );
  has 'image' => (is => 'ro', isa => 'Str'  );
  has 'imageID' => (is => 'ro', isa => 'Str'  );
  has 'lastState' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerState'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'ready' => (is => 'ro', isa => 'Bool'  );
  has 'restartCount' => (is => 'ro', isa => 'Int'  );
  has 'state' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerState'  );
1;
