package IO::K8s::Api::Core::V1::PodSecurityContext;
  use Moose;
  use IO::K8s;

  has 'fsGroup' => (is => 'ro', isa => 'Int'  );
  has 'runAsGroup' => (is => 'ro', isa => 'Int'  );
  has 'runAsNonRoot' => (is => 'ro', isa => 'Bool'  );
  has 'runAsUser' => (is => 'ro', isa => 'Int'  );
  has 'seLinuxOptions' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SELinuxOptions'  );
  has 'supplementalGroups' => (is => 'ro', isa => 'ArrayRef[Int]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
