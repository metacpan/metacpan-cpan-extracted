package IO::K8s::Api::Core::V1::SecurityContext;
  use Moose;

  has 'allowPrivilegeEscalation' => (is => 'ro', isa => 'Bool'  );
  has 'capabilities' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::Capabilities'  );
  has 'privileged' => (is => 'ro', isa => 'Bool'  );
  has 'readOnlyRootFilesystem' => (is => 'ro', isa => 'Bool'  );
  has 'runAsGroup' => (is => 'ro', isa => 'Int'  );
  has 'runAsNonRoot' => (is => 'ro', isa => 'Bool'  );
  has 'runAsUser' => (is => 'ro', isa => 'Int'  );
  has 'seLinuxOptions' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SELinuxOptions'  );
1;
