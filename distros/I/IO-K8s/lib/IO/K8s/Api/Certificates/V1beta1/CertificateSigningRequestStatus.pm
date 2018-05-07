package IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestStatus;
  use Moose;

  has 'certificate' => (is => 'ro', isa => 'Str'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestCondition]'  );
1;
