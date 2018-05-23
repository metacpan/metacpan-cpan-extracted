package IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestStatus;
  use Moose;
  use IO::K8s;

  has 'certificate' => (is => 'ro', isa => 'Str'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestCondition]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
