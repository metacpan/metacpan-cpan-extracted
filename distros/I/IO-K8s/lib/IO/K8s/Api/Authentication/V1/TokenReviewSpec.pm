package IO::K8s::Api::Authentication::V1::TokenReviewSpec;
  use Moose;

  has 'token' => (is => 'ro', isa => 'Str'  );
1;
