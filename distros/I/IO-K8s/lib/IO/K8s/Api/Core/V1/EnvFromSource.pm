package IO::K8s::Api::Core::V1::EnvFromSource;
  use Moose;
  use IO::K8s;

  has 'configMapRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ConfigMapEnvSource'  );
  has 'prefix' => (is => 'ro', isa => 'Str'  );
  has 'secretRef' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::SecretEnvSource'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
