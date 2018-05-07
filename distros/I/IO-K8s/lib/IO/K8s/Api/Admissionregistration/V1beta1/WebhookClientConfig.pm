package IO::K8s::Api::Admissionregistration::V1beta1::WebhookClientConfig;
  use Moose;

  has 'caBundle' => (is => 'ro', isa => 'Str'  );
  has 'service' => (is => 'ro', isa => 'IO::K8s::Api::Admissionregistration::V1beta1::ServiceReference'  );
  has 'url' => (is => 'ro', isa => 'Str'  );
1;
