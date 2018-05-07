package IO::K8s::Api::Authentication::V1beta1::TokenReviewSpec;
  use Moose;

  has 'token' => (is => 'ro', isa => 'Str'  );
1;
