package IO::K8s::Api::Core::V1::NodeSystemInfo;
  use Moose;
  use IO::K8s;

  has 'architecture' => (is => 'ro', isa => 'Str'  );
  has 'bootID' => (is => 'ro', isa => 'Str'  );
  has 'containerRuntimeVersion' => (is => 'ro', isa => 'Str'  );
  has 'kernelVersion' => (is => 'ro', isa => 'Str'  );
  has 'kubeletVersion' => (is => 'ro', isa => 'Str'  );
  has 'kubeProxyVersion' => (is => 'ro', isa => 'Str'  );
  has 'machineID' => (is => 'ro', isa => 'Str'  );
  has 'operatingSystem' => (is => 'ro', isa => 'Str'  );
  has 'osImage' => (is => 'ro', isa => 'Str'  );
  has 'systemUUID' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
