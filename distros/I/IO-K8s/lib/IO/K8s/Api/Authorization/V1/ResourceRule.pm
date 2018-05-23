package IO::K8s::Api::Authorization::V1::ResourceRule;
  use Moose;
  use IO::K8s;

  has 'apiGroups' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resourceNames' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'resources' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'verbs' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
