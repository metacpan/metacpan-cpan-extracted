package IO::K8s::Api::Core::V1::VolumeProjection;
  use Moose;
  use IO::K8s;

  has 'configMap' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ConfigMapProjection'  );
  has 'downwardAPI' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::DownwardAPIProjection'  );
  has 'secret' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretProjection'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
