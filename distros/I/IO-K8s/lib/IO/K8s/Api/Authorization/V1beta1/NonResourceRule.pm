package IO::K8s::Api::Authorization::V1beta1::NonResourceRule;
  use Moose;
  use IO::K8s;

  has 'nonResourceURLs' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'verbs' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
