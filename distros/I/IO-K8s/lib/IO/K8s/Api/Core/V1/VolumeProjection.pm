package IO::K8s::Api::Core::V1::VolumeProjection;
  use Moose;

  has 'configMap' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ConfigMapProjection'  );
  has 'downwardAPI' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::DownwardAPIProjection'  );
  has 'secret' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretProjection'  );
1;
