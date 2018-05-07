package IO::K8s::Api::Apps::V1::ControllerRevision;
  use Moose;

  has 'apiVersion' => (is => 'ro', isa => 'Str'  );
  has 'data' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Runtime::RawExtension'  );
  has 'kind' => (is => 'ro', isa => 'Str'  );
  has 'metadata' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta'  );
  has 'revision' => (is => 'ro', isa => 'Int'  );
1;
