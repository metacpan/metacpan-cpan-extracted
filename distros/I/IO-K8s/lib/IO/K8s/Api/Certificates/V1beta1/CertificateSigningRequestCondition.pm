package IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestCondition;
  use Moose;

  has 'lastUpdateTime' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
