package IO::K8s::Api::Core::V1::EnvVarSource;
  use Moose;
  use IO::K8s;

  has 'configMapKeyRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ConfigMapKeySelector'  );
  has 'fieldRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ObjectFieldSelector'  );
  has 'resourceFieldRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ResourceFieldSelector'  );
  has 'secretKeyRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretKeySelector'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
