package IO::K8s::Api::Authorization::V1::SelfSubjectRulesReviewSpec;
  use Moose;
  use IO::K8s;

  has 'namespace' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
