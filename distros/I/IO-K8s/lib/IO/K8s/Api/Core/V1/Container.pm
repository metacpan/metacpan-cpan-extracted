package IO::K8s::Api::Core::V1::Container;
  use Moose;
  use IO::K8s;

  has 'args' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'command' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'env' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EnvVar]'  );
  has 'envFrom' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::EnvFromSource]'  );
  has 'image' => (is => 'ro', isa => 'Str'  );
  has 'imagePullPolicy' => (is => 'ro', isa => 'Str'  );
  has 'lifecycle' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Lifecycle'  );
  has 'livenessProbe' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Probe'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::ContainerPort]'  );
  has 'readinessProbe' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Probe'  );
  has 'resources' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceRequirements'  );
  has 'securityContext' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecurityContext'  );
  has 'stdin' => (is => 'ro', isa => 'Bool'  );
  has 'stdinOnce' => (is => 'ro', isa => 'Bool'  );
  has 'terminationMessagePath' => (is => 'ro', isa => 'Str'  );
  has 'terminationMessagePolicy' => (is => 'ro', isa => 'Str'  );
  has 'tty' => (is => 'ro', isa => 'Bool'  );
  has 'volumeDevices' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::VolumeDevice]'  );
  has 'volumeMounts' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::VolumeMount]'  );
  has 'workingDir' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
