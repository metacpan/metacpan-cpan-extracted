package IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequest;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'spec' => (is => 'ro', isa => 'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestSpec'  );
  has 'status' => (is => 'ro', isa => 'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestStatus'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
