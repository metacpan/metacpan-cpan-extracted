package IO::K8s::Api::Authentication::V1beta1::TokenReviewSpec;
  use Moose;
  use IO::K8s;

  has 'token' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
