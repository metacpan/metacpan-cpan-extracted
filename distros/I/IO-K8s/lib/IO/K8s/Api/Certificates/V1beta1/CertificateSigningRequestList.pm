package IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestList;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'items' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequest]'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
