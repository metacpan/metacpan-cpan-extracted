package IO::K8s::Api::Policy::V1beta1::PodSecurityPolicySpec;
  use Moose;
  use IO::K8s;

  has 'allowedCapabilities' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'allowedFlexVolumes' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Policy::V1beta1::AllowedFlexVolume]'  );
  has 'allowedHostPaths' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Policy::V1beta1::AllowedHostPath]'  );
  has 'allowPrivilegeEscalation' => (is => 'ro', isa => 'Bool'  );
  has 'defaultAddCapabilities' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'defaultAllowPrivilegeEscalation' => (is => 'ro', isa => 'Bool'  );
  has 'fsGroup' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::FSGroupStrategyOptions'  );
  has 'hostIPC' => (is => 'ro', isa => 'Bool'  );
  has 'hostNetwork' => (is => 'ro', isa => 'Bool'  );
  has 'hostPID' => (is => 'ro', isa => 'Bool'  );
  has 'hostPorts' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Policy::V1beta1::HostPortRange]'  );
  has 'privileged' => (is => 'ro', isa => 'Bool'  );
  has 'readOnlyRootFilesystem' => (is => 'ro', isa => 'Bool'  );
  has 'requiredDropCapabilities' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'runAsUser' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::RunAsUserStrategyOptions'  );
  has 'seLinux' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::SELinuxStrategyOptions'  );
  has 'supplementalGroups' => (is => 'ro', isa => 'IO::K8s::Api::Policy::V1beta1::SupplementalGroupsStrategyOptions'  );
  has 'volumes' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
