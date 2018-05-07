package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::WatchEvent;
  use Moose;

  has 'object' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Runtime::RawExtension'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
