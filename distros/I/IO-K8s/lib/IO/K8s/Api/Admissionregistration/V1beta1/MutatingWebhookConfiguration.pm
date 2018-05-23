package IO::K8s::Api::Admissionregistration::V1beta1::MutatingWebhookConfiguration;
  use Moose;
  use IO::K8s;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'webhooks' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Admissionregistration::V1beta1::Webhook]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
