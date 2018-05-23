package IO::K8s::Api::Authentication::V1::TokenReviewStatus;
  use Moose;
  use IO::K8s;

  has 'authenticated' => (is => 'ro', isa => 'Bool'  );
  has 'error' => (is => 'ro', isa => 'Str'  );
  has 'user' => (is => 'ro', isa => 'IO::K8s::Api::Authentication::V1::UserInfo'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
